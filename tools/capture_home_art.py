"""Run native visual qualification into a new directory; never overwrite evidence.

Example: python tools/capture_home_art.py --godot /path/to/godot --output /new/run
The executable may be the existing Godot 4.5.1. No providers, downloads or servers.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).rstrip("\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=shutil.which("godot") or shutil.which("godot4"))
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--xvfb", action="store_true", help="Use a private Linux X display even when DISPLAY is set")
    parser.add_argument("--profile", choices=("home", "workshop"), default="home",
                        help="Retained Home study or integrated input-driven smith commission")
    args = parser.parse_args()
    workshop = args.profile == "workshop"
    prefix = "home-workshop" if workshop else "home-art"
    expected = 5 if workshop else 8
    if args.xvfb and not sys.platform.startswith("linux"):
        parser.error("--xvfb is only supported on Linux")
    if not args.godot:
        parser.error("Godot executable is required; no render is inferred from source")
    output = args.output.resolve()
    output.mkdir(parents=False, exist_ok=False)
    identity: dict = {"schema": "1792.art-execution.v1", "operation_id": "home-workshop-capture.v2" if workshop else "home-art-capture.v1",
                      "source_commit": "", "dirty": True, "hardware_performance_qualified": False}
    try:
        head = git("rev-parse", "HEAD")
        status = git("status", "--porcelain", "--untracked-files=all").splitlines()
        dirty = any(not (line[3:].startswith("game/") and line.endswith((".gd.uid", ".gdshader.uid"))) for line in status)
        identity.update(git_head=head, dirty=dirty, source_commit="" if dirty else head)
    except (OSError, subprocess.CalledProcessError):
        identity["git_status"] = "unavailable"
    paths = sorted(p for top in ("game", "tools", "docs") for p in (ROOT / top).rglob("*")
                   if p.is_file() and not {".godot", "__pycache__"}.intersection(p.parts)
                   and p.suffix not in {".pyc", ".uid", ".import"})
    hashes = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    identity["source_files"] = hashes
    identity["source_content_sha256"] = hashlib.sha256(json.dumps(hashes, sort_keys=True).encode()).hexdigest()
    (output / "execution.json").write_text(json.dumps(identity, indent=2)+"\n")
    env = {**os.environ, "HOME_ART_OUTPUT": str(output), "SOURCE_COMMIT": identity["source_commit"],
           "HOME_WORKSHOP_OUTPUT": str(output), "SOURCE_CONTENT_SHA256": identity["source_content_sha256"],
           "GODOT_SILENCE_ROOT_WARNING": "1"}
    commands = [([args.godot, "--headless", "--path", "game", "--editor", "--import"], "import.log")]
    if workshop:
        commands.append(([args.godot, "--headless", "--fixed-fps", "60", "--path", "game",
                          "--script", "res://tests/test_home_workshop.gd"], "journey.log"))
    render = [args.godot, "--path", "game", "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy",
              "--fixed-fps", "60", "--script", "res://tests/render_home_workshop.gd" if workshop else "res://tests/render_home_art.gd"]
    if sys.platform.startswith("linux") and (args.xvfb or not os.environ.get("DISPLAY")):
        xvfb = shutil.which("xvfb-run")
        if not xvfb:
            raise RuntimeError("No display or xvfb-run: rendered qualification NOT RUN")
        render = [xvfb, "-a", *render]
    commands.append((render, "render.log"))
    for command, name in commands:
        run = subprocess.run(command, cwd=ROOT, env=env, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, text=True, timeout=120, check=False)
        (output / name).write_text(run.stdout, encoding="utf-8")
        if name == "journey.log" and not re.search(r"HOME_WORKSHOP_TESTS: [1-9][0-9]* passed, 0 failed", run.stdout):
            raise RuntimeError("Input journey did not reach its successful completion marker")
        if run.returncode or re.search(r"(?m)^(?:SCRIPT ERROR|ERROR):", run.stdout):
            raise RuntimeError(f"{name} failed; retained log: {output / name}")
    batch = json.loads((output / f"{prefix}-captures.json").read_text())
    records = batch["captures"]
    if batch["failures"] or len(records) != expected:
        raise RuntimeError("Incomplete capture batch")
    for record in records:
        filename = output / f"{prefix}-{record['capture_id']}.png"
        data = filename.read_bytes()
        if data[:8] != b"\x89PNG\r\n\x1a\n" or list(struct.unpack(">II", data[16:24])) != record["viewport"]:
            raise RuntimeError(f"Invalid PNG dimensions: {filename}")
        if hashlib.sha256(data).hexdigest() != record["image_sha256"]:
            raise RuntimeError(f"Capture hash mismatch: {filename}")
    by_id = {record["capture_id"]: record for record in records}
    ids = ["working-daylight", "working-golden"] if workshop else [f"courtyard-{n}" for n in ("baseline", "daylight", "golden", "evening")]
    comparison = [by_id[name]["scene_pixels_sha256"] for name in ids]
    if len(set(comparison)) != len(ids):
        raise RuntimeError("Scene pixels did not change between comparison presets")
    if workshop:
        journey = json.loads((output / "home-workshop-journey.json").read_text())
        if journey["source_content_sha256"] != identity["source_content_sha256"]:
            raise RuntimeError("Journey source identity mismatch")
        if [step["step"] for step in journey["steps"]] != ["fuel", "working", "tools", "complete"]:
            raise RuntimeError("Incomplete executed journey")
        for record in records:
            if record["source_content_sha256"] != identity["source_content_sha256"]:
                raise RuntimeError("Capture source identity mismatch")
            if record["journey_sha256"] != hashlib.sha256((output / "home-workshop-journey.json").read_bytes()).hexdigest():
                raise RuntimeError("Capture journey identity mismatch")
    identity["qualified_capture_count"] = len(records)
    identity["completed"] = True
    (output / "execution.json").write_text(json.dumps(identity, indent=2)+"\n")
    print(f"{'HOME_WORKSHOP' if workshop else 'HOME_ART'}_CAPTURE: {expected} verified native captures in {output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
