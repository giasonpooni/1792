"""Acquire two explicitly selected CC0 material samples for an art study.

This is not terrain acquisition or historical evidence. Network use is explicit;
no assets are fetched at game startup. Output is new-only. Sources are bounded,
recorded, verified as images, and resized for the prototype texture budget.
"""
from __future__ import annotations
import argparse
from datetime import datetime, timezone
import hashlib
import io
import json
from pathlib import Path
import urllib.request
from PIL import Image

ASSETS = {
    'dirt': ('Charlotte Baglioni', 'https://polyhaven.com/a/dirt'),
    'plastered_wall': ('Amal Kumar', 'https://polyhaven.com/a/plastered_wall'),
}
MAPS = ('diff', 'disp', 'rough')
MAX_BYTES = 32 * 1024 * 1024


def acquire(output: Path) -> None:
    output.mkdir(parents=False, exist_ok=False)
    records = []
    for asset, (author, source) in ASSETS.items():
        for kind in MAPS:
            url = f'https://dl.polyhaven.org/file/ph-assets/Textures/jpg/4k/{asset}/{asset}_{kind}_4k.jpg'
            request = urllib.request.Request(url, headers={'User-Agent': '1792-material-study/1.0'})
            with urllib.request.urlopen(request, timeout=60) as response:
                raw = response.read(MAX_BYTES + 1)
            if not 0 < len(raw) <= MAX_BYTES:
                raise ValueError('Source outside texture size budget')
            with Image.open(io.BytesIO(raw)) as image:
                if image.size != (4096, 4096) or image.format != 'JPEG':
                    raise ValueError('Unexpected source image dimensions or format')
                image.load()
                converted = image.convert('RGB' if kind == 'diff' else 'L')
                converted = converted.resize((1024, 1024), Image.Resampling.LANCZOS)
                filename = f'{asset}_{kind}_1k.png'
                converted.save(output / filename)
            data = (output / filename).read_bytes()
            records.append({'file': filename, 'sha256': hashlib.sha256(data).hexdigest(),
                            'upstream_sha256': hashlib.sha256(raw).hexdigest(), 'upstream_bytes': len(raw),
                            'url': url, 'asset_page': source, 'author': author, 'license': 'CC0-1.0',
                            'license_url': 'https://polyhaven.com/license', 'source_width_m': 2,
                            'adaptation': '4096 JPEG to 1024 PNG; diffuse RGB, height/roughness grayscale',
                            'historical_evidence': False})
    (output/'sources.json').write_text(json.dumps({'schema': '1792.surface-study.v1',
        'acquired_utc': datetime.now(timezone.utc).isoformat(), 'files': records,
        'license': 'CC0-1.0', 'historical_evidence': False}, indent=2)+'\n')

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    acquire(parser.parse_args().output)
