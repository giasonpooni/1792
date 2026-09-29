"""Stage verified 1792 PC bytes for GDK MakePkg; explicit Windows execution, NEVER upload.

Staging/conformance is not Microsoft's SubmissionValidator or proof of assigned identity.
The existing local-PC package is an immutable input; this is a distinct derived artifact.
"""
from __future__ import annotations
import argparse
import binascii
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path
from verify_platform import Package, PAYLOAD_NAMES, _json, _linked, verify

PROFILE_KEYS = {"schema", "identity_name", "identity_publisher", "version", "store_id",
                "display_name", "publisher_display_name", "description"}
LOGOS = {"Square44x44Logo": 44, "Square150x150Logo": 150, "Square480x480Logo": 480, "StoreLogo": 100}
LOOSE_NAMES = PAYLOAD_NAMES | {"MicrosoftGame.config"} | {"Assets/" + k + ".png" for k in LOGOS}
MAX_META = 1024 * 1024


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_small(path: Path, limit: int = MAX_META) -> bytes:
    if _linked(path) or not path.is_file() or not 0 < path.stat().st_size <= limit:
        raise ValueError("Missing, linked, empty or oversized input: " + path.name)
    data = path.read_bytes()
    if not 0 < len(data) <= limit:
        raise ValueError("Input changed size")
    return data


def profile_error(value: object) -> dict:
    if not isinstance(value, dict) or set(value) != PROFILE_KEYS or value.get("schema") != "cg.microsoft-pc-identity.v1":
        raise ValueError("Exact Microsoft PC identity profile required")
    for key in PROFILE_KEYS:
        text = value[key]
        if not isinstance(text, str) or not text or len(text) > 256 or any(ord(c) < 32 for c in text):
            raise ValueError("Invalid identity text: " + key)
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9.-]{2,49}", value["identity_name"]):
        raise ValueError("Use the package identity Name assigned in Partner Center")
    if not value["identity_publisher"].startswith("CN=") or len(value["identity_publisher"]) < 4:
        raise ValueError("Use the complete assigned Publisher beginning CN=")
    if not re.fullmatch(r"[A-Z0-9]{12}", value["store_id"]):
        raise ValueError("Explicit 12-character Store ID required")
    if not re.fullmatch(r"(?:0|[1-9][0-9]{0,4})(?:\.(?:0|[1-9][0-9]{0,4})){3}", value["version"]):
        raise ValueError("Version must contain four bounded integers")
    if value["version"] == "0.0.0.0" or any(int(n) > 65535 for n in value["version"].split(".")):
        raise ValueError("Version component exceeds 65535")
    return dict(value)


def png_check(data: bytes, size: int) -> None:
    """Bounded non-interlaced RGB/RGBA PNG validation, not editorial/logo certification."""
    if len(data) > MAX_META or not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("A bounded PNG asset is required")
    pos, chunks, compressed, channels = 8, [], bytearray(), 0
    while pos < len(data):
        if pos + 12 > len(data): raise ValueError("Truncated PNG")
        length = struct.unpack_from(">I", data, pos)[0]
        if length > MAX_META or pos + length + 12 > len(data): raise ValueError("Oversized PNG chunk")
        kind, body = data[pos+4:pos+8], data[pos+8:pos+8+length]
        crc = struct.unpack_from(">I", data, pos+8+length)[0]
        if binascii.crc32(kind + body) & 0xffffffff != crc: raise ValueError("PNG CRC mismatch")
        if not chunks and kind != b"IHDR": raise ValueError("PNG must begin with IHDR")
        if kind == b"IHDR":
            if chunks or length != 13: raise ValueError("Invalid PNG header")
            w, h, depth, color, compression, filtering, interlace = struct.unpack(">IIBBBBB", body)
            if (w,h,depth,compression,filtering,interlace) != (size,size,8,0,0,0) or color not in (2,6):
                raise ValueError("PNG must be exact-size, non-interlaced 8-bit RGB/RGBA")
            channels = 3 if color == 2 else 4
        elif kind == b"IDAT": compressed.extend(body)
        elif kind == b"IEND":
            if length != 0 or pos + 12 != len(data): raise ValueError("Invalid PNG end")
        elif kind[:1].isupper() and kind != b"PLTE": raise ValueError("Unknown critical PNG chunk")
        chunks.append(kind);pos += length + 12
        if len(chunks) > 128: raise ValueError("Too many PNG chunks")
    if not compressed or chunks[-1] != b"IEND": raise ValueError("Missing PNG data/end")
    expected = size * (1 + size * channels)
    decoder = zlib.decompressobj()
    raw = decoder.decompress(bytes(compressed), expected + 1)
    if len(raw) != expected or not decoder.eof or decoder.unused_data or decoder.unconsumed_tail:
        raise ValueError("PNG decompressed size/stream mismatch")
    if any(raw[row * (size * channels + 1)] > 4 for row in range(size)):
        raise ValueError("Unsupported PNG scanline filter")


