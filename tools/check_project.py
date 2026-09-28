"""Offline structural checks only. This does NOT compile or execute GDScript."""
from __future__ import annotations

import hashlib
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"


class ProjectChecks(unittest.TestCase):
    def test_resource_references_resolve(self) -> None:
        for path in GAME.rglob("*"):
            if path.suffix not in {".gd", ".tscn", ".godot"}:
                continue
            for ref in re.findall(r'"res://([^"\n]+)"', path.read_text(encoding="utf-8")):
                with self.subTest(source=str(path.relative_to(ROOT)), ref=ref):
                    self.assertTrue((GAME / ref).is_file(), ref)

    def test_scene_resource_counts(self) -> None:
        for path in GAME.rglob("*.tscn"):
            text = path.read_text(encoding="utf-8")
            expected = 1 + len(re.findall(r'^\[(?:ext|sub)_resource\b', text, re.M))
            found = re.search(r"load_steps=(\d+)", text)
            self.assertIsNotNone(found, str(path))
            self.assertEqual(int(found[1]), expected, str(path))

    def test_scene_and_script_references(self) -> None:
        for path in GAME.rglob("*.tscn"):
            text = path.read_text(encoding="utf-8")
            for kind, header in [("ExtResource", "ext"), ("SubResource", "sub")]:
                ids = set(re.findall(rf'^\[{header}_resource[^\n]*id="([^"]+)"', text, re.M))
                used = set(re.findall(rf'{kind}\("([^"]+)"\)', text))
                self.assertTrue(used <= ids, f"{path}: {used - ids}")

    def test_scenario_references(self) -> None:
        state = json.loads((GAME / "data/command_sandbox.json").read_text())
        actors = state["actors"]
        places = [p["id"] for p in state["places"]]
        self.assertEqual(len(places), len(set(places)))
        self.assertIn(state["player"]["character_id"], actors)
        self.assertIn(state["order"]["issuer_id"], actors)
        self.assertIn(state["order"]["commander_id"], actors)
        for actor in actors.values():
            self.assertEqual(len(actor["position"]), 3)
            self.assertTrue(set(actor["known_places"]) <= set(places))
        self.assertEqual(state["player"]["position"], actors["ranjit_singh"]["position"])

    def test_historical_fixture_is_explicitly_separate(self) -> None:
        state = json.loads((GAME / "data/command_sandbox.json").read_text())
        self.assertEqual(state["historical_class"], "fictional_sandbox")
        self.assertEqual(state["scenario_id"], "lahore_command_sandbox")
        self.assertEqual(state["game_time"]["year"], 1801)
        self.assertEqual(state["schema_version"], "world-state.v1")
        self.assertEqual(state["command_schema_version"], "command-story.v1")
        self.assertEqual(state["reports"], [])
        self.assertEqual(state["order"]["status"], "available")

    def test_legacy_home_scene_is_retained_byte_for_byte(self) -> None:
        path = GAME / "world/home_territory.tscn"
        data = path.read_bytes()
        digest = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
        self.assertEqual(digest, "48d9a1ed2171a1259ea6dc79f5bb6ce5e741d1a4")

    def test_original_world_schema_is_not_replaced(self) -> None:
        data = (ROOT / "schemas/world_state.schema.json").read_bytes()
        digest = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
        self.assertEqual(digest, "5bb28190b77453920895b0595b260822d3f22b61")


    def test_mahan_historical_events_match_schema_shape(self) -> None:
        schema = json.loads((ROOT / "schemas/historical_event.schema.json").read_text())
        self.assertEqual(schema["$id"], "https://1792.game/schemas/historical_event.schema.json")
        self.assertEqual(schema["properties"]["schema_version"]["const"], "historical-event.v1")
        # world_state schema remains untouched (digest asserted elsewhere).
        root_events = sorted(p.name for p in (ROOT / "data/history").glob("*.json"))
        game_events = sorted(p.name for p in (GAME / "mahan/data").glob("*.json"))
        self.assertEqual(root_events, game_events)
        self.assertEqual(root_events, [
            "mahan_gujranwala_home_ground.json",
            "mahan_gujranwala_ridge_settlement_approach.json",
            "mahan_late_campaign_illness.json",
            "mahan_singh_death_fixed.json",
        ])
        loc_root = sorted(p.name for p in (ROOT / "data/history/locations").glob("*.json"))
        loc_game = sorted(p.name for p in (GAME / "mahan/data/locations").glob("*.json"))
        self.assertEqual(loc_root, loc_game)
        self.assertIn("gujranwala_settlement.json", loc_root)
        self.assertIn("gujranwala_fort_road.json", loc_root)
        self.assertIn("gujranwala_camp.json", loc_root)
        schema_loc = json.loads((ROOT / "schemas/historical_location.schema.json").read_text())
        self.assertEqual(schema_loc["properties"]["schema_version"]["const"], "historical-location.v1")
        for name in loc_root:
            root_bytes = (ROOT / "data/history/locations" / name).read_bytes()
            game_bytes = (GAME / "mahan/data/locations" / name).read_bytes()
            self.assertEqual(root_bytes, game_bytes, name)
            loc = json.loads(root_bytes)
            self.assertEqual(loc["schema_version"], "historical-location.v1")
            for key in schema_loc["required"]:
                self.assertIn(key, loc)
            self.assertEqual(loc["gameplay"].get("profile_scope", "mahan.v1"), "mahan.v1")
            blob = json.dumps(loc).lower()
            for token in ["raj_kaur", "phulkian", "sandhawalia"]:
                self.assertNotIn(token, blob)
        # Events may reference Gujranwala place ids
        illness = json.loads((ROOT / "data/history/mahan_late_campaign_illness.json").read_text())
        self.assertIn("gujranwala_fort_road", illness["location"].get("related_place_ids", []))
        home = json.loads((ROOT / "data/history/mahan_gujranwala_home_ground.json").read_text())
        self.assertEqual(home["location"]["place_id"], "gujranwala_settlement")
        approach = json.loads((ROOT / "data/history/mahan_gujranwala_ridge_settlement_approach.json").read_text())
        self.assertEqual(approach["location"]["place_id"], "gujranwala_fort_road")
        self.assertIn("gujranwala_settlement", approach["location"].get("related_place_ids", []))
        self.assertIn("no_alternate_history_win", approach["historical_outcome"].get("invariants", []))
        for name in root_events:
            root_bytes = (ROOT / "data/history" / name).read_bytes()
            game_bytes = (GAME / "mahan/data" / name).read_bytes()
            self.assertEqual(root_bytes, game_bytes, name)
            event = json.loads(root_bytes)
            self.assertEqual(event["schema_version"], "historical-event.v1")
            for key in schema["required"]:
                self.assertIn(key, event)
            self.assertFalse(event["knowledge"]["player_knowledge"])
            self.assertEqual(event["gameplay"].get("profile_scope", "mahan.v1"), "mahan.v1")
            kinds = {}
            for actor in event["actors"]:
                aid = actor["id"]
                kind = actor["kind"]
                self.assertIn(kind, ["person", "household", "faction"])
                if aid in kinds:
                    self.assertEqual(kinds[aid], kind)
                kinds[aid] = kind
            blob = json.dumps(event).lower()
            for token in ["raj_kaur", "phulkian", "sandhawalia"]:
                self.assertNotIn(token, blob)
            if event["historical_outcome"]["fixed"]:
                self.assertNotEqual(event["gameplay"]["intervention_scope"], "alter_outcome")

    def test_main_menu_keeps_both_entries(self) -> None:
        project = (GAME / "project.godot").read_text()
        menu = (GAME / "ui/main_menu.gd").read_text()
        self.assertIn('run/main_scene="res://ui/main_menu.tscn"', project)
        self.assertIn("res://world/home_territory.tscn", menu)
        self.assertIn("res://world/command_sandbox.tscn", menu)
        self.assertIn("res://world/mahan_camp.tscn", menu)
        self.assertIn("res://mahan/mahan_launch.gd", menu)


if __name__ == "__main__":
    unittest.main(verbosity=2)
