"""Qualify the current-Home instructor and the systems it composes with."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "test-results" / "instructor"


def run(command: list[str], name: str, marker: str | None = None,
        render: bool = False, timeout: int = 180) -> None:
    runtime = RESULTS / name
    runtime.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(XDG_CONFIG_HOME=str(runtime / "config"),
               XDG_DATA_HOME=str(runtime / "data"), LIBGL_ALWAYS_SOFTWARE="1")
    if render:
        env.update(LIBGL_ALWAYS_SOFTWARE="1", INSTRUCTOR_CURRENT_RENDER="1")
    result = subprocess.run(command, cwd=ROOT, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            timeout=timeout, check=False)
    (RESULTS / f"{name}.log").write_text(result.stdout)
    print(result.stdout, flush=True)
    if result.returncode or re.search(r"(?m)^(?:SCRIPT ERROR|SHADER ERROR|ERROR):", result.stdout):
        raise RuntimeError(f"{name} failed; see test-results/instructor/{name}.log")
    if marker and not re.search(re.escape(marker) + r" [1-9][0-9]* passed, 0 failed", result.stdout):
        raise RuntimeError(f"{name} did not reach its completion marker")
    if render and not re.search(r"INSTRUCTOR_CURRENT_RENDER: [1-9][0-9]* captures", result.stdout):
        raise RuntimeError("Instructor journey did not produce native captures")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=shutil.which("godot") or shutil.which("godot4"))
    parser.add_argument("--native", action="store_true", help="Also run the physical journey and native small-screen captures")
    args = parser.parse_args()
    if not args.godot:
        print("Godot unavailable; instructor gameplay checks NOT RUN.", file=sys.stderr)
        return 2
    run([sys.executable, "tools/check_project.py"], "structure")
    run([sys.executable, "tools/playable_ledger.py", "--check"], "ledger")
    run([args.godot, "--headless", "--editor", "--path", "game", "--import"], "import")
    for script, marker in [
        ("test_instructor_economy", "INSTRUCTOR_ECONOMY_TESTS:"),
        ("test_instructor_story", "INSTRUCTOR_STORY_TESTS:"),
        ("test_home_workshop", "HOME_WORKSHOP_TESTS:"),
        ("test_oral_memory_current", "ORAL_MEMORY_CURRENT_TESTS:"),
        ("test_remounts", "REMOUNTS_TESTS:"),
        ("test_riding_training", "RIDING_TRAINING_TESTS:"),
    ]:
        run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", f"res://tests/{script}.gd"], script, marker)
    if args.native:
        if not shutil.which("xvfb-run"):
            raise RuntimeError("Native qualification requires xvfb-run")
        run(["xvfb-run", "-a", args.godot, "--fixed-fps", "60", "--path", "game",
             "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy",
             "--script", "res://tests/test_beginning_guidance.gd"],
            "beginning-guidance", "BEGINNING_GUIDANCE_TESTS:")
        run(["xvfb-run", "-a", args.godot, "--fixed-fps", "60", "--path", "game",
             "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy",
             "--script", "res://tests/test_instructor_current_integration.gd"],
            "current-journey", "INSTRUCTOR_CURRENT_TESTS:", render=True, timeout=360)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1)