def game_config(profile: dict) -> bytes:
    p = profile_error(profile)
    root = ET.Element("Game", {"configVersion": "1"})
    ET.SubElement(root, "Identity", {"Name": p["identity_name"], "Publisher": p["identity_publisher"], "Version": p["version"]})
    executables = ET.SubElement(root, "ExecutableList")
    ET.SubElement(executables, "Executable", {"Name": "1792.exe", "Id": "Game", "TargetDeviceFamily": "PC"})
    ET.SubElement(root, "ShellVisuals", {"DefaultDisplayName": p["display_name"],
                  "PublisherDisplayName": p["publisher_display_name"], "Description": p["description"],
                  "ForegroundText": "light", "BackgroundColor": "#172321",
                  **{key: "Assets/" + key + ".png" for key in LOGOS}})
    ET.SubElement(root, "StoreId").text = p["store_id"]
    desktop = ET.SubElement(root, "DesktopRegistration")
    ET.SubElement(desktop, "ProcessorArchitecture").text = "x64"
    ET.indent(root)
    return ET.tostring(root, encoding="utf-8", xml_declaration=True) + b"\n"


def stage_pc(package: Path, profile: dict, assets: Path, output: Path, *, expected_commit: str, expected_tree: str) -> dict:
    # Validate everything before creating any destination. This stages data; it runs no executable.
    p = profile_error(profile)
    verification = verify(package, expected_commit=expected_commit, expected_tree=expected_tree)
    if verification["target"] != "windows_local": raise ValueError("Microsoft staging requires a local-PC payload, not another store package")
    if _linked(assets) or not assets.is_dir(): raise ValueError("A regular original-logo directory is required")
    logos = {}
    for key, size in LOGOS.items():
        data = read_small(assets / (key + ".png"));png_check(data, size);logos[key] = data
    if output.exists() or _linked(output): raise ValueError("Refusing to replace an existing staging output")
    package_root = package.resolve()
    if output.resolve().is_relative_to(package_root) or output.resolve().is_relative_to(assets.resolve()):
        raise ValueError("Derived staging must be outside input directories")
    output.parent.mkdir(parents=True, exist_ok=True)
    scratch = Path(tempfile.mkdtemp(prefix=".microsoft-stage-", dir=output.parent))
    reader = Package(package)
    try:
        loose = scratch / "loose";loose.mkdir();(loose / "Assets").mkdir()
        manifest = _json(reader.small("manifest.json"))
        for name in sorted(PAYLOAD_NAMES):
            dest = loose / name
            with reader.open("content/" + name) as source, dest.open("xb") as stream:
                remaining = reader.files["content/" + name]
                while remaining:
                    block = source.read(min(1024 * 1024, remaining))
                    if not block: raise ValueError("Source truncated during copy")
                    stream.write(block);remaining -= len(block)
                if source.read(1): raise ValueError("Source grew during copy")
            with dest.open("rb") as stream: copied_digest = hashlib.file_digest(stream, "sha256").hexdigest()
            if copied_digest != manifest["files"][name]["sha256"]:
                raise ValueError("Source changed during staging")
        (loose / "MicrosoftGame.config").write_bytes(game_config(p))
        for key, data in logos.items(): (loose / "Assets" / (key + ".png")).write_bytes(data)
        files = {}
        for path in sorted(loose.rglob("*")):
            if path.is_file():
                with path.open("rb") as stream: digest = hashlib.file_digest(stream, "sha256").hexdigest()
                files[path.relative_to(loose).as_posix()] = {"bytes": path.stat().st_size, "sha256": digest}
        receipt = {"schema": "cg.microsoft-pc-stage.v1", "game_id": "1792", "operation_id": "microsoft.stage-loose.v1",
                   "source_commit": expected_commit, "source_tree": expected_tree,
                   "input_manifest_sha256": verification["manifest_sha256"], "identity": p,
                   "identity_assignment_verified": False, "package_format": "MSIXVC", "files": files,
                   "makepkg_executed": False, "submission_validated": False, "store_uploaded": False, "console_port": False}
        (scratch / "stage.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
        scratch.rename(output)
        return receipt
    except Exception:
        shutil.rmtree(scratch, ignore_errors=True)
        raise
    finally: reader.close()


def inspect_stage(root: Path) -> dict:
    if _linked(root) or not root.is_dir(): raise ValueError("Regular staging directory required")
    receipt = _json(read_small(root / "stage.json"))
    expected_keys = {"schema", "game_id", "operation_id", "source_commit", "source_tree", "input_manifest_sha256",
                     "identity", "identity_assignment_verified", "package_format", "files", "makepkg_executed",
                     "submission_validated", "store_uploaded", "console_port"}
    if set(receipt) != expected_keys or receipt["schema"] != "cg.microsoft-pc-stage.v1" or receipt["package_format"] != "MSIXVC":
        raise ValueError("Unsupported staging record")
    if receipt["game_id"] != "1792" or receipt["operation_id"] != "microsoft.stage-loose.v1": raise ValueError("Wrong staging identity")
    for key in ("source_commit", "source_tree", "input_manifest_sha256"):
        if not isinstance(receipt[key], str) or not re.fullmatch(r"[0-9a-f]{%d}" % (64 if key.endswith("sha256") else 40), receipt[key]):
            raise ValueError("Invalid source identity")
    for key in ("identity_assignment_verified", "makepkg_executed", "submission_validated", "store_uploaded", "console_port"):
        if receipt[key] is not False: raise ValueError("Staging record cannot claim native execution or approval")
    if not isinstance(receipt["files"], dict) or set(receipt["files"]) != LOOSE_NAMES: raise ValueError("Wrong loose-file allowlist")
    seen = set()
    for path in root.rglob("*"):
        if _linked(path): raise ValueError("Linked staging entry")
        name = path.relative_to(root).as_posix()
        if path.is_dir():
            if name not in {"loose", "loose/Assets"}: raise ValueError("Unexpected staging directory")
        elif path.is_file(): seen.add(name)
        else: raise ValueError("Non-regular staging member")
    if seen != {"stage.json"} | {"loose/" + name for name in LOOSE_NAMES}: raise ValueError("Changed loose payload set")
    for name, record in receipt["files"].items():
        path = root / "loose" / name
        if not isinstance(record, dict) or set(record) != {"bytes", "sha256"} or type(record["bytes"]) is not int:
            raise ValueError("Invalid loose file record")
        if not 0 < record["bytes"] <= 512 * 1024 * 1024 or path.stat().st_size != record["bytes"]:
            raise ValueError("Changed loose payload length")
        with path.open("rb") as stream: digest = hashlib.file_digest(stream, "sha256").hexdigest()
        if digest != record["sha256"]: raise ValueError("Changed loose payload hash")
    if read_small(root / "loose/MicrosoftGame.config") != game_config(receipt["identity"]): raise ValueError("Configuration differs from declared PC identity")
    for key, size in LOGOS.items(): png_check(read_small(root / "loose/Assets" / (key + ".png")), size)
    return receipt


def command_plan(stage_root: Path, makepkg: Path, output: Path) -> list[list[str]]:
    # No command, flags or filenames are accepted from the manifest/profile.
    return [[str(makepkg), "genmap", "/f", str(output / "layout.xml"), "/d", str(stage_root / "loose")],
            [str(makepkg), "pack", "/pc", "/f", str(output / "layout.xml"), "/d", str(stage_root / "loose"),
             "/pd", str(output / "packages"), "/validationcritical"]]


def pack_pc(stage_root: Path, output: Path, makepkg: Path, expected_tool_sha256: str, *, execute: bool = False) -> dict:
    receipt = inspect_stage(stage_root)
    if not re.fullmatch(r"[0-9a-f]{64}", expected_tool_sha256): raise ValueError("Pin the trusted installed MakePkg executable hash")
    if not makepkg.is_absolute() or _linked(makepkg) or not makepkg.is_file(): raise ValueError("Explicit regular absolute MakePkg path required")
    with makepkg.open("rb") as stream: digest = hashlib.file_digest(stream, "sha256").hexdigest()
    if digest != expected_tool_sha256: raise ValueError("MakePkg hash mismatch")
    if output.exists() or _linked(output) or output.resolve().is_relative_to(stage_root.resolve()): raise ValueError("New external output directory required")
    plan = command_plan(stage_root.resolve(), makepkg.resolve(), output.resolve())
    report = {"schema": "cg.makepkg-execution.v1", "source_commit": receipt["source_commit"], "source_tree": receipt["source_tree"],
              "input_stage_sha256": sha(read_small(stage_root / "stage.json")), "tool_sha256": digest,
              "operation_id": "microsoft.makepkg-local.v1", "commands": plan, "executed": False,
              "store_uploaded": False, "console_certified": False, "production_encryption": False,
              "steps": [], "status": "planned_only"}
    if not execute: return report
    if os.name != "nt": raise ValueError("Actual MakePkg execution requires Windows; a generated plan is not a native package")
    output.mkdir(parents=True);(output / "packages").mkdir()
    try:
        for i, command in enumerate(plan):
            inspect_stage(stage_root)
            with makepkg.open("rb") as stream:
                if hashlib.file_digest(stream, "sha256").hexdigest() != digest: raise ValueError("MakePkg changed before execution")
            log = output / ("step-%d.log" % i)
            # stdout goes directly to file, not unbounded process output retained in memory.
            with log.open("wb") as stream:
                result = subprocess.run(command, cwd=stage_root, stdout=stream, stderr=subprocess.STDOUT,
                                        timeout=600, check=False, shell=False)
            report["executed"] = True
            report["steps"].append({"index": i, "exit_code": result.returncode, "log": log.name})
            if result.returncode: raise RuntimeError("MakePkg failed; previous source and output logs retained")
        produced = list((output / "packages").glob("*.msixvc"))
        if not produced or any(_linked(p) or not p.is_file() or p.stat().st_size == 0 for p in produced):
            raise RuntimeError("MakePkg did not produce a nonempty MSIXVC package")
        report["status"] = "makepkg_completed_not_store_approved"
    except Exception:
        report["status"] = "failed_or_interrupted"
        raise
    finally:
        (output / "execution.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    staging = sub.add_parser("stage")
    for flag in ("package", "identity", "assets", "output"): staging.add_argument("--" + flag, type=Path, required=True)
    for flag in ("expected-commit", "expected-tree"): staging.add_argument("--" + flag, required=True)
    packing = sub.add_parser("pack")
    for flag in ("stage", "makepkg", "output"): packing.add_argument("--" + flag, type=Path, required=True)
    packing.add_argument("--tool-sha256", required=True)
    packing.add_argument("--execute", action="store_true", help="Run local genmap and pack only, on Windows; no upload or installation")
    args = parser.parse_args()
    if args.command == "stage":
        result = stage_pc(args.package, _json(read_small(args.identity, 8192)), args.assets, args.output,
                          expected_commit=args.expected_commit, expected_tree=args.expected_tree)
    else: result = pack_pc(args.stage, args.output, args.makepkg, args.tool_sha256, execute=args.execute)
    print(json.dumps(result, indent=2))


if __name__ == "__main__": main()
