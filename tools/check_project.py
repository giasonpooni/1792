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
