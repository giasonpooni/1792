"""Stage an unsigned PC payload or offline Steam preview recipe. Never uploads.

Header checks are shape checks, not a replacement for executing the exported game.
The source identity is supplied by the build and recorded separately from hashes.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import struct
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGETS = ROOT / "platforms/targets.v1.json"
PAYLOAD = ("1792.exe", "1792.pck")
MAX_FILE_BYTES = 512 * 1024 * 1024


def sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def require_file(path: Path, limit: int = MAX_FILE_BYTES) -> None:
    if path.is_symlink() or not path.is_file() or not 0 < path.stat().st_size <= limit:
        raise ValueError(f"Missing, linked, empty or oversized input: {path.name}")


def check_payload(source: Path) -> None:
    for name in PAYLOAD:
        require_file(source / name)
    with (source / PAYLOAD[0]).open("rb") as stream:
        header = stream.read(64)
        if len(header) != 64 or header[:2] != b"MZ":
            raise ValueError("Payload is not a PE executable")
        offset = struct.unpack_from("<I", header, 0x3C)[0]
        if offset < 64 or offset > (source / PAYLOAD[0]).stat().st_size - 6:
            raise ValueError("Invalid PE header location")
        stream.seek(offset)
        if stream.read(6) != b"PE\0\0\x64\x86":
            raise ValueError("Expected a Windows x86_64 executable")
    with (source / PAYLOAD[1]).open("rb") as stream:
        if stream.read(4) != b"GDPC":
            raise ValueError("Expected a separate Godot PCK")


def identity(value: str, label: str) -> str:
    if not re.fullmatch(r"[0-9a-f]{40}", value):
        raise ValueError(f"{label} must be a full Git SHA, not a moving branch")
    return value


def steam_id(value: str | None) -> str:
    if value is None or not re.fullmatch(r"[1-9][0-9]{0,9}", value) or value == "480":
        raise ValueError("Supply the actual assigned positive app/depot ID; no sample IDs")
    return value


def steam_recipes(app_id: str, depot_id: str, source_commit: str) -> dict[str, bytes]:
    """Exact preview-only recipes. This function neither logs in nor invokes SteamCMD."""
    steam_id(app_id); steam_id(depot_id); identity(source_commit, "source_commit")
    if app_id == depot_id:
        raise ValueError("App and depot identities must be distinct")
    return {
        "steam-preview/app_build.vdf": (
            f'"AppBuild"\n{{\n "AppID" "{app_id}"\n "Desc" "1792 offline preview {source_commit}"\n'
            ' "Preview" "1"\n "ContentRoot" "../content"\n "BuildOutput" "../steam-preview-output"\n'
            f' "Depots"\n {{\n  "{depot_id}" "depot_build.vdf"\n }}\n}}\n').encode("utf-8"),
        "steam-preview/depot_build.vdf": (
            f'"DepotBuildConfig"\n{{\n "DepotID" "{depot_id}"\n'
            ' "FileMapping"\n {\n  "LocalPath" "*"\n  "DepotPath" "."\n  "recursive" "1"\n }\n}\n').encode("utf-8"),
    }


def stage(source: Path, output: Path, notices: Path, *, target: str,
          source_commit: str, source_tree: str, execution_id: str,
          app_id: str | None = None, depot_id: str | None = None) -> dict:
    targets = json.loads(TARGETS.read_text(encoding="utf-8"))["targets"]
    if target not in targets:
        raise ValueError("Unknown build target")
    if target not in ("windows_local", "steam_windows"):
        raise ValueError(targets[target]["reason"])
    identity(source_commit, "source_commit"); identity(source_tree, "source_tree")
    if not execution_id or len(execution_id) > 160:
        raise ValueError("A bounded execution identity is required")
    if target == "steam_windows":
        app_id, depot_id = steam_id(app_id), steam_id(depot_id)
        if app_id == depot_id:
            raise ValueError("App and depot identities must be distinct")
    elif app_id is not None or depot_id is not None:
        raise ValueError("Store IDs do not belong to the local PC target")
    check_payload(source)
    require_file(notices, 2 * 1024 * 1024)
    info = json.loads(notices.read_text(encoding="utf-8"))
    if (not isinstance(info, dict) or info.get("schema") != "cg.engine-notices.v1"
            or not isinstance(info.get("godot_license"), str) or not info["godot_license"]
            or not isinstance(info.get("components"), list) or not info["components"]
            or not isinstance(info.get("licenses"), dict) or not info["licenses"]
            or not str(info.get("engine", "")).startswith("4.5.1-stable")):
        raise ValueError("Notices must be obtained from the executed reference build")
    if output.exists() or output.is_symlink():
        raise ValueError("Refusing to overwrite an existing output")
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = Path(tempfile.mkdtemp(prefix=".1792-stage-", dir=output.parent))
    try:
        content = temporary / "content"
        content.mkdir()
        for name in PAYLOAD:
            shutil.copyfile(source / name, content / name)
        # Deliberate allowlist: ignored files, SDKs and credentials are not swept in.
        shutil.copyfile(ROOT / "LICENSE", content / "GAME-LICENSE.txt")
        shutil.copyfile(ROOT / "licenses/third-party/Godot-MIT.txt", content / "GODOT-LICENSE.txt")
        shutil.copyfile(notices, content / "ENGINE-NOTICES.json")
        (content / "README.txt").write_text(
            "1792 - Cartesian Graphics development build\n\n"
            "Keep 1792.exe and 1792.pck together. Run 1792.exe.\n"
            "Unsigned local PC prototype; not a store release or Xbox console build.\n"
            "Godot and its dependencies keep their own licences; see GODOT-LICENSE.txt\n"
            "and ENGINE-NOTICES.json (full runtime-reported copyright and licence texts).\n"
            "Choose Home territory. Xbox-style pad: A select, X interact, Y mount,\n"
            "Menu pause/save/settings, View stories, sticks move/look, RT run.\n"
            "Synthetic controller and headless tests do not qualify physical hardware.\n",
            encoding="utf-8")
        manifest = {
            "schema": "cg.platform-build.v2", "game_id": "1792", "target": target,
            "source_commit": source_commit, "source_tree": source_tree,
            "operation_id": "platform.stage-payload.v1", "execution_id": execution_id,
            "runtime_provider": "cg.local-pc.v1", "engine": info["engine"],
            "packaging_only": True, "store_uploaded": False, "signed": False,
            "console_certified": False,
            "steam_preview": None if target == "windows_local" else {
                "app_id": app_id, "depot_id": depot_id, "preview": True},
            "recipes": {},
            "files": {p.name: {"bytes": p.stat().st_size, "sha256": sha256(p)}
                      for p in sorted(content.iterdir())},
        }
        if target == "steam_windows":
            for name, data in steam_recipes(app_id, depot_id, source_commit).items():
                recipe = temporary / name
                recipe.parent.mkdir(exist_ok=True)
                recipe.write_bytes(data)
                manifest["recipes"][name] = {"bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
        (temporary / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        # Do not silently replace another build produced while staging.
        if output.exists():
            raise ValueError("Output appeared while staging")
        temporary.rename(output)
        return manifest
    finally:
        if temporary.exists():
            shutil.rmtree(temporary)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--notices", type=Path, required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--source-tree", required=True)
    parser.add_argument("--execution-id", required=True)
    parser.add_argument("--app-id"); parser.add_argument("--depot-id")
    args = parser.parse_args()
    try:
        print(json.dumps(stage(**vars(args)), indent=2))
        return 0
    except (ValueError, OSError, KeyError, TypeError) as error:
        parser.exit(2, f"Packaging refused: {error}\n")


if __name__ == "__main__":
    raise SystemExit(main())
