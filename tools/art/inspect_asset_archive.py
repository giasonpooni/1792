"""Read-only ZIP/legacy .blend inventory. No extraction, Blender or code execution.

python tools/art/inspect_asset_archive.py input.zip --output /new/report.json
Only uncompressed, pre-5.0 BLENDER headers are inspected. This does not validate
meshes, render scenes, resolve libraries, approve licences or admit game content.
Format reference: https://archive.blender.org/www/development/architecture/blender-file-format/
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path, PurePosixPath
import re
import stat
import struct
from typing import Any
import zipfile
import zlib

MAX_ARCHIVE = 128 * 1024 * 1024
MAX_MEMBER = 128 * 1024 * 1024
MAX_TOTAL = 256 * 1024 * 1024
MAX_MEMBERS = 512
MAX_BLOCKS = 200_000
MAX_DNA_ITEMS = 65_536


def digest(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def checked_name(name: str) -> str:
    """Do not reinterpret hostile ZIP names as safe filesystem paths."""
    if (not name or len(name) > 1024 or '\\' in name or ':' in name
            or any(ord(c) < 32 or ord(c) == 127 for c in name)):
        raise ValueError('Unsupported archive member name')
    parts = name.rstrip('/').split('/')
    if name.startswith('/') or any(p in ('', '.', '..') for p in parts):
        raise ValueError('Unsafe archive member path')
    return name.rstrip('/')


def read_dna(raw: memoryview, endian: str, pointer_size: int) -> dict[str, Any]:
    """Limited SDNA layout parser; refuse implicit/ambiguous padding."""
    pos = 0

    def take(n: int) -> bytes:
        nonlocal pos
        if n < 0 or pos + n > len(raw):
            raise ValueError('Truncated DNA')
        result = bytes(raw[pos:pos+n]); pos += n
        return result

    def marker(expected: bytes) -> None:
        if take(len(expected)) != expected:
            raise ValueError('Invalid DNA marker')

    def number(fmt: str) -> int:
        return struct.unpack(endian + fmt, take(struct.calcsize(fmt)))[0]

    def count() -> int:
        n = number('I')
        if n > MAX_DNA_ITEMS:
            raise ValueError('DNA item budget exceeded')
        return n

    def strings(n: int) -> list[str]:
        result: list[str] = []
        for _ in range(n):
            value = bytearray()
            while True:
                byte = take(1)
                if byte == b'\0':
                    break
                value.extend(byte)
                if len(value) > 4096:
                    raise ValueError('DNA name budget exceeded')
            result.append(value.decode('ascii'))
        take((-pos) % 4)
        return result

    marker(b'SDNANAME'); names = strings(count())
    marker(b'TYPE'); types = strings(count())
    marker(b'TLEN'); lengths = [number('H') for _ in types]
    take((-pos) % 4); marker(b'STRC')
    layouts: dict[str, Any] = {}
    order: list[str] = []
    field_total = 0
    for _ in range(count()):
        type_index, fields = number('H'), number('H')
        field_total += fields
        if type_index >= len(types) or field_total > MAX_DNA_ITEMS:
            raise ValueError('Invalid DNA type or field budget')
        order.append(types[type_index])
        offset = 0; layout: dict[str, Any] = {}
        for _ in range(fields):
            ft, fn = number('H'), number('H')
            if ft >= len(types) or fn >= len(names):
                raise ValueError('Invalid DNA field index')
            spelling = names[fn]
            dimensions = [int(v) for v in re.findall(r'\[(\d+)\]', spelling)]
            size = (pointer_size if '*' in spelling else lengths[ft]) * math.prod(dimensions)
            if size > MAX_MEMBER:
                raise ValueError('DNA field size budget exceeded')
            key = spelling.lstrip('*').split('[')[0]
            layout[key] = (offset, size, types[ft], '*' in spelling)
            offset += size
        # These old files explicitly name their padding. Do not guess otherwise.
        if offset == lengths[type_index]:
            layouts[types[type_index]] = layout
    return {'layouts': layouts, 'order': order}


def inspect_blend(raw: bytes) -> dict[str, Any]:
    """Count stored blocks and inspect a few declared fields; never follow pointers."""
    if (len(raw) < 12 or raw[:7] != b'BLENDER' or raw[7:8] not in (b'_', b'-')
            or raw[8:9] not in (b'v', b'V') or not raw[9:12].isdigit()):
        raise ValueError('Unsupported .blend header (compressed/new formats not handled)')
    version = int(raw[9:12])
    if not 250 <= version < 500:
        raise ValueError('Unsupported legacy .blend version')
    pointer_size = 8 if raw[7:8] == b'-' else 4
    endian = '<' if raw[8:9] == b'v' else '>'
    header = struct.Struct(endian + '4sI' + ('Q' if pointer_size == 8 else 'I') + 'II')
    pos = 12; counts: Counter[str] = Counter(); targets: list[tuple[str, int, memoryview]] = []
    dna = None; ended = False
    for _ in range(MAX_BLOCKS):
        if pos + header.size > len(raw):
            raise ValueError('Truncated .blend block header or missing ENDB')
        code, size, _address, schema_index, _instances = header.unpack_from(raw, pos)
        pos += header.size
        if size > len(raw) - pos:
            raise ValueError('Truncated .blend block payload')
        content = memoryview(raw)[pos:pos+size]; pos += size
        label = code.rstrip(b'\0').decode('ascii')
        counts[label] += 1
        if label == 'DNA1':
            if dna is not None:
                raise ValueError('Duplicate DNA1')
            dna = content
        if label in ('LI', 'IM', 'ME', 'TX'):
            if _instances != 1:
                raise ValueError('Expected one ID datablock per target block')
            targets.append((label, schema_index, content))
        if label == 'ENDB':
            if size != 0 or pos != len(raw):
                raise ValueError('Invalid ENDB or trailing bytes')
            ended = True
            break
    if not ended or dna is None:
        raise ValueError('Incomplete .blend or block budget exceeded')
    parsed = read_dna(dna, endian, pointer_size)
    layouts, order = parsed['layouts'], parsed['order']

    def field(content: memoryview, kind: str, name: str) -> bytes | None:
        spec = layouts.get(kind, {}).get(name)
        if spec is None:
            return None
        start, size, _type, _pointer = spec
        if start + size > len(content):
            raise ValueError('Declared field outside stored block')
        return bytes(content[start:start+size])

    def basename(value: bytes | None) -> str | None:
        if value is None:
            return None
        decoded = value.split(b'\0', 1)[0].decode('utf-8', errors='replace')
        return PurePosixPath(decoded.replace('\\', '/')).name or None

    libraries = []; images = []; meshes = []
    for label, schema_index, content in targets:
        expected = {'LI': 'Library', 'IM': 'Image', 'ME': 'Mesh', 'TX': 'Text'}[label]
        if schema_index >= len(order) or order[schema_index] != expected:
            raise ValueError('Target block disagrees with its SDNA type')
        if label == 'LI':
            libraries.append({'basename': basename(field(content, 'Library', 'name')),
                              'resolved': False})
        elif label == 'IM':
            packed = field(content, 'Image', 'packedfile')
            images.append({'basename': basename(field(content, 'Image', 'name')),
                           'legacy_packedfile_pointer_nonzero':
                           any(packed) if packed is not None else None})
        elif label == 'ME':
            item = {}
            for name in ('totvert', 'totedge', 'totface', 'totpoly'):
                value = field(content, 'Mesh', name)
                item[name] = struct.unpack(endian+'i', value)[0] if value is not None and len(value) == 4 else None
                if item[name] is not None and item[name] < 0:
                    raise ValueError('Negative saved mesh count')
            meshes.append(item)
    return {
        'inspection': 'static_binary_metadata_only', 'saved_version_header': f'{version//100}.{version%100:02}',
        'pointer_bytes': pointer_size, 'endianness': 'little' if endian == '<' else 'big',
        'stored_blocks_by_code': dict(sorted(counts.items())),
        'stored_datablocks': {'objects': counts['OB'], 'meshes': counts['ME'], 'materials': counts['MA'],
                              'images': counts['IM'], 'libraries': counts['LI'], 'particle_settings': counts['PA'],
                              'text_blocks': counts['TX'], 'actions': counts['AC']},
        'libraries': libraries, 'images': images,
        'mesh_totals_saved_not_evaluated': {
            name: sum(m[name] for m in meshes) if meshes and all(m[name] is not None for m in meshes) else None
            for name in ('totvert', 'totedge', 'totface', 'totpoly')},
        'limits': 'Counts include stored/orphan datablocks, not evaluated visible objects or render triangles. '
                  'Packed pointers do not certify complete textures. Library paths are basename-only; no files resolved. '
                  'No Blender import, drivers, topology, rig, materials, measurements or render qualified.'
    }


def inspect(path: Path) -> dict[str, Any]:
    if path.is_symlink() or not path.is_file() or path.stat().st_size > MAX_ARCHIVE:
        raise ValueError('Input must be a regular ZIP within the archive budget')
    raw_archive = path.read_bytes()
    if len(raw_archive) > MAX_ARCHIVE:
        raise ValueError('Archive grew past its budget')
    import io
    records = []
    with zipfile.ZipFile(io.BytesIO(raw_archive)) as archive:
        infos = archive.infolist()
        if not 0 < len(infos) <= MAX_MEMBERS or sum(i.file_size for i in infos) > MAX_TOTAL:
            raise ValueError('Archive member/expansion budget exceeded')
        seen = set()
        for info in infos:
            name = checked_name(info.filename)
            key = name.casefold()
            if key in seen:
                raise ValueError('Duplicate/case-colliding archive name')
            seen.add(key)
            if info.is_dir() and info.file_size != 0:
                raise ValueError('Directory member carries unexpected payload')
            mode = (info.external_attr >> 16) & 0xffff
            if (stat.S_IFMT(mode) not in (0, stat.S_IFREG, stat.S_IFDIR)
                    or info.flag_bits & 1 or info.file_size > MAX_MEMBER
                    or info.compress_type not in (zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED)):
                raise ValueError('Unsupported link, special, encrypted, compressed or oversized member')
        for info in infos:
            if info.is_dir():
                continue
            # Full bounded read also checks each member's CRC. Nothing extracted.
            with archive.open(info) as stream:
                raw = stream.read(MAX_MEMBER + 1)
            if len(raw) != info.file_size or len(raw) > MAX_MEMBER:
                raise ValueError('Inconsistent member length')
            record = {'name': info.filename, 'bytes': len(raw), 'sha256': digest(raw), 'crc_checked': True}
            if Path(info.filename).suffix.lower() == '.blend':
                record['blend'] = inspect_blend(raw)
            records.append(record)
    return {'schema': '1792.asset-archive-inspection.v1', 'archive_name': path.name,
            'archive_bytes': len(raw_archive), 'archive_sha256': digest(raw_archive),
            'expanded_bytes': sum(i.file_size for i in infos), 'members': records,
            'source_files_executed': False, 'files_extracted': False, 'runtime_admission': False,
            'licence_decision': 'not_inferred_by_inspector'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        report = inspect(args.archive)
        with args.output.open('x', encoding='utf-8') as target:
            json.dump(report, target, indent=2, allow_nan=False); target.write('\n')
    except (ValueError, OSError, UnicodeError, zipfile.BadZipFile, struct.error, zlib.error) as exc:
        parser.exit(2, f'Inspection refused: {exc}\n')
