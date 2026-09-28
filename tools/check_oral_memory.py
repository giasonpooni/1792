"""Offline content/integration checks; not a substitute for executing Godot."""
from __future__ import annotations
import json
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / "game/narrative/oral_memory/borrowed_rope.v1.json"

class OralMemoryChecks(unittest.TestCase):
    def setUp(self) -> None:
        self.data = json.loads(PACK.read_text(encoding="utf-8"))

    def test_fiction_not_historical_evidence(self) -> None:
        self.assertEqual(self.data["historical_class"], "authored_fiction")
        self.assertIn("not an attested sakhi", self.data["authoring_note"])
        self.assertIn("no historical quotation", self.data["authoring_note"])

    def test_content_identity(self) -> None:
        self.assertEqual(self.data["schema"], "1792.oral-memory-content.v1")
        self.assertEqual(self.data["episode_id"], "borrowed_rope")
        self.assertEqual(set(self.data), {"schema", "episode_id", "title", "historical_class", "authoring_note", "tellings", "trace"})

    def test_telling_shapes(self) -> None:
        fields = {"speaker_id", "speaker", "site", "channel", "root_id", "lineage", "claim", "text"}
        for telling in self.data["tellings"].values():
            self.assertEqual(set(telling), fields)
            self.assertTrue(telling["lineage"])
            self.assertLessEqual(len(telling["lineage"]), 8)
            self.assertIn(telling["site"], {"quartermaster", "market", "listener"})
            self.assertNotEqual(telling["speaker_id"], "shah_muhammad")

    def test_echo_retains_origin(self) -> None:
        t = self.data["tellings"]
        self.assertEqual(t["trader_account"]["root_id"], t["well_echo"]["root_id"])
        self.assertEqual(t["trader_account"]["lineage"], t["well_echo"]["lineage"][:-1])

    def test_reflection_is_not_new_independent_source(self) -> None:
        t = self.data["tellings"]
        self.assertEqual(t["quartermaster_account"]["root_id"], t["quartermaster_reflection"]["root_id"])
        self.assertNotEqual(t["quartermaster_account"]["text"], t["quartermaster_reflection"]["text"])

    def test_conflict_has_no_canonical_verdict(self) -> None:
        t = self.data["tellings"]
        self.assertNotEqual(t["quartermaster_account"]["claim"], t["trader_account"]["claim"])
        self.assertNotIn("canonical_truth", self.data)
        self.assertIn("Neither tells you", self.data["trace"]["text"])

    def test_active_launch_extends_researched_world(self) -> None:
        launch = (ROOT / "game/childhood/home_launch.gd").read_text()
        chapter = (ROOT / "game/narrative/oral_memory/memory_chapter.gd").read_text()
        state = (ROOT / "game/narrative/oral_memory/memory_state.gd").read_text()
        self.assertIn('res://narrative/oral_memory/memory_chapter.gd', launch)
        self.assertIn('extends "res://territory/researched_chapter.gd"', chapter)
        self.assertIn('extends "res://territory/gujranwala_state.gd"', state)
        self.assertNotIn('func advance(', state)

    def test_native_and_render_fixtures_are_wired(self) -> None:
        workflow = (ROOT / ".github/workflows/oral-memory.yml").read_text()
        self.assertIn("test_oral_memory.gd", workflow)
        self.assertIn("render_oral_memory.gd", workflow)
        self.assertIn("tools/run_checks.py", workflow)
        self.assertIn("02ec53d1cc7dbb9cc6355393c61b9ab43d1244751a124f10248a4802830788cd", workflow)

if __name__ == "__main__":
    unittest.main(verbosity=2)
