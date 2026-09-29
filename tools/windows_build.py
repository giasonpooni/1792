"""Export and execute the actual Windows payload before allowlisted staging."""
from __future__ import annotations
import argparse
import json
import os
import re
import shutil
import subprocess
from pathlib import Path
from package_platform import ROOT, stage
from verify_platform import verify


def checked(command: list[str], name: str, cwd: Path) -> str:
    result = subprocess.run(command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            encoding="utf-8", errors="replace", timeout=180, check=False)
    (ROOT / "test-results").mkdir(exist_ok=True)
    (ROOT / "test-results" / (name + ".log")).write_text(result.stdout, encoding="utf-8")
    print(result.stdout)
    if result.returncode or re.search(r"(?m)^(SCRIPT ERROR|ERROR):", result.stdout):
        raise RuntimeError(name + " failed")
    return result.stdout


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    args = parser.parse_args()
    if os.name != "nt":
        raise RuntimeError("Run on actual Windows; cross-export alone does not qualify execution")
    target = ROOT / "build/windows"
    if target.exists():
        raise RuntimeError("Refusing to replace existing build directory")
    target.mkdir(parents=True)
    source_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    source_tree = subprocess.check_output(["git", "rev-parse", "HEAD^{tree}"], cwd=ROOT, text=True).strip()
    identity_file = ROOT / "game/platform/build_identity.json"
    original_identity = identity_file.read_bytes()
    try:
        # Derived export metadata, restored afterward. Source archives retain the tracked template.
        identity_file.write_text(json.dumps({"schema": "cg.export-source.v1", "source_commit": source_commit,
                                            "source_tree": source_tree, "execution_id": os.environ.get("GITHUB_RUN_ID", "local-windows-build")}), encoding="utf-8")
        checked([args.godot, "--headless", "--path", "game", "--export-release",
                 "Windows x86_64 (local)", str(target / "1792.exe")], "windows-export", ROOT)
    finally:
        identity_file.write_bytes(original_identity)
    integration = checked([str(target / "1792.exe"), "--headless", "--", "--hardware-session", "--platform-integration-smoke"],
                          "windows-integration-boot", target)
    prefix = "INTEGRATION_BOOT_RECORD: "
    observation = json.loads(next(line[len(prefix):] for line in integration.splitlines() if line.startswith(prefix)))
    if observation["errors"] or observation["source_commit"] != source_commit or observation["source_tree"] != source_tree:
        raise RuntimeError("Exported integration probe did not match the selected source identity")
    if observation["os"] != "Windows" or not observation["exported"] or "INTEGRATION_BOOT_SMOKE: pass" not in integration:
        raise RuntimeError("Missing actual exported Windows integration probe")
    (ROOT / "test-results/windows-integration-observation.json").write_text(json.dumps(observation, indent=2), encoding="utf-8")
    # New process, no --path to source: resource access must come from the exported PCK.
    stdout = checked([str(target / "1792.exe"), "--headless", "--", "--platform-smoke"],
                     "windows-packaged-boot", target)
    if "PLATFORM_BOOT_SMOKE: pass" not in stdout:
        raise RuntimeError("Packaged boot completion marker missing")
    line = next((line for line in stdout.splitlines() if line.startswith("PLATFORM_BOOT_RECORD: ")), "")
    record = json.loads(line.removeprefix("PLATFORM_BOOT_RECORD: "))
    if record["os"] != "Windows" or not record["exported"] or record["errors"]:
        raise RuntimeError("Probe did not observe a successful exported Windows process")
    source_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    source_tree = subprocess.check_output(["git", "rev-parse", "HEAD^{tree}"], cwd=ROOT, text=True).strip()
    record.update(source_commit=source_commit, source_tree=source_tree,
                  execution_id=os.environ.get("GITHUB_RUN_ID", "local-windows-build"),
                  verification_id="windows-exported-boot.v1")
    (ROOT / "test-results/windows-packaged-observation.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
    notices = Path(os.environ["APPDATA"]) / "Godot/app_userdata/1792/platform-engine-notices.json"
    output = ROOT / "build/package"
    stage(target, output, notices, target="windows_local", source_commit=source_commit,
          source_tree=source_tree, execution_id=record["execution_id"])
    shutil.make_archive(str(ROOT / "build/1792-windows-development"), "zip", output)
    report = verify(ROOT / "build/1792-windows-development.zip", expected_commit=source_commit, expected_tree=source_tree)
    (ROOT / "test-results/windows-package-verification.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("WINDOWS_PACKAGE: exported, executed and staged; no signing or store upload")


if __name__ == "__main__":
    main()
