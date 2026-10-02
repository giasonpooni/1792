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
    if result.returncode or re.search(r"(?m)^(?:SCRIPT ERROR|SHADER ERROR|ERROR):", result.stdout):
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
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_gate_passage_direction.gd"],
        "gate-passage-direction", "GATE_PASSAGE_DIRECTION_TESTS:")
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
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_sukerchakia_service.gd"],
        "sukerchakia-service", "SUKERCHAKIA_SERVICE_TESTS:")
    run([sys.executable, "tools/check_youth.py"], "youth-catalogue")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_youth_brawl.gd"],
        "youth-brawl", "YOUTH_BRAWL_TESTS:")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_locomotion.gd"],
        "locomotion", "LOCOMOTION_TESTS:")
    run([sys.executable, "tools/check_locomotion_rates.py", "--godot", args.godot], "locomotion-rates")
    run([sys.executable, "tools/check_world_atlas.py"], "world-atlas-contracts")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_world_atlas.gd"],
        "world-atlas", "WORLD_ATLAS_TESTS:")
    run([sys.executable, "tools/check_home_art.py"], "home-art-contracts")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_home_art.gd"],
        "home-art", "HOME_ART_TESTS:")
    run([sys.executable, "tools/check_home_workshop.py"], "home-workshop-contracts")
    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_home_workshop.gd"],
        "home-workshop", "HOME_WORKSHOP_TESTS:")
    run([sys.executable,"tools/check_courtyard.py"],"courtyard-contracts")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_courtyard.gd"],"courtyard","COURTYARD_TESTS:")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_gujranwala_beauty.gd"],"gujranwala-beauty","GUJRANWALA_BEAUTY_TESTS:")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_gujranwala_depth.gd"],"gujranwala-depth","GUJRANWALA_DEPTH_TESTS:")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_gujranwala_microdetail.gd"],"gujranwala-microdetail","GUJRANWALA_MICRODETAIL_TESTS:")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_vessel_profile.gd"],"vessel-profile","VESSEL_PROFILE_TESTS:")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_gujranwala_material_fidelity.gd"],"gujranwala-material-fidelity","GUJRANWALA_MATERIAL_FIDELITY_TESTS:")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_horsecraft_state.gd"],"horsecraft-state","HORSECRAFT_STATE_TESTS:")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_horsecraft_study.gd"],"horsecraft-scene","HORSECRAFT_SCENE_TESTS:")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_horse_visual.gd"],"horse-visual","HORSE_VISUAL_TESTS:")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_horsecraft_handling.gd"],"horsecraft-handling","HORSECRAFT_HANDLING_TESTS:")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_riding_skills.gd"],"riding-skills","RIDING_SKILLS_TESTS:")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_riding_training.gd"],"riding-training","RIDING_TRAINING_TESTS:")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_charat_campaign_intro.gd"],"charat-campaign-intro","CHARAT_CAMPAIGN_INTRO_TESTS:")
    run([args.godot,"--headless","--fixed-fps","60","--path","game","--script","res://tests/test_childhood_intro_session.gd"],"childhood-intro-session","CHILDHOOD_INTRO_SESSION_TESTS:")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1)
