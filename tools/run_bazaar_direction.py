"""Run inherited game suites and the direct bazaar craft checks."""
from __future__ import annotations
import argparse
from pathlib import Path
import shutil
import subprocess
import sys
from run_checks import run

ROOT = Path(__file__).resolve().parents[1]

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=shutil.which('godot') or shutil.which('godot4'))
    args = parser.parse_args()
    if not args.godot:
        print('Godot unavailable; gameplay checks NOT RUN.', file=sys.stderr)
        return 2
    subprocess.run([sys.executable, '-u', 'tools/run_checks.py', '--godot', args.godot], cwd=ROOT, check=True)
    for script, name, marker in [
        ('res://tests/test_bazaar_direction.gd','bazaar-direction','BAZAAR_DIRECTION_TESTS:'),
        ('res://tests/test_bazaar_market_craft.gd','bazaar-market-craft','BAZAAR_MARKET_CRAFT_TESTS:'),
        ('res://tests/test_bazaar_inhabited_approach.gd','bazaar-inhabited-approach','BAZAAR_INHABITED_APPROACH_TESTS:'),
        ('res://tests/test_bazaar_listening.gd','bazaar-listening','BAZAAR_LISTENING_TESTS:'),
        ('res://tests/test_hand_worked_lives.gd','hand-worked-lives','HAND_WORKED_LIVES_TESTS:'),
    ]:
        run([args.godot,'--headless','--fixed-fps','60','--path','game','--script',script],name,marker)
    return 0

if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1)
