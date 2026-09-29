"""Validate the deferred DLC contract, using the existing anthology and world.

Copyright (c) 2026 Cartesian Graphics. All rights reserved.
This offline authoring check neither enables a DLC nor admits historical truth.
"""
from __future__ import annotations

import datetime as dt
import hashlib
import json
from pathlib import Path
from typing import Any

from world_atlas import (ROOT, PLAN, WORLD, CatalogueError, load, require,
                         unique, validate_plan, validate_world)

MANIFEST = ROOT / "game/data/fall_of_empire.v1.json"
CLOSE = "formal_peace_1859_07_08"
RETAINED = {"lahore_succession", "naurangabad", "sobraon", "second_war",
            "last_resistance", "bar_1857"}
POLICY = {"both_sides": True, "historical_outcomes_fixed": True,
          "religious_figures_embodied": False, "site_interiors": False,
          "lineage_determines_allegiance": False, "hypotheses_merge_identity": False}


def text(value: Any) -> bool:
    return type(value) is str and bool(value.strip())


def refs(value: Any, registry: dict[str, Any], label: str, nonempty: bool = True) -> None:
    require(type(value) is list and all(type(v) is str for v in value), f"{label}: reference list")
    require((bool(value) or not nonempty) and len(value) == len(set(value))
            and all(v in registry for v in value), f"{label}: missing/duplicate reference")


def date(value: Any) -> dt.date:
    require(type(value) is str and len(value) == 10, "ISO day required")
    try:
        parsed = dt.date.fromisoformat(value)
    except (ValueError, TypeError) as exc:
        raise CatalogueError("Invalid calendar date") from exc
    require(parsed.isoformat() == value, "Canonical ISO day required")
    return parsed


