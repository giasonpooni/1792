"""Offline integrity check for the game-owned optional NET domain workload."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]

def main():
    path = ROOT / 'tools/net/water-round.profile.json'
    profile = json.loads(path.read_text())
    assert profile['project_id'] == '1792'
    assert profile['scenario']['source_class'] == 'authored_game'
    assert profile['scenario']['parameters']['positioning'] == 'validated_pose_fixture_not_traversal'
    assert profile['scenario']['clock']['duration_ticks'] == 70
    assert profile['scenario']['parameters']['observation_stride_physics_ticks'] == 6
    visited, pending = set(), [profile['entrypoint']]
    while pending:
        name = pending.pop()
        if name in visited:
            continue
        visited.add(name)
        target = ROOT / 'game' / name
        assert target.is_file() and not target.is_symlink()
        raw = target.read_bytes()
        assert profile['files'][name] == 'sha256:' + hashlib.sha256(raw).hexdigest(), name
        pending.extend(re.findall(r'res://([\w/.-]+\.gd)', raw.decode('utf-8')))
    assert visited == set(profile['files']), 'The explicit preload closure changed'
    assert len(visited) == 12
    assert len(profile['scenario']['checks']) == 9
    print('NET_GAME_PROFILE: 12 exact source files; 9 authored rules; 18 parameter cases; no engine started')

if __name__ == '__main__':
    main()
