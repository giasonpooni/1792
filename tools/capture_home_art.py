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


def max_numeric_error(left, right) -> float:
    if isinstance(left, list) and isinstance(right, list):
        if len(left)!=len(right): return float("inf")
        return max((max_numeric_error(a,b) for a,b in zip(left,right)), default=0.0)
    if isinstance(left,(int,float)) and not isinstance(left,bool) and isinstance(right,(int,float)) and not isinstance(right,bool):
        import math
        return abs(left-right) if math.isfinite(left) and math.isfinite(right) else float("inf")
    return 0.0 if left==right else float("inf")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=shutil.which("godot") or shutil.which("godot4"))
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--xvfb", action="store_true", help="Use a private Linux X display even when DISPLAY is set")
    parser.add_argument("--profile", choices=("home", "workshop", "courtyard"), default="home",
                        help="Retained Home study or integrated input-driven smith commission")
    args = parser.parse_args()
    workshop = args.profile == "workshop"
    courtyard = args.profile == "courtyard"
    prefix = "courtyard" if courtyard else "home-workshop" if workshop else "home-art"
    expected = 6 if courtyard else 5 if workshop else 8
    if args.xvfb and not sys.platform.startswith("linux"):
        parser.error("--xvfb is only supported on Linux")
    if not args.godot:
        parser.error("Godot executable is required; no render is inferred from source")
    output = args.output.resolve()
    output.mkdir(parents=False, exist_ok=False)
    identity: dict = {"schema": "1792.art-execution.v1", "operation_id": "courtyard-walk-capture.v1" if courtyard else "home-workshop-capture.v2" if workshop else "home-art-capture.v1",
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
                   and p.suffix not in {".pyc", ".uid"})
    hashes = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    identity["source_files"] = hashes
    identity["source_content_sha256"] = hashlib.sha256(json.dumps(hashes, sort_keys=True).encode()).hexdigest()
    (output / "execution.json").write_text(json.dumps(identity, indent=2)+"\n")
    env = {**os.environ, "HOME_ART_OUTPUT": str(output), "SOURCE_COMMIT": identity["source_commit"],
           "HOME_WORKSHOP_OUTPUT": str(output), "SOURCE_CONTENT_SHA256": identity["source_content_sha256"],
           "COURTYARD_MOTION_TRACE": "1" if courtyard else "0", "GODOT_SILENCE_ROOT_WARNING": "1"}
    commands = [([args.godot, "--headless", "--path", "game", "--editor", "--import"], "import.log")]
    if workshop or courtyard:
        commands.append(([args.godot, "--headless", "--fixed-fps", "60", "--path", "game",
                          "--script", "res://tests/test_home_workshop.gd"], "journey.log"))
    render = [args.godot, "--path", "game", "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy",
              "--fixed-fps", "60", "--script", "res://tests/render_courtyard_walk.gd" if courtyard else "res://tests/render_home_workshop.gd" if workshop else "res://tests/render_home_art.gd"]
    if sys.platform.startswith("linux") and (args.xvfb or not os.environ.get("DISPLAY")):
        xvfb = shutil.which("xvfb-run")
        if not xvfb:
            raise RuntimeError("No display or xvfb-run: rendered qualification NOT RUN")
        render = [xvfb, "-a", *render]
    commands.append((render, "render.log"))
    for command, name in commands:
        run = subprocess.run(command, cwd=ROOT, env=env, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, text=True, timeout=300 if courtyard else 120, check=False)
        (output / name).write_text(run.stdout, encoding="utf-8")
        if name == "journey.log" and not re.search(r"HOME_WORKSHOP_TESTS: [1-9][0-9]* passed, 0 failed", run.stdout):
            raise RuntimeError("Input journey did not reach its successful completion marker")
        if run.returncode or re.search(r"(?m)^(?:SCRIPT ERROR|SHADER ERROR|ERROR):", run.stdout):
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
    ids = ["earlier-study", "authored-daylight"] if courtyard else ["working-daylight", "working-golden"] if workshop else [f"courtyard-{n}" for n in ("baseline", "daylight", "golden", "evening")]
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
    if courtyard:
        journey = json.loads((output/"home-workshop-journey.json").read_text())
        frames = batch["motion_frames"]
        observations = journey["motion_frames"]
        if not 40 <= len(frames) <= 240 or len(frames) != len(observations):
            raise RuntimeError("Incomplete native motion replay")
        if journey["source_content_sha256"] != identity["source_content_sha256"] or batch["journey_sha256"] != hashlib.sha256((output/"home-workshop-journey.json").read_bytes()).hexdigest():
            raise RuntimeError("Input journey binding mismatch")
        for i, (record, observed) in enumerate(zip(frames, observations)):
            path=output/"walk-frames"/f"{i:04d}.png"
            if hashlib.sha256(path.read_bytes()).hexdigest()!=record["image_sha256"]:
                raise RuntimeError("Motion image mismatch")
            if record["source_content_sha256"]!=identity["source_content_sha256"] or record["input_observation_index"]!=i:
                raise RuntimeError("Motion source mismatch")
            for key, source_key in (("tick","tick"),("camera_position","camera_position"),("camera_basis","camera_basis"),("fov","camera_fov")):
                if max_numeric_error(record[key],observed[source_key]) > (1e-5 if key.startswith("camera_") else 0): raise RuntimeError("Motion replay differs from input: "+key)
            if max_numeric_error(record["position"],observed["avatar_motion"]["position"])>1e-5: raise RuntimeError("Motion replay body differs from input")
            if i and record["tick"]<=frames[i-1]["tick"]: raise RuntimeError("Nonchronological motion")
        before,after=by_id["earlier-study"],by_id["authored-daylight"]
        for key in ("tick","position","camera_position","camera_basis","fov"):
            if before[key]!=after[key]: raise RuntimeError("A/B comparison changed "+key)
        for record in records:
            if record["source_content_sha256"]!=identity["source_content_sha256"]: raise RuntimeError("Still source mismatch")
        identity["qualified_motion_frames"]=len(frames)
        identity["camera_replay_tolerance"]=1e-5
        identity["max_camera_position_error"]=max(max_numeric_error(r["camera_position"],o["camera_position"]) for r,o in zip(frames,observations))
        # Preserve recorded simulation timing; this is not a hardware-FPS demonstration.
        lines=["ffconcat version 1.0"]
        for i,frame in enumerate(frames):
            duration=(frames[i+1]["tick"]-frame["tick"])/60 if i+1<len(frames) else .1
            lines.extend([f"file 'walk-frames/{i:04d}.png'",f"duration {duration:.9f}"])
        lines.append(f"file 'walk-frames/{len(frames)-1:04d}.png'")
        (output/"walk-timing.ffconcat").write_text("\n".join(lines)+"\n")
        encoder=shutil.which("ffmpeg")
        if encoder:
            command=[encoder,"-nostdin","-v","error","-n","-safe","1","-f","concat","-i",str(output/"walk-timing.ffconcat"),
                     "-c:v","libx264","-crf","19","-pix_fmt","yuv420p","-fps_mode","vfr","-movflags","+faststart",str(output/"courtyard-walk.mp4")]
            result=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=120)
            (output/"video-encode.log").write_text(result.stdout)
            if result.returncode: raise RuntimeError("Video encoding failed")
            identity["video_sha256"]=hashlib.sha256((output/"courtyard-walk.mp4").read_bytes()).hexdigest()
        else: identity["video_status"]="ffmpeg unavailable; PNG sequence retained"
    if hashes != {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}:
        raise RuntimeError("Source changed during capture; results retained but not qualified")
    identity["qualified_capture_count"] = len(records)
    identity["completed"] = True
    (output / "execution.json").write_text(json.dumps(identity, indent=2)+"\n")
    print(f"{'COURTYARD' if courtyard else 'HOME_WORKSHOP' if workshop else 'HOME_ART'}_CAPTURE: {expected} verified native captures in {output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
