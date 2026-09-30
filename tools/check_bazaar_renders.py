"""Check exact observation-backed captures, rather than a stale hard-coded frame count."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import struct
import zlib

REQUIRED = ('approach-animal', 'friends-walking', 'windup', 'checked', 'down',
            'ending-fight', 'ending-leave', 'friends-dialogue', 'compact')
FACES = ('mela-amused', 'jiva-wry', 'challenger', 'mela-resolute',
         'mela-relieved', 'jiva-relieved', 'mela-neutral-comparison', 'player-view')


def png(path: Path, size: tuple[int, int]) -> str:
    raw = path.read_bytes()
    if not raw.startswith(b'\x89PNG\r\n\x1a\n') or len(raw) < 33:
        raise ValueError(f'Invalid PNG: {path.name}')
    if struct.unpack_from('>II', raw, 16) != size:
        raise ValueError(f'Wrong image dimensions: {path.name}')
    offset, payload = 8, bytearray()
    while offset < len(raw):
        length = struct.unpack_from('>I', raw, offset)[0]
        kind = raw[offset+4:offset+8]
        end = offset+8+length
        if end+4 > len(raw) or zlib.crc32(raw[offset+4:end]) & 0xffffffff != struct.unpack_from('>I', raw, end)[0]:
            raise ValueError(f'Bad PNG chunk: {path.name}')
        if kind == b'IDAT':
            payload.extend(raw[offset+8:end])
        offset = end+4
    if not payload or not zlib.decompress(payload):
        raise ValueError(f'Empty PNG: {path.name}')
    return hashlib.sha256(raw).hexdigest()


def verify(user_dir: Path) -> dict:
    data = json.loads((user_dir/'bazaar-direction.json').read_text())
    manifest = json.loads((user_dir/'bazaar-direction-images/manifest.json').read_text())
    names = list(REQUIRED)
    if 'approach-line' in data['snapshots']:
        names.append('approach-line')
    names += [f'motion-{i:03d}' for i in range(len(data['motion']))]
    if data['failed'] or manifest['failed'] or manifest['captures'] != len(names):
        raise ValueError('Direction capture/observation mismatch')
    ticks = [row['tick'] for row in data['motion']]
    if len(ticks) <= 12 or manifest['motion_ticks'] != ticks or any(b-a != 4 for a, b in zip(ticks, ticks[1:])):
        raise ValueError('Motion playback must preserve actual four-tick spacing')
    directory = user_dir/'bazaar-direction-images'
    if {p.stem for p in directory.glob('*.png')} != set(names):
        raise ValueError('Missing, stale or unobserved direction image')
    files = {f'direction/{name}.png': png(directory/f'{name}.png',
             (800, 450) if name == 'compact' or name.startswith('motion-') else (1280, 720)) for name in names}
    facial = json.loads((user_dir/'bazaar-face-images/manifest.json').read_text())
    if facial['failed'] or {r['file'] for r in facial['captures']} != {f'{n}.png' for n in FACES}:
        raise ValueError('Incomplete face-performance captures')
    directory = user_dir/'bazaar-face-images'
    if {p.stem for p in directory.glob('*.png')} != set(FACES):
        raise ValueError('Missing or stale face image')
    files.update({f'faces/{name}.png': png(directory/f'{name}.png', (1280, 720)) for name in FACES})
    return {'schema': '1792.bazaar-render-audit.v1', 'status': 'passed',
            'direction_captures': len(names), 'face_captures': len(FACES), 'files_sha256': files,
            'scope': 'capture integrity and observation coverage, not artistic approval'}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--user-dir', required=True, type=Path)
    args = parser.parse_args()
    report = verify(args.user_dir)
    print(json.dumps(report, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
