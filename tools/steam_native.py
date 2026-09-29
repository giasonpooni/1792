"""Acquire and qualify one pinned native Steam runtime; no login, upload or redistribution.

The normal local build is immutable input. Native files are fetched from upstream
into an explicit directory, never added to repository source or CI artifacts.
The no-client probe is a native ABI/load test, not a successful Steam session.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request
from pathlib import Path
from verify_platform import Package, _json, _linked, verify

ARCHIVE = "win64-g451-s162-gs4161.tar.xz"
URL = "https://github.com/GodotSteam/GodotSteam/releases/download/v4.16.1/" + ARCHIVE
ARCHIVE_BYTES = 111555348
ARCHIVE_SHA256 = "a0d7483433824f8ab72e16e45cadb6e44b4b697fe5b598a0c90b9973a41e0999"
EDITOR = "godotsteam.451.editor.win64.exe"
CONSOLE = "godotsteam.451.editor.win64.console.exe"
TEMPLATE = "godotsteam.451.template.win64.exe"
DLL = "steam_api64.dll"
MEMBERS = {
    "godotsteam.451.debug.template.win64.exe": (96555008, "1c85d3ce043ba29d3c665004fb32b7981cfca683138d076dc7a287b5cfa61598"),
    CONSOLE: (188928, "bd65a6c7ded64739d0e83d9184a871c0c52ae77551318c748255954b748fc273"),
    EDITOR: (165835776, "7df73b10bc46ff997d90fdb48a7e891ce5f88181532d776833bc6e03e1400815"),
    TEMPLATE: (98420736, "39aee696b2202c87d45926419d321c9eaee538a7ebe0b78c67abcb447ffe8ac7"),
    DLL: (319584, "e082bf5c9f881c822b1540a76b74f9d15e18019a73ebd206a559595badcb7f65"),
}
SELECTED = {CONSOLE, EDITOR, TEMPLATE, DLL}
ROOT = Path(__file__).resolve().parents[1]
NOTICE = """Native dependency qualification only.
GodotSteam 4.16.1 / Godot 4.5.1 / Steamworks 1.62, upstream module build.
This older version is pinned to the game's reference engine, not claimed current.
Downloaded native software retains its own rights. No Steamworks account,
redistribution permission, App ID, subscription or certification is granted.
Do not publish this reference directory or copy DLLs into the local-PC package.
GodotSteam: https://codeberg.org/godotsteam/godotsteam (MIT; publisher notices).
Steamworks: https://partner.steamgames.com/doc/sdk (Valve's separate terms).
"""


def digest(path: Path, size: int | None = None) -> str:
    if _linked(path) or not path.is_file():
        raise ValueError("Expected a regular nonlinked file: " + path.name)
    if size is not None and path.stat().st_size != size:
        raise ValueError("Native file size mismatch: " + path.name)
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def reference_record() -> dict:
    return {"schema": "cg.steam-native-reference.v1", "operation_id": "steam.acquire-reference.v1",
            "archive_url": URL, "archive_sha256": ARCHIVE_SHA256, "archive_bytes": ARCHIVE_BYTES,
            "engine_line": "4.5.1", "bridge_release": "4.16.1", "steamworks_line": "1.62",
            "files": {name: {"bytes": MEMBERS[name][0], "sha256": MEMBERS[name][1]} for name in sorted(SELECTED)},
            "steam_client_qualified": False, "redistribution_authorized": False}


def _extract_locked(archive: Path, destination: Path, members: dict, selected: set[str]) -> None:
    """No extractall: exact flat regular members, bounded streamed copies and hashes.

    Parameters enable small synthetic archive tests; the public installer supplies
    only the constants above. Destination must be a fresh caller-owned scratch dir.
    """
    seen: set[str] = set()
    with tarfile.open(archive, "r:xz") as source:
        for item in source:
            if item.name not in members or item.name in seen or not item.isfile() or "/" in item.name or "\\" in item.name:
                raise ValueError("Unexpected, duplicate or nonregular native archive member")
            size, expected = members[item.name]
            if type(size) is not int or size <= 0 or item.size != size:
                raise ValueError("Native member size mismatch")
            seen.add(item.name)
            digestor = hashlib.sha256()
            stream = source.extractfile(item)
            if stream is None: raise ValueError("Missing native member stream")
            target = (destination / item.name).open("xb") if item.name in selected else None
            try:
                remaining = size
                while remaining:
                    block = stream.read(min(remaining, 1024 * 1024))
                    if not block: raise ValueError("Truncated native archive member")
                    digestor.update(block); remaining -= len(block)
                    if target: target.write(block)
                if stream.read(1) or digestor.hexdigest() != expected:
                    raise ValueError("Native member digest mismatch")
            finally:
                stream.close()
                if target: target.close()
    if seen != set(members) or not selected <= seen:
        raise ValueError("Incomplete native archive")


def install(output: Path, archive: Path | None = None) -> dict:
    if output.exists() or _linked(output): raise ValueError("Refusing to replace an existing native reference")
    output.parent.mkdir(parents=True, exist_ok=True)
    scratch = Path(tempfile.mkdtemp(prefix=".steam-reference-", dir=output.parent))
    try:
        if archive is None:
            archive = scratch / ARCHIVE
            request = urllib.request.Request(URL, headers={"User-Agent": "1792-native-reference"})
            total = 0
            with urllib.request.urlopen(request, timeout=180) as source, archive.open("xb") as target:
                while block := source.read(1024 * 1024):
                    total += len(block)
                    if total > ARCHIVE_BYTES: raise ValueError("Native download exceeded its locked size")
                    target.write(block)
        if digest(archive, ARCHIVE_BYTES) != ARCHIVE_SHA256: raise ValueError("Native archive hash mismatch")
        content = scratch / "reference"; content.mkdir()
        _extract_locked(archive, content, MEMBERS, SELECTED)
        record = reference_record()
        (content / "reference.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
        (content / "REFERENCE-NOTICE.txt").write_text(NOTICE, encoding="utf-8", newline="\n")
        inspect(content)
        content.rename(output)
        return record
    finally:
        shutil.rmtree(scratch, ignore_errors=True)


def inspect(reference: Path) -> dict:
    if _linked(reference) or not reference.is_dir(): raise ValueError("Regular native reference directory required")
    if {p.name for p in reference.iterdir()} != SELECTED | {"reference.json", "REFERENCE-NOTICE.txt"}:
        raise ValueError("Native reference file allowlist mismatch")
    p = reference / "reference.json"
    if _linked(p) or not p.is_file() or p.stat().st_size > 16384: raise ValueError("Invalid native reference receipt")
    record = _json(p.read_bytes())
    if json.dumps(record, sort_keys=True) != json.dumps(reference_record(), sort_keys=True): raise ValueError("Native reference receipt differs from trusted lock")
    if digest(reference / "REFERENCE-NOTICE.txt", len(NOTICE.encode())) != hashlib.sha256(NOTICE.encode()).hexdigest():
        raise ValueError("Native reference notice changed")
    for name in SELECTED:
        size, expected = MEMBERS[name]
        if digest(reference / name, size) != expected: raise ValueError("Native runtime bytes changed: " + name)
    return record


def validate_probe(value: object, *, source_commit: str, source_tree: str, exported: bool) -> dict:
    if not isinstance(value, dict) or value.get("schema") != "cg.steam-native-probe.v1":
        raise ValueError("Missing native probe observation")
    exact = {"source_commit": source_commit, "source_tree": source_tree, "os": "Windows",
             "exported": exported, "native_module_loaded": True, "adapter_contract_matches": True,
             "isolated_user_storage": True,
             "client_running": False, "adapter_preflight_refused_without_client": True,
             "sdk_session_initialized": False, "live_client_qualified": False,
             "physical_hardware_qualified": False, "store_uploaded": False, "errors": []}
    if set(value) != set(exact) | {"schema", "engine", "build_execution_id"}:
        raise ValueError("Unexpected native probe fields")
    if not isinstance(value.get("build_execution_id"), str) or not 0 < len(value["build_execution_id"]) <= 160:
        raise ValueError("Invalid build execution identity")
    for key, expected in exact.items():
        actual = value.get(key)
        if type(actual) is not type(expected) or actual != expected:
            raise ValueError("Native observation did not establish " + key)
    engine = value.get("engine")
    if not isinstance(engine, str) or not (engine == "4.5.1-stable" or (engine.startswith("4.5.1-stable (") and engine.endswith(")"))):
        raise ValueError("Native engine line changed")
    return value


def _run(command: list[str], cwd: Path, environment: dict, log: Path) -> str:
    """Explicit local process, no shell; fixed timeout; retain complete observed output."""
    with log.open("wb") as stream:
        result = subprocess.run(command, cwd=cwd, env=environment, stdout=stream,
                                stderr=subprocess.STDOUT, timeout=180, check=False, shell=False)
    if log.stat().st_size > 4 * 1024 * 1024: raise RuntimeError("Native probe produced excessive log output")
    text = log.read_text(encoding="utf-8", errors="replace")
    print(text, flush=True)
    if result.returncode or any(line.startswith(("SCRIPT ERROR:", "ERROR:")) for line in text.splitlines()):
        raise RuntimeError("Native process failed; inspect " + log.name)
    return text


def qualify(reference: Path, package: Path, evidence: Path, *, source_commit: str, source_tree: str) -> dict:
    """Execute only verified native binaries + verified PCK, in isolated user storage.

    Native work files are temporary and are NOT a distribution package. Only text
    logs, observed licence metadata and identity/digest records leave the scratch dir.
    """
    if os.name != "nt": raise ValueError("Native Windows qualification must run on Windows")
    locked = inspect(reference)
    reference = reference.absolute()
    verified = verify(package, expected_commit=source_commit, expected_tree=source_tree)
    if verified["target"] != "windows_local": raise ValueError("Require the unmodified local-PC base package")
    if evidence.exists() or _linked(evidence): raise ValueError("Fresh native evidence output required")
    for root in (reference, package):
        if evidence.resolve().is_relative_to(root.resolve()): raise ValueError("Evidence must be outside immutable inputs")
    evidence.mkdir(parents=True)
    record = {"schema": "cg.steam-native-qualification.v1", "operation_id": "steam.qualify-native-absent-client.v1",
              "verification_id": "steam.native-module-and-packaged-probe.v1", "source_commit": source_commit,
              "source_tree": source_tree, "execution_id": os.environ.get("GITHUB_RUN_ID", "local-native-qualification"),
              "base_manifest_sha256": verified["manifest_sha256"], "reference": locked,
              "status": "started", "native_binaries_redistributed": False, "live_client_qualified": False,
              "physical_hardware_qualified": False, "store_uploaded": False, "observations": {}}
    try:
        with tempfile.TemporaryDirectory(prefix="1792-native-steam-") as temp:
            work = Path(temp); payload = work / "payload"; payload.mkdir()
            user = work / "isolated-user"; user.mkdir()
            environment = os.environ.copy()
            environment.update(APPDATA=str(user), LOCALAPPDATA=str(user), GODOT_SILENCE_ROOT_WARNING="1",
                               CG_NATIVE_PROBE_USER_ROOT=str(user))
            for name, target in ((TEMPLATE, "1792.exe"), (DLL, DLL)):
                shutil.copyfile(reference / name, payload / target)
                if digest(payload / target, MEMBERS[name][0]) != MEMBERS[name][1]: raise ValueError("Native copy changed")
            reader = Package(package)
            try:
                manifest = _json(reader.small("manifest.json"))
                with reader.open("content/1792.pck") as source, (payload / "1792.pck").open("xb") as target:
                    shutil.copyfileobj(source, target, 1024 * 1024)
            finally: reader.close()
            pck = manifest["files"]["1792.pck"]
            if digest(payload / "1792.pck", pck["bytes"]) != pck["sha256"]: raise ValueError("PCK changed during assembly")
            record["payload"] = {"native_exe_sha256": MEMBERS[TEMPLATE][1], "native_dll_sha256": MEMBERS[DLL][1],
                                  "base_pck_sha256": pck["sha256"], "pck_modified": False}
            inspect(reference)
            output = _run([str(payload / "1792.exe"), "--headless", "--main-pack", str(payload / "1792.pck"),
                           "--script", "res://platform/steam_native_probe.gd", "--", "--steam-native-probe"], payload,
                          environment, evidence / "native-packaged-contract.log")
            prefix = "STEAM_NATIVE_RECORD: "
            rows = [line[len(prefix):] for line in output.splitlines() if line.startswith(prefix)]
            if len(rows) != 1 or "STEAM_NATIVE_PROBE: pass" not in output: raise RuntimeError("Native completion marker missing")
            record["observations"]["native_contract"] = validate_probe(_json(rows[0].encode()), source_commit=source_commit,
                                                                        source_tree=source_tree, exported=True)
            # Execute the unchanged existing gameplay/recovery/reading probe with the native template.
            output = _run([str(payload / "1792.exe"), "--headless", "--", "--platform-smoke"], payload,
                          environment, evidence / "native-packaged-gameplay.log")
            prefix = "PLATFORM_BOOT_RECORD: "
            rows = [line[len(prefix):] for line in output.splitlines() if line.startswith(prefix)]
            if len(rows) != 1 or "PLATFORM_BOOT_SMOKE: pass" not in output: raise RuntimeError("Native gameplay probe incomplete")
            gameplay = _json(rows[0].encode())
            if gameplay.get("os") != "Windows" or gameplay.get("exported") is not True or gameplay.get("errors") != []:
                raise RuntimeError("Native packaged game did not pass its inherited probe")
            record["observations"]["native_gameplay"] = gameplay
            notices = user / "Godot/app_userdata/1792/platform-engine-notices.json"
            if _linked(notices) or not notices.is_file() or not 0 < notices.stat().st_size < 2 * 1024 * 1024:
                raise RuntimeError("Native runtime notices not retained")
            shutil.copyfile(notices, evidence / "native-engine-notices.json")
            if digest(payload / "1792.pck", pck["bytes"]) != pck["sha256"]: raise ValueError("Probe modified the game pack")
            if digest(payload / "1792.exe", MEMBERS[TEMPLATE][0]) != MEMBERS[TEMPLATE][1]: raise ValueError("Probe modified runtime")
            if digest(payload / DLL, MEMBERS[DLL][0]) != MEMBERS[DLL][1]: raise ValueError("Probe modified runtime library")
        record["status"] = "native_load_contract_and_local_gameplay_passed_no_client"
    except Exception:
        record["status"] = "failed_or_interrupted"
        raise
    finally:
        record["evidence_files"] = {p.name: {"bytes": p.stat().st_size, "sha256": digest(p)}
                                    for p in sorted(evidence.iterdir()) if p.is_file()}
        (evidence / "qualification.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    return record


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    install_cmd = commands.add_parser("install", help="Download this locked upstream Windows reference; no execution")
    install_cmd.add_argument("--output", type=Path, required=True)
    install_cmd.add_argument("--archive", type=Path)
    inspect_cmd = commands.add_parser("inspect", help="Check the installed reference without executing it")
    inspect_cmd.add_argument("--reference", type=Path, required=True)
    probe = commands.add_parser("qualify", help="Execute the native no-client and inherited gameplay probes on Windows")
    for field in ("reference", "package", "evidence"): probe.add_argument("--" + field, type=Path, required=True)
    for field in ("expected-commit", "expected-tree"): probe.add_argument("--" + field, required=True)
    args = parser.parse_args()
    if args.command == "install": result = install(args.output, args.archive)
    elif args.command == "inspect": result = inspect(args.reference)
    else: result = qualify(args.reference, args.package, args.evidence,
                           source_commit=args.expected_commit, source_tree=args.expected_tree)
    print(json.dumps(result, indent=2))


if __name__ == "__main__": main()
