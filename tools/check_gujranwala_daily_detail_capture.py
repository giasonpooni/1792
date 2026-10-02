"""Verify paired native detail captures using the existing strict PNG decoder."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import re

from check_gujranwala_beauty_capture import decode_png, SIZE


def check_capture(folder: Path) -> dict:
    manifest = json.loads((folder / "manifest.json").read_text())
    if (manifest.get("schema") != "1792.gujranwala-daily-detail-render.v1"
            or type(manifest.get("failures")) is not int or manifest["failures"] != 0
            or manifest.get("inspection_camera_only") is not True
            or manifest.get("historical_authentication") is not False
            or manifest.get("human_art_approval") is not False):
        raise ValueError("Failed or mislabeled daily-detail manifest")
    for key in ("source_commit", "source_tree"):
        if not isinstance(manifest.get(key), str) or not re.fullmatch(r"[0-9a-f]{40}", manifest[key]):
            raise ValueError("Missing source identity: " + key)
    for key in ("engine", "renderer", "device"):
        if not isinstance(manifest.get(key), str) or not manifest[key].strip():
            raise ValueError("Missing renderer execution metadata: " + key)
    records = manifest.get("captures")
    expected = {view + suffix for view in ("door", "market", "well")
                for suffix in ("-baseline", "-detail")}
    if not isinstance(records, list) or len(records) != 6:
        raise ValueError("Expected three baseline/detail pairs")
    by_id, pixels = {}, {}
    for record in records:
        if not isinstance(record, dict) or record.get("id") not in expected or record["id"] in by_id:
            raise ValueError("Unexpected or duplicate capture")
        name = record["id"]
        if (record.get("file") != name + ".png" or record.get("preset") != "daylight"
                or record.get("daily_detail_enabled") is not name.endswith("-detail")
                or record.get("comparison") != name.split("-")[0]
                or record.get("frozen_state") is not True
                or record.get("camera_kind") != "explicit-art-inspection"
                or record.get("gameplay_camera") is not False
                or record.get("pixel_format") != "rgba8"
                or (record.get("width"), record.get("height")) != SIZE):
            raise ValueError("Invalid comparison labels: " + name)
        if type(record.get("tick")) is not int or record["tick"] < 0:
            raise ValueError("Invalid frozen tick")
        if not isinstance(record.get("campaign_snapshot_sha256"), str) or not re.fullmatch(r"[0-9a-f]{64}", record["campaign_snapshot_sha256"]):
            raise ValueError("Missing frozen state identity")
        for key in ("camera_position", "target"):
            value = record.get(key)
            if not isinstance(value, list) or len(value) != 3 or any(type(n) not in (int, float) or not math.isfinite(n) for n in value):
                raise ValueError("Invalid camera vector")
        fov = record.get("fov")
        if type(fov) not in (int, float) or not math.isfinite(fov) or not 1 < fov < 179:
            raise ValueError("Invalid camera FOV")
        data = (folder / record["file"]).read_bytes()
        width, height, rgba = decode_png(data)
        if (hashlib.sha256(data).hexdigest() != record.get("sha256")
                or hashlib.sha256(rgba).hexdigest() != record.get("pixel_sha256")):
            raise ValueError("PNG byte/pixel identity mismatch: " + name)
        if rgba == rgba[:4] * (width * height):
            raise ValueError("Blank renderer output: " + name)
        by_id[name], pixels[name] = record, rgba
    if {p.name for p in folder.glob("*.png")} != {name + ".png" for name in expected}:
        raise ValueError("Missing or extra comparison PNG")
    differences = {}
    for view in ("door", "market", "well"):
        a, b = view + "-baseline", view + "-detail"
        for key in ("camera_position", "target", "fov", "tick", "campaign_snapshot_sha256", "preset"):
            if by_id[a][key] != by_id[b][key]:
                raise ValueError("Detail comparison changes " + key)
        changed = sum(pixels[a][i:i+4] != pixels[b][i:i+4]
                      for i in range(0, len(pixels[a]), 4))
        if changed < 100:
            raise ValueError("Detail is not visibly represented: " + view)
        differences[view] = changed
    if len({(r["tick"], r["campaign_snapshot_sha256"]) for r in records}) != 1:
        raise ValueError("Comparison captures changed campaign state")
    return {"schema": "1792.gujranwala-daily-detail-verification.v1", "status": "passed",
            "source_commit": manifest["source_commit"], "source_tree": manifest["source_tree"],
            "captures": 6, "changed_pixels": differences,
            "scope": "PNG integrity and paired pixel differences with renderer-reported frozen camera/state consistency; not historical authentication, human art approval or hardware performance"}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--capture-dir", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(check_capture(args.capture_dir), indent=2))


if __name__ == "__main__":
    main()
