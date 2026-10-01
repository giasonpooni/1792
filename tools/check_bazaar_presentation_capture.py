"""Check completeness of actual recorded bazaar views; not artistic approval.

The optional ambient line is not forced to interrupt priority dialogue. Every
mandatory view and every recorded motion sample still requires its own PNG.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import struct


def check_capture(user_dir: Path) -> dict:
    source = json.loads((user_dir / 'bazaar-direction.json').read_text(encoding='utf-8'))
    folder = user_dir / 'bazaar-direction-images'
    manifest = json.loads((folder / 'manifest.json').read_text(encoding='utf-8'))
    mandatory = {'approach-animal', 'friends-walking', 'windup', 'checked', 'down',
                 'ending-fight', 'ending-leave', 'friends-dialogue', 'compact'}
    if not mandatory.difference({'compact'}) <= source['snapshots'].keys():
        raise ValueError('Missing mandatory recorded scene view')
    expected = mandatory | {f'motion-{i:03d}' for i in range(len(source['motion']))}
    if 'approach-line' in source['snapshots']:
        expected.add('approach-line')
    actual = {p.stem for p in folder.glob('*.png')}
    ticks = [item['tick'] for item in source['motion']]
    if (source['failed'] != 0 or manifest['failed'] != 0 or actual != expected
            or manifest['captures'] != len(expected)
            or manifest['motion_frames'] != len(ticks)
            or manifest['motion_ticks'] != ticks or len(ticks) < 13
            or any(b-a != 4 for a,b in zip(ticks,ticks[1:]))):
        raise ValueError('Incomplete, failed, extra or mistimed recorded presentation')
    for name in expected:
        data = (folder / (name + '.png')).read_bytes()
        expected_size = (800, 450) if name == 'compact' or name.startswith('motion-') else (1280, 720)
        if (len(data) < 33 or data[:8] != b'\x89PNG\r\n\x1a\n'
                or data[12:16] != b'IHDR' or struct.unpack('>II',data[16:24]) != expected_size):
            raise ValueError('Missing or incorrectly sized PNG: ' + name)
    listening = json.loads((user_dir / 'bazaar-listening-images/manifest.json').read_text())
    if listening['failed'] != 0 or len(listening['views']) != 3:
        raise ValueError('Missing close inspection views')
    for view in listening['views']:
        if view['source_snapshot'] not in source['snapshots']:
            raise ValueError('Close view invented an unrecorded state')
    if {p.name for p in (user_dir/'bazaar-listening-images').glob('*.png')} != {
            'mela.png','jiva.png','challenger.png','player-view.png'}:
        raise ValueError('Incomplete listening capture set')
    return {'schema':'1792.bazaar-capture-completeness.v1','status':'passed',
            'journey_views':len(expected),'close_inspection_views':3,'additional_player_view':1,
            'motion_frames':len(ticks),'optional_ambient_line_captured':'approach-line' in source['snapshots'],
            'scope':'record/image completeness, not pixel similarity, human playtesting or art approval'}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--user-dir',type=Path,required=True)
    args = parser.parse_args()
    print(json.dumps(check_capture(args.user_dir),indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
