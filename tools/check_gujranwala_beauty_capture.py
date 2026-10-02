"""Independently verify beauty PNGs and renderer-reported camera/state consistency.

This checks capture integrity, not historical authenticity or human art approval.
Only the renderer's 8-bit RGB/RGBA, non-interlaced PNG output is accepted; no
third-party decoder or image-generation dependency is required.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import struct
import zlib

SIZE = (1280, 720)
CAPTURES = {
    "courtyard-daylight": "daylight",
    "courtyard-golden": "golden_hour",
    "veranda-close": "golden_hour",
    "market-close": "golden_hour",
    "skyline-evening": "evening",
    "courtyard-evening": "evening",
}
LIGHTING = ("courtyard-daylight", "courtyard-golden", "courtyard-evening")


def decode_png(data: bytes) -> tuple[int, int, bytes]:
    """Decode bounded, CRC-checked engine PNG pixels into row-major RGBA8."""
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("Not a PNG")
    offset, chunks, payload = 8, [], bytearray()
    dimensions = None
    channels = 0
    while offset < len(data):
        if offset + 12 > len(data):
            raise ValueError("Truncated PNG chunk")
        length, kind = struct.unpack_from(">I4s", data, offset)
        end = offset + 12 + length
        if end > len(data):
            raise ValueError("Truncated PNG payload")
        block = data[offset + 8:end - 4]
        crc = struct.unpack_from(">I", data, end - 4)[0]
        if zlib.crc32(kind + block) & 0xffffffff != crc:
            raise ValueError("PNG chunk CRC mismatch")
        if kind == b"IHDR":
            if chunks or len(block) != 13:
                raise ValueError("Malformed PNG header")
            width, height, depth, color, compression, filtering, interlace = struct.unpack(">IIBBBBB", block)
            if ((width, height) != SIZE or depth != 8 or color not in (2, 6)
                    or compression != 0 or filtering != 0 or interlace != 0):
                raise ValueError("Expected 1280x720 non-interlaced RGB/RGBA8 PNG")
            dimensions = (width, height)
            channels = 3 if color == 2 else 4
        elif kind == b"IDAT":
            if dimensions is None or (b"IDAT" in chunks and chunks[-1] != b"IDAT"):
                raise ValueError("Malformed PNG image data")
            payload.extend(block)
        elif kind == b"IEND":
            if block or end != len(data) or not payload:
                raise ValueError("Malformed PNG end")
        elif kind[0] & 32 == 0:
            raise ValueError("Unsupported critical PNG chunk")
        chunks.append(kind)
        offset = end
    if not chunks or chunks[-1] != b"IEND" or dimensions is None:
        raise ValueError("Incomplete PNG")
    width, height = dimensions
    stride = width * channels
    expected = (stride + 1) * height
    decoder = zlib.decompressobj()
    raw = decoder.decompress(payload, expected + 1)
    if len(raw) != expected or not decoder.eof or decoder.unused_data or decoder.unconsumed_tail:
        raise ValueError("PNG decompressed length mismatch")
    result = bytearray()
    previous = bytearray(stride)
    for y in range(height):
        start = y * (stride + 1)
        method = raw[start]
        row = bytearray(raw[start + 1:start + 1 + stride])
        if method not in range(5):
            raise ValueError("Invalid PNG row filter")
        if method:
            for x in range(stride):
                left = row[x - channels] if x >= channels else 0
                up = previous[x]
                corner = previous[x - channels] if x >= channels else 0
                if method == 1:
                    predictor = left
                elif method == 2:
                    predictor = up
                elif method == 3:
                    predictor = (left + up) // 2
                else:
                    base = left + up - corner
                    a, b, c = abs(base - left), abs(base - up), abs(base - corner)
                    predictor = left if a <= b and a <= c else up if b <= c else corner
                row[x] = (row[x] + predictor) & 255
        if channels == 4:
            result.extend(row)
        else:
            for x in range(0, stride, 3):
                result.extend(row[x:x + 3])
                result.append(255)
        previous = row
    return width, height, bytes(result)


def check_capture(folder: Path) -> dict:
    manifest = json.loads((folder / "manifest.json").read_text(encoding="utf-8"))
    if (manifest.get("schema") != "1792.gujranwala-beauty-render.v2"
            or type(manifest.get("failures")) is not int or manifest["failures"] != 0
            or manifest.get("inspection_camera_only") is not True
            or manifest.get("historical_authentication") is not False
            or manifest.get("human_art_approval") is not False):
        raise ValueError("Failed or mislabeled inspection manifest")
    for key in ("engine", "renderer", "device"):
        if not isinstance(manifest.get(key), str) or not manifest[key].strip():
            raise ValueError("Missing renderer execution metadata: " + key)
    records = manifest.get("captures")
    if not isinstance(records, list) or len(records) != len(CAPTURES):
        raise ValueError("Expected six art-inspection captures")
    by_id = {}
    for record in records:
        if not isinstance(record, dict) or record.get("id") not in CAPTURES or record["id"] in by_id:
            raise ValueError("Unexpected or duplicate capture")
        name = record["id"]
        if (record.get("file") != name + ".png" or record.get("preset") != CAPTURES[name]
                or record.get("camera_kind") != "explicit-art-inspection"
                or record.get("gameplay_camera") is not False
                or record.get("frozen_state") is not True
                or record.get("pixel_format") != "rgba8"
                or (record.get("width"), record.get("height")) != SIZE):
            raise ValueError("Invalid capture labels or dimensions: " + name)
        if type(record.get("tick")) is not int or record["tick"] < 0:
            raise ValueError("Invalid frozen campaign tick")
        if not isinstance(record.get("campaign_snapshot_sha256"), str) or not re.fullmatch(r"[0-9a-f]{64}", record["campaign_snapshot_sha256"]):
            raise ValueError("Missing frozen campaign snapshot identity")
        for key in ("camera_position", "target"):
            vector = record.get(key)
            if not isinstance(vector, list) or len(vector) != 3 or any(type(v) not in (int, float) or not math.isfinite(v) for v in vector):
                raise ValueError("Invalid inspection camera vector")
        fov = record.get("fov")
        if type(fov) not in (int, float) or not math.isfinite(fov) or not 1 < fov < 179:
            raise ValueError("Invalid inspection FOV")
        data = (folder / record["file"]).read_bytes()
        width, height, pixels = decode_png(data)
        if (hashlib.sha256(data).hexdigest() != record.get("sha256")
                or hashlib.sha256(pixels).hexdigest() != record.get("pixel_sha256")
                or (width, height) != (record["width"], record["height"])):
            raise ValueError("PNG byte/pixel identity mismatch: " + name)
        # A one-color image is a blank renderer output, even when its hash is valid.
        if pixels == pixels[:4] * (width * height):
            raise ValueError("Blank inspection image: " + name)
        by_id[name] = record
    if {p.name for p in folder.glob("*.png")} != {name + ".png" for name in CAPTURES}:
        raise ValueError("Missing or extra inspection PNG")
    first = by_id[LIGHTING[0]]
    for name in LIGHTING[1:]:
        for key in ("camera_position", "target", "fov", "tick", "campaign_snapshot_sha256"):
            if by_id[name][key] != first[key]:
                raise ValueError("Lighting comparison changes " + key)
    if len({by_id[name]["pixel_sha256"] for name in LIGHTING}) != 3:
        raise ValueError("Same-camera lighting pixels did not all change")
    if len({(r["tick"], r["campaign_snapshot_sha256"]) for r in records}) != 1:
        raise ValueError("Inspection captures changed campaign state")
    return {"schema": "1792.gujranwala-beauty-verification.v1", "status": "passed",
            "captures": len(records), "same_camera_lighting_presets": 3,
            "scope": "PNG integrity/pixel differences and renderer-reported frozen same-camera metadata consistency; not human art approval or source authenticity"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--capture-dir", type=Path, required=True)
    args = parser.parse_args()
    try:
        print(json.dumps(check_capture(args.capture_dir), indent=2))
    except (OSError, ValueError, KeyError, TypeError, struct.error, zlib.error) as error:
        parser.exit(1, str(error) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
