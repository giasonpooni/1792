"""Run the unchanged inherited gates, then funded-service native qualification."""
from __future__ import annotations
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
from run_checks import run

ROOT = Path(__file__).resolve().parents[1]

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', default=shutil.which('godot') or shutil.which('godot4'))
    args = parser.parse_args()
    if not args.godot:
        print('Godot is unavailable: runtime tests NOT RUN.', file=sys.stderr)
        return 2
    # Each inherited suite retains its own original timeout and completion gate.
    subprocess.run([sys.executable, 'tools/run_checks.py', '--godot', args.godot], cwd=ROOT, check=True)
    run([sys.executable, 'tools/check_commission_catalogue.py'], 'commission-catalogue')
    run([args.godot, '--headless', '--fixed-fps', '60', '--path', 'game', '--script', 'res://tests/test_commissions.gd'], 'commissions', 'COMMISSION_TESTS:')
    return 0

if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (RuntimeError, OSError, subprocess.SubprocessError) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1)