def validate(data: dict[str, Any], plan: dict[str, Any], world: dict[str, Any]) -> None:
    validate_world(world)
    validate_plan(plan, world)
    require(type(data) is dict and data.get("schema") == "fall-of-empire.v1"
            and data.get("id") == "fall_of_empire", "DLC identity")
    require(data.get("story_window") == [1839, 1860] and data.get("closing_anchor") == CLOSE,
            "1839-1859 campaign closure")
    require(data.get("production") == {"status": "foundation_only", "gate": "finish_ranjit_full_life",
            "release_enabled": False, "playable_campaign_ready": False}, "Production gate cannot be promoted by a catalogue")
    require(data["production"].get("release_enabled") is False and data["production"].get("playable_campaign_ready") is False, "Boolean production flags")
    require(data.get("policy") == POLICY and all(data["policy"].get(k) is v for k, v in POLICY.items()), "Protected DLC boundaries")
    require(data.get("parent_plan") == "res://data/anthology.v1.json"
            and data.get("world_catalogue") == "res://data/historical_world.v1.json", "Existing substrate references")
    sources = unique(data.get("sources"), "source")
    for source in sources.values():
        require(all(text(source.get(k)) for k in ("title", "scope", "rights", "kind", "consulted")), "Source attribution/scope")
        require(type(source.get("url")) is str and (source["url"].startswith("https://")
                or source["id"] == "editorial"), "Source URL")
    events = unique(data.get("events"), "event")
    require(CLOSE in events, "Missing closing anchor")
    for event in events.values():
        require(text(event.get("summary")) and text(event.get("note")), "Event scope note")
        window = event.get("window")
        require(type(window) is list and len(window) == 2, "Event interval")
        start, end = map(date, window)
        require(dt.date(1839, 1, 1) <= start < end <= dt.date(1860, 1, 1), "Event outside DLC")
        require(event.get("precision") in {"day", "year", "campaign", "research_window"}, "Event precision")
        require(event.get("status") in {"supported_secondary", "research_window"}, "No new historical certification")
        refs(event.get("sources"), sources, "Event source")
        if event["status"] == "supported_secondary":
            require(any(s != "editorial" for s in event["sources"]), "Editorial text is not corroboration")
        if event["precision"] == "day":
            require(end - start == dt.timedelta(days=1), "A day event has half-open day bounds")
    require(events[CLOSE]["window"] == ["1859-07-08", "1859-07-09"], "Closing anchor changed")
    chapters = unique(data.get("chapters"), "chapter")
    require("settlement" in chapters and "divided_1857" in chapters, "Missing opposing/settlement chapters")
    parent = unique(plan["campaigns"], "parent campaign")
    places = unique(world["places"], "place")
    retained: set[str] = set()
    for chapter in chapters.values():
        require(text(chapter.get("title")) and chapter.get("status") == "planned_not_playable", "Chapter readiness")
        window = chapter.get("editorial_years")
        require(type(window) is list and len(window) == 2 and all(type(y) is int for y in window)
                and 1839 <= window[0] < window[1] <= 1860, "Editorial chapter interval")
        refs(chapter.get("event_ids"), events, "Chapter event")
        refs(chapter.get("requires"), chapters, "Chapter prerequisite", False)
        refs(chapter.get("place_refs"), places, "Shared place")
        refs(chapter.get("retained_modules"), parent, "Retained module", False)
        require(type(chapter.get("verbs")) is list and bool(chapter["verbs"])
                and all(text(v) for v in chapter["verbs"]), "Authored player verbs")
        retained.update(chapter["retained_modules"])
        for ref in chapter["event_ids"]:
            start, end = map(date, events[ref]["window"])
            require(start < dt.date(window[1], 1, 1) and end > dt.date(window[0], 1, 1), "Chapter/event do not overlap")
    require(RETAINED <= retained, "Earlier approved story modules must remain")
    visited: set[str] = set()
    visiting: set[str] = set()
    def visit(key: str) -> None:
        require(key not in visiting, "Campaign dependency cycle")
        if key in visited:
            return
        visiting.add(key)
        for dependency in chapters[key]["requires"]:
            visit(dependency)
        visiting.remove(key)
        visited.add(key)
    for key in chapters:
        visit(key)
    # Closure must depend transitively on every chapter; no bypass directly from Delhi.
    ancestry: set[str] = set()
    def ancestors(key: str) -> None:
        for dependency in chapters[key]["requires"]:
            if dependency not in ancestry:
                ancestry.add(dependency)
                ancestors(dependency)
    ancestors("settlement")
    require(ancestry == set(chapters) - {"settlement"}, "Settlement bypasses a retained chapter")
    cast = unique(data.get("cast"), "cast")
    blocked = set(plan["nonplayable"]) | set(plan["unembodied_context"]) | set(plan["review_associates"])
    for person in cast.values():
        require(text(person.get("label")) and text(person.get("note")) and person.get("chapter") in chapters, "Cast description")
        require(person.get("admission") in {"candidate", "research_only", "unembodied_context"}
                and person.get("presence") == "not_spawned", "No historical cast spawn from a plan")
        require(person["id"] not in blocked or person["admission"] != "candidate", "Unembodied/nonplayable person")
        refs(person.get("sources"), sources, "Cast source", False)
    require("ahmad_khan_kharal" in cast and "rai_ahmad_khan_kharal" not in cast, "Retain existing Kharal identity")
    require(cast.get("thakur_singh_sandhawalia", {}).get("admission") == "research_only", "Thakur 1857 participation not established")
    for claim in unique(data.get("claims"), "claim").values():
        require(claim.get("status") in {"reported_secondary", "research_lead", "attributed_claim", "hypothesis"}, "Claim is not canonical event")
        require(all(text(claim.get(k)) for k in ("subject", "summary", "constraint")), "Claim attribution/constraint")
        refs(claim.get("sources"), sources, "Claim source")
        if claim["status"] == "reported_secondary":
            require(any(s != "editorial" for s in claim["sources"]), "Reported claim needs an external source")
    for link in unique(data.get("deferred_links"), "deferred link").values():
        require(link.get("in_dlc") is False and type(link.get("year")) is int and link["year"] >= 1860,
                "Later anthology material is not in this DLC")
        require(text(link.get("note")), "Deferred attribution")
    ending = data.get("ending", {})
    require(ending.get("requires") == ["crown_transfer_1858_08_02", "crown_proclamation_1858_11_01", CLOSE,
            "road_inspected_open", "muster_accounted", "market_delivery", "household_accounted"], "Postwar closure conditions")
    require(ending.get("preserves") == ["missing_people", "displacement", "property_loss", "grievances", "opposed_memories"], "Settlement must not erase consequences")
    qualification = data.get("qualification", {})
    require(qualification.get("classification") == "synthetic:qualification"
            and qualification.get("id") == "fall-of-empire.settlement-fixture.v1"
            and qualification.get("roles") == ["company_courier", "rebel_courier", "resident"]
            and qualification.get("event_id") == "fixture.shared_road"
            and type(qualification.get("report_delay_ticks")) is int and qualification["report_delay_ticks"] == 120
            and type(qualification.get("receipt_limit")) is int and qualification["receipt_limit"] == 64,
            "Qualification identity/limits")


def main() -> int:
    data, plan, world = load(MANIFEST), load(PLAN), load(WORLD)
    validate(data, plan, world)
    print(json.dumps({"operation_id": "validate-fall-of-empire.v1", "manifest_sha256": hashlib.sha256(MANIFEST.read_bytes()).hexdigest(),
                      "chapters": len(data["chapters"]), "events": len(data["events"]), "cast_records": len(data["cast"]),
                      "historical_truth_certified": False, "playable_campaign_ready": False}, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (CatalogueError, OSError, ValueError, KeyError, TypeError) as error:
        raise SystemExit(f"DLC contract refused: {error}")
