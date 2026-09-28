"""Run structural checks and the actual Godot suite, failing on engine errors."""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run(command: list[str], name: str, marker: str | None = None) -> None:
    result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=120, check=False)
    logs = ROOT / "test-results"
    logs.mkdir(exist_ok=True)
    (logs / f"{name}.log").write_text(result.stdout, encoding="utf-8")
    print(result.stdout)
    if result.returncode or re.search(r"(?m)^(?:SCRIPT ERROR|ERROR):", result.stdout):
        raise RuntimeError(f"{name} failed (exit {result.returncode}); see test-results/{name}.log")
    if marker and not re.search(re.escape(marker) + r" (?:[1-9][0-9]* passed, 0 failed|[1-9][0-9]* assertions; 0 failures)", result.stdout):
        raise RuntimeError(f"{name} did not reach its completion marker")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default=shutil.which("godot") or shutil.which("godot4"))
    args = parser.parse_args()
    run([sys.executable, "tools/check_project.py"], "structure")
    if not args.godot:
        print("Godot is unavailable: runtime tests NOT RUN.", file=sys.stderr)
        return 2
    run([args.godot, "--headless", "--path", "game", "--editor", "--import"], "import")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_command_story.gd"],
        "command-story", "COMMAND_STORY_TESTS:")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_house_reporting.gd"],
        "houses", "HOUSE_CONFLICT_TESTS:")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_riding.gd"],
        "riding", "RIDING_TESTS:")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_companions.gd"],
        "companions", "COMPANION_TESTS:")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_character_names.gd"],
        "character-names", "CHARACTER_NAMES_TESTS:")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_childhood.gd"],
        "childhood", "CHILDHOOD_TESTS:")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_aftermath.gd"],
        "aftermath", "AFTERMATH_TESTS:")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_fixed_interlude.gd"],
        "fixed-interlude", "FIXED_INTERLUDE_TESTS:")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_gujranwala.gd"],
        "gujranwala", "GUJRANWALA_TESTS:")
    run([sys.executable, "tools/check_reconstruction.py"], "reconstruction-contracts")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_reconstruction.gd"],
        "reconstruction", "RECONSTRUCTION_TESTS:")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_political_exposure.gd"],
        "political-exposure", "POLITICAL_EXPOSURE:")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_water_round.gd"],
        "water-round", "WATER_ROUND_TESTS:")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1)
