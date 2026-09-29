"""Read-only package conformance. Does not extract, execute, sign or upload a game.

Validates a directory or ZIP against a bounded manifest, exact payload allowlist,
optional expected source identities, and versioned preview-only Steam recipes.
Hashes detect changes, NOT authorship: supply expected source identities from a
trusted build record. An adversary can rewrite an unsigned manifest and payload.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import stat
import struct
import zipfile
from contextlib import contextmanager
from pathlib import Path
from typing import BinaryIO, Iterator

from package_platform import MAX_FILE_BYTES, identity, steam_recipes

PAYLOAD_NAMES = {"1792.exe", "1792.pck", "GAME-LICENSE.txt", "GODOT-LICENSE.txt", "ENGINE-NOTICES.json", "README.txt"}
V1_KEYS = {"schema", "game_id", "target", "source_commit", "source_tree", "operation_id", "execution_id",
           "runtime_provider", "engine", "packaging_only", "store_uploaded", "signed", "console_certified", "files"}
V2_KEYS = V1_KEYS | {"steam_preview", "recipes"}
DIRECTORIES = {"content", "steam-preview"}
METADATA_LIMIT = 2 * 1024 * 1024


def _object(pairs: list[tuple[str, object]]) -> dict:
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("Duplicate JSON key: " + key)
        result[key] = value
    return result


def _json(data: bytes) -> dict:
    def reject(value: str) -> None:
        raise ValueError("Non-finite JSON number: " + value)
    value = json.loads(data.decode("utf-8"), object_pairs_hook=_object, parse_constant=reject)
    if not isinstance(value, dict):
        raise ValueError("Expected a JSON object")
    return value


def _safe_name(name: str) -> str:
    if not name or "\\" in name or any(ord(c) < 32 for c in name):
        raise ValueError("Invalid package path")
    if any(part in ("", ".", "..") or ":" in part for part in name.split("/")):
        raise ValueError("Unsafe or non-canonical package path")
    return name


def _linked(path: Path) -> bool:
    return path.is_symlink() or (hasattr(path, "is_junction") and path.is_junction())


class Package:
    """Bounded reader for trusted staging trees or untrusted archives; never extracts."""
    def __init__(self, path: Path):
        self.path = path
        self.archive: zipfile.ZipFile | None = None
        self.files: dict[str, int] = {}
        self.directories: set[str] = set()
        if _linked(path):
            raise ValueError("Linked package roots are unsupported")
        seen: set[str] = set()
        try:
            if path.is_dir():
                entries = path.rglob("*")
                for entry in entries:
                    if _linked(entry):
                        raise ValueError("Linked package members are unsupported")
                    name = _safe_name(entry.relative_to(path).as_posix())
                    self._record(name, entry.is_dir(), seen)
                    if not entry.is_dir():
                        if not entry.is_file():
                            raise ValueError("Non-regular package member")
                        self.files[name] = entry.stat().st_size
            else:
                self.archive = zipfile.ZipFile(path)
                entries = self.archive.infolist()
                if len(entries) > 16:
                    raise ValueError("Too many archive members")
                for entry in entries:
                    name = _safe_name(entry.filename[:-1] if entry.is_dir() else entry.filename)
                    mode = (entry.external_attr >> 16) & 0xFFFF
                    kind = stat.S_IFMT(mode)
                    if kind not in (0, stat.S_IFREG, stat.S_IFDIR) or entry.flag_bits & 1:
                        raise ValueError("Linked, special or encrypted ZIP member")
                    if entry.compress_type not in (zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED):
                        raise ValueError("Unsupported archive compression")
                    if kind == stat.S_IFDIR and not entry.is_dir():
                        raise ValueError("Inconsistent ZIP directory entry")
                    self._record(name, entry.is_dir(), seen)
                    if not entry.is_dir():
                        self.files[name] = entry.file_size
            if not self.files or len(self.files) > 9:
                raise ValueError("Unexpected package file count")
            for name, size in self.files.items():
                limit = MAX_FILE_BYTES if name in ("content/1792.exe", "content/1792.pck") else METADATA_LIMIT
                if not 0 < size <= limit:
                    raise ValueError("Empty or oversized member: " + name)
        except Exception:
            self.close()
            raise

    def _record(self, name: str, directory: bool, seen: set[str]) -> None:
        if name.casefold() in seen:
            raise ValueError("Duplicate or case-colliding member: " + name)
        seen.add(name.casefold())
        if len(seen) > 16:
            raise ValueError("Too many package members")
        if directory:
            if name not in DIRECTORIES:
                raise ValueError("Unexpected directory: " + name)
            self.directories.add(name)
        else:
            allowed = {"manifest.json"} | {"content/" + n for n in PAYLOAD_NAMES} | {
                "steam-preview/app_build.vdf", "steam-preview/depot_build.vdf"}
            if name not in allowed:
                raise ValueError("Unexpected package member: " + name)

    @contextmanager
    def open(self, name: str) -> Iterator[BinaryIO]:
        if name not in self.files:
            raise ValueError("Missing package member: " + name)
        stream = self.archive.open(name) if self.archive else (self.path / name).open("rb")
        with stream:
            yield stream

    def small(self, name: str) -> bytes:
        if self.files.get(name, METADATA_LIMIT + 1) > METADATA_LIMIT:
            raise ValueError("Metadata too large: " + name)
        with self.open(name) as stream:
            data = stream.read(METADATA_LIMIT + 1)
        if len(data) != self.files[name] or len(data) > METADATA_LIMIT:
            raise ValueError("Metadata size changed: " + name)
        return data

    def digest(self, name: str) -> str:
        count, digest = 0, hashlib.sha256()
        with self.open(name) as stream:
            while chunk := stream.read(1024 * 1024):
                count += len(chunk)
                if count > self.files[name]:
                    raise ValueError("Member exceeded declared size")
                digest.update(chunk)
        if count != self.files[name]:
            raise ValueError("Member length changed")
        return digest.hexdigest()

    def close(self) -> None:
        if self.archive is not None:
            self.archive.close()


def _records(reader: Package, records: object, expected: set[str], prefix: str = "") -> None:
    if not isinstance(records, dict) or set(records) != expected:
        raise ValueError("Manifest file allowlist mismatch")
    for name, record in records.items():
        if not isinstance(record, dict) or set(record) != {"bytes", "sha256"}:
            raise ValueError("Malformed file digest record")
        if type(record["bytes"]) is not int or record["bytes"] != reader.files.get(prefix + name):
            raise ValueError("File length mismatch: " + name)
        digest = record["sha256"]
        if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
            raise ValueError("Invalid file hash")
        if reader.digest(prefix + name) != digest:
            raise ValueError("File hash mismatch: " + name)


def verify(path: Path, *, expected_commit: str | None = None, expected_tree: str | None = None) -> dict:
    reader = Package(path)
    try:
        manifest_bytes = reader.small("manifest.json")
        m = _json(manifest_bytes)
        v2 = m.get("schema") == "cg.platform-build.v2"
        if not v2 and m.get("schema") != "cg.platform-build.v1":
            raise ValueError("Unsupported package manifest version")
        if set(m) != (V2_KEYS if v2 else V1_KEYS):
            raise ValueError("Unexpected manifest fields")
        for key, value in (("game_id", "1792"), ("runtime_provider", "cg.local-pc.v1"),
                           ("operation_id", "platform.stage-payload.v1")):
            if m[key] != value:
                raise ValueError("Package identity changed: " + key)
        for key in ("source_commit", "source_tree"):
            if not isinstance(m[key], str):
                raise ValueError("Source identities must be strings")
            identity(m[key], key)
        for expected, key in ((expected_commit, "source_commit"), (expected_tree, "source_tree")):
            if expected is not None and m[key] != identity(expected, key):
                raise ValueError("Unexpected " + key)
        if not isinstance(m["engine"], str) or not m["engine"].startswith("4.5.1-stable"):
            raise ValueError("Unsupported engine identity")
        if not isinstance(m["execution_id"], str) or not 0 < len(m["execution_id"]) <= 160:
            raise ValueError("Invalid build execution identity")
        if m["packaging_only"] is not True or any(m[key] is not False for key in ("store_uploaded", "signed", "console_certified")):
            raise ValueError("Unsigned staging cannot claim publishing, signing or certification")
        target = m["target"]
        if target not in ("windows_local", "steam_windows"):
            raise ValueError("Unimplemented package target")
        expected_files = {"manifest.json"} | {"content/" + n for n in PAYLOAD_NAMES}
        recipes: dict[str, bytes] = {}
        if target == "steam_windows":
            if not v2:
                raise ValueError("Legacy Steam recipe has no manifest-bound app/depot identity; regenerate it")
            preview = m["steam_preview"]
            if not isinstance(preview, dict) or set(preview) != {"app_id", "depot_id", "preview"} or preview["preview"] is not True:
                raise ValueError("Only declared preview-only Steam recipes are supported")
            if not isinstance(preview["app_id"], str) or not isinstance(preview["depot_id"], str):
                raise ValueError("Steam identities must be strings")
            recipes = steam_recipes(preview["app_id"], preview["depot_id"], m["source_commit"])
            expected_files |= set(recipes)
        elif v2 and m["steam_preview"] is not None:
            raise ValueError("Local build cannot carry a store identity")
        if set(reader.files) != expected_files or (target == "windows_local" and "steam-preview" in reader.directories):
            raise ValueError("Package contains missing or unexpected files")
        _records(reader, m["files"], PAYLOAD_NAMES, "content/")
        if v2:
            _records(reader, m["recipes"], set(recipes))
        for name, canonical in recipes.items():
            if reader.small(name) != canonical:
                raise ValueError("Steam recipe differs from the declared preview-only recipe")
        with reader.open("content/1792.exe") as stream:
            header = stream.read(64)
            if len(header) != 64 or header[:2] != b"MZ":
                raise ValueError("Invalid PE shape")
            offset = struct.unpack_from("<I", header, 60)[0]
            if not 64 <= offset <= reader.files["content/1792.exe"] - 6:
                raise ValueError("Invalid PE header location")
            stream.seek(offset)
            if stream.read(6) != b"PE\0\0\x64\x86":
                raise ValueError("Not a Windows x86_64 PE payload")
        with reader.open("content/1792.pck") as stream:
            if stream.read(4) != b"GDPC":
                raise ValueError("Not a separate Godot PCK")
        notices = _json(reader.small("content/ENGINE-NOTICES.json"))
        if notices.get("schema") != "cg.engine-notices.v1" or notices.get("engine") != m["engine"]:
            raise ValueError("Runtime notices do not match package engine")
        for key, kind in (("godot_license", str), ("components", list), ("licenses", dict)):
            if not isinstance(notices.get(key), kind) or not notices[key]:
                raise ValueError("Missing runtime notices: " + key)
        return {"schema": "cg.package-verification.v1", "ok": True,
                "verification_id": "platform-package-conformance.v1", "operation_id": "platform.verify-package.v1",
                "manifest_schema": m["schema"], "manifest_sha256": hashlib.sha256(manifest_bytes).hexdigest(),
                "source_commit": m["source_commit"], "source_tree": m["source_tree"],
                "build_execution_id": m["execution_id"], "target": target, "files_checked": len(reader.files),
                "steam_preview": m.get("steam_preview"), "authenticity_verified": False,
                "payload_executed_by_verifier": False, "store_uploaded": False, "console_certification": False}
    finally:
        reader.close()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package", type=Path)
    parser.add_argument("--expected-commit")
    parser.add_argument("--expected-tree")
    args = parser.parse_args()
    try:
        print(json.dumps(verify(args.package, expected_commit=args.expected_commit, expected_tree=args.expected_tree), indent=2))
    except (ValueError, OSError, KeyError, TypeError, EOFError, zipfile.BadZipFile, NotImplementedError) as error:
        parser.exit(2, f"Package refused: {error}\n")


if __name__ == "__main__":
    main()
