"""Execute one physics command stream at three render schedules and compare observations."""
from __future__ import annotations
import hashlib
import argparse
import json
import re
import subprocess
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    args = parser.parse_args()
    output = ROOT / 'test-results'
    output.mkdir(exist_ok=True)
    records: list[dict] = []
    commands: list[list[str]] = []
    for rate in (30, 60, 144):
        command = [args.godot, '--headless', '--fixed-fps', str(rate), '--path', 'game',
                   '--script', 'res://tests/test_locomotion_rate.gd']
        commands.append(command)
        result = subprocess.run(command, cwd=ROOT, env={**os.environ, 'LOCOMOTION_RATE_LABEL': str(rate)},
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                text=True, timeout=60, check=False)
        (output / f'locomotion-rate-{rate}.log').write_text(result.stdout, encoding='utf-8')
        if result.returncode or re.search(r'(?m)^(SCRIPT ERROR|ERROR):', result.stdout):
            raise RuntimeError(f'Native rate execution failed: {rate}\n{result.stdout}')
        match = re.search(r'(?m)^LOCOMOTION_RATE_FILE: (.+)$', result.stdout)
        if not match:
            raise RuntimeError(f'Missing rate artifact at {rate}')
        text = Path(match.group(1).strip()).read_text(encoding='utf-8')
        record = json.loads(text)
        if record['physics_hz'] != 60 or record['render_schedule_fps'] != rate:
            raise RuntimeError('Rate observation identity mismatch')
        if [row['tick'] for row in record['trace']] != list(range(1, 181)):
            raise RuntimeError('Incomplete physics trace')
        (output / f'locomotion-rate-{rate}.json').write_text(text, encoding='utf-8')
        records.append(record)
    if not all(r['trace'] == records[0]['trace'] and r['motor_digest'] == records[0]['motor_digest']
               and r['trace_digest'] == records[0]['trace_digest'] and r['geometry_digest'] == records[0]['geometry_digest'] for r in records):
        raise RuntimeError('Render scheduling changed this fixture\'s physics trajectory')
    verification = {'verification_id': 'locomotion-render-schedule-comparison.v1',
                    'operation_id': records[0]['operation_id'], 'physics_hz': 60,
                    'schedules': [30, 60, 144], 'ticks_per_execution': 180,
                    'identical_observations': True, 'trace_digest': records[0]['trace_digest'],
                    'motor_digest': records[0]['motor_digest'], 'geometry_digest': records[0]['geometry_digest'],
                    'observation_digest': hashlib.sha256(json.dumps(records[0]['trace'], sort_keys=True, separators=(',', ':'), allow_nan=False).encode()).hexdigest(), 'commands': commands,
                    'scope': 'Same engine/platform/scene/inputs; not cross-platform determinism or GPU performance.'}
    (output / 'locomotion-rate-verification.json').write_text(json.dumps(verification, indent=2) + '\n', encoding='utf-8')
    print('LOCOMOTION_RATE_MATRIX: 3 schedules; identical 180-tick traces')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
