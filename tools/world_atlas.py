"""Offline, fail-closed historical-world catalogue and acquisition planner.

Copyright (c) 2026 Cartesian Graphics. All rights reserved.
No networking, terrain download, fictional survey admission or live-game authority.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
WORLD = ROOT / "game/data/historical_world.v1.json"
PLAN = ROOT / "game/data/anthology.v1.json"


class CatalogueError(ValueError):
    """The data cannot support the claimed world representation."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise CatalogueError(message)


def number(value: Any) -> bool:
    return type(value) in (int, float) and math.isfinite(value)


def integer(value: Any, low: int, high: int) -> bool:
    return number(value) and value == math.floor(value) and low <= value <= high


def _pairs(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        require(key not in result, f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def loads(text: str) -> Any:
    def invalid(value: str) -> None:
        raise CatalogueError(f"Non-finite JSON value: {value}")
    return json.loads(text, object_pairs_hook=_pairs, parse_constant=invalid)


def load(path: Path) -> dict[str, Any]:
    return loads(path.read_text(encoding="utf-8"))


def rectangle(value: Any) -> bool:
    return (type(value) is list and len(value) == 4 and all(number(v) for v in value)
            and -180 <= value[0] < value[2] <= 180 and -90 <= value[1] < value[3] <= 90)


def interval(value: Any) -> bool:
    return (type(value) is dict and integer(value.get("from"), 1200, 1873)
            and integer(value.get("until"), 1201, 1874) and value["from"] < value["until"])


def unique(records: Any, label: str) -> dict[str, dict[str, Any]]:
    require(type(records) is list, f"{label} must be an array")
    result = {}
    for record in records:
        require(type(record) is dict and type(record.get("id")) is str
                and bool(record["id"]) and record["id"] not in result, f"Invalid/duplicate {label} identity")
        result[record["id"]] = record
    return result


def validate_world(data: dict[str, Any]) -> None:
    require(type(data) is dict and data.get("schema") == "historical-world.v1", "Unknown world schema")
    require(data.get("model_id") == "punjab-world-envelope.v1", "Unknown world model")
    require(type(data.get("metres_per_unit")) in (int, float) and data["metres_per_unit"] == 1,
            "Only one metre per game unit is admitted")
    require(data.get("coordinate_order") == ["longitude", "latitude", "ellipsoidal_height_m"], "Coordinate order")
    require(data.get("geodetic_datum") == "WGS84-ellipsoidal-metres", "Vertical datum cannot be inferred")
    require(interval(data.get("epoch")) and data["epoch"] == {"from": 1200, "until": 1874}, "Anthology epoch")
    require(rectangle(data.get("bounds")) and all(integer(x, -180, 180) for x in data["bounds"]), "Macro extent")
    require(data.get("macro_cell_degrees") == 1, "Only one-degree acquisition indexing is supported")
    require(data.get("active_protagonist") == "ranjit_singh", "Active protagonist changed")
    require(data.get("production_gate") == "childhood_to_lahore_prelude_then_full_life_before_dlc", "Production gate")
    policy = data.get("religious_policy", {})
    require(policy.get("figures_embodied") is False and policy.get("site_interiors") is False
            and policy.get("prayer") == "exterior_only", "Religious-site boundary")
    require(data.get("terrain_assets") == [], "Terrain needs a separate asset admission implementation")
    sources = unique(data.get("sources"), "source")
    for source in sources.values():
        for key in ("title", "scope", "rights"):
            require(type(source.get(key)) is str and bool(source[key]), f"Source {key} missing")
        require(type(source.get("url")) is str and (source["url"].startswith("https://") or source["id"] == "design"), "Source URL")
    theatres = unique(data.get("theatres"), "theatre")
    b = data["bounds"]
    for theatre in theatres.values():
        t = theatre.get("bounds")
        require(rectangle(t) and b[0] <= t[0] < t[2] <= b[2] and b[1] <= t[1] < t[3] <= b[3], "Theatre outside production extent")
        require(theatre.get("classification") == "authored_production_envelope_not_border", "Not a historical border")
    for place in unique(data.get("places"), "place").values():
        require(type(place.get("label")) is str and bool(place["label"]) and place.get("theatre") in theatres, "Place name/theatre")
        require(place.get("kind") in {"settlement", "fort", "crossing", "route_node", "battlefield", "sacred_site"}, "Place kind")
        require(place.get("placement_class") in {"A", "B", "C", "D"}, "Place evidence class")
        require(type(place.get("source_ids")) is list and bool(place["source_ids"])
                and all(s in sources for s in place["source_ids"]), "Unresolved place source")
        require(type(place.get("note")) is str and bool(place["note"]), "Evidence limitation required")
        anchor = place.get("anchor")
        require(anchor is None or (type(anchor) is list and len(anchor) == 2
                and all(number(x) for x in anchor) and b[0] <= anchor[0] < b[2] and b[1] <= anchor[1] < b[3]), "Invalid anchor")
        require(place.get("placement_class") != "D" or anchor is None, "Unlocated means no fabricated coordinates")
        require(place.get("placement_class") not in {"A", "B"} or any(s != "design" for s in place["source_ids"]), "Authored labels are not independent evidence")
        uncertainty = place.get("uncertainty_m")
        require(uncertainty is None or (number(uncertainty) and uncertainty >= 0), "Invalid uncertainty")
        require(place.get("geometry") is None, "Point registry cannot admit a historical footprint")
        require(type(place.get("periods")) is list, "Periods must be explicit")
        for span in place["periods"]:
            require(interval(span) and type(span.get("source_ids")) is list and bool(span["source_ids"])
                    and all(s in sources and s != "design" for s in span["source_ids"]), "Unverified historical presence")
        require(place.get("importance") == [], "Do not invent religious importance from fame")


def validate_plan(plan: dict[str, Any], world: dict[str, Any]) -> None:
    require(type(plan) is dict and plan.get("schema") == "anthology-plan.v1", "Unknown plan schema")
    require(plan.get("period") == [1200, 1874] and plan.get("anchor") == "ranjit_singh", "Plan anchor/period")
    require(plan.get("current_deliverable") == "ranjit_childhood" and plan.get("dlc_gate") == "finish_ranjit_full_life", "DLC production gate")
    require(set(plan.get("nonplayable", [])) == {"adina_beg", "sada_kaur"}, "Non-playable policy")
    blocked = set(plan["nonplayable"]) | set(plan.get("unembodied_context", [])) | set(plan.get("review_associates", []))
    require({"religious_figures", "baba_bir_singh", "bhai_maharaj_singh"} <= blocked, "Religious-figure boundary")
    theatres = set(unique(world["theatres"], "theatre"))
    active = []
    for entry in unique(plan.get("campaigns"), "campaign").values():
        window = entry.get("story_window")
        require(type(window) is list and len(window) == 2 and all(integer(y, 1200, 1874) for y in window)
                and window[0] < window[1], "Editorial story window")
        require(entry.get("chronology_status") == "editorial_research_window_not_lifespan", "A plan is not a verified biography")
        require(entry.get("theatre") in theatres, "Unknown campaign theatre")
        require(type(entry.get("protagonists")) is list and type(entry.get("display_names")) is list
                and len(entry["protagonists"]) == len(entry["display_names"]), "Protagonist roster")
        require(len(set(entry["protagonists"])) == len(entry["protagonists"])
                and not blocked.intersection(entry["protagonists"]), "Blocked/duplicate protagonist")
        require(entry.get("playable_content_ready") is False, "A catalogue cannot claim a finished campaign")
        require(entry.get("status") in {"active", "base_game_later", "dlc_research", "epilogue_plan"}, "Campaign status")
        require(type(entry.get("conflicts")) is str and bool(entry["conflicts"]), "Story/conflict scope required")
        if entry["status"] == "active": active.append(entry["id"])
    require(active == ["ranjit_childhood"], "Only the childhood campaign is active production")


def tile_plan(data: dict[str, Any], source_digest: str) -> dict[str, Any]:
    validate_world(data)
    require(len(source_digest) == 64 and all(c in "0123456789abcdef" for c in source_digest), "Invalid content digest")
    b = data["bounds"]
    cells = []
    for lat in range(int(b[1]), int(b[3])):
        for lon in range(int(b[0]), int(b[2])):
            cells.append({"id": f"ll1:{lon + 180}:{lat + 90}", "bounds": [lon, lat, lon + 1, lat + 1],
                          "status": "missing", "asset_id": None, "resolution_m": None,
                          "historical_surface_admitted": False})
    return {"schema": "world-acquisition-plan.v1", "model_id": data["model_id"],
            "operation_id": "enumerate-one-degree-coverage.v1", "source_sha256": source_digest,
            "coordinate_space": "angular-index-not-metric-terrain", "loaded_cells": 0, "cells": cells}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--world", type=Path, default=WORLD)
    parser.add_argument("--anthology", type=Path, default=PLAN)
    parser.add_argument("--plan-tiles", type=Path, help="Create a NEW missing-coverage plan; never downloads/promotes terrain")
    args = parser.parse_args()
    data, plan = load(args.world), load(args.anthology)
    validate_world(data); validate_plan(plan, data)
    digest = hashlib.sha256(args.world.read_bytes()).hexdigest()
    result = tile_plan(data, digest)
    if args.plan_tiles:
        # Exclusive creation protects an existing acquisition report from accidental replacement.
        with args.plan_tiles.open("x", encoding="utf-8", newline="\n") as output:
            json.dump(result, output, ensure_ascii=False, indent=2, allow_nan=False); output.write("\n")
    print(f"WORLD_CATALOGUE: {len(data['places'])} places, {len(data['theatres'])} theatres, "
          f"{len(plan['campaigns'])} editorial modules; {len(result['cells'])} cells missing, 0 loaded")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (CatalogueError, OSError, json.JSONDecodeError, TypeError, KeyError) as error:
        raise SystemExit(str(error))
