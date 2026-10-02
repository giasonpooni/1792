"""Offline source identity checks; native route validation lives in Godot."""
from __future__ import annotations

import hashlib
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / "game/narrative/oral_memory/borrowed_rope.v1.json"
SOURCE_SHA256 = "db916de404cbd96cf46563b12e93744d0190b0c5f9f6958c2a3d540ce0c311d0"


class OralMemoryChecks(unittest.TestCase):
    def setUp(self) -> None:
        self.data = json.loads(PACK.read_text(encoding="utf-8"))

    def test_original_content_bytes_retained(self) -> None:
        self.assertEqual(hashlib.sha256(PACK.read_bytes()).hexdigest(), SOURCE_SHA256)

    def test_original_fiction_attribution_retained(self) -> None:
        self.assertEqual(self.data["historical_class"], "authored_fiction")
        self.assertIn("not an attested sakhi", self.data["authoring_note"])
        self.assertIn("no historical quotation", self.data["authoring_note"])

    def test_echo_keeps_reported_origin(self) -> None:
        tellings = self.data["tellings"]
        self.assertEqual(tellings["trader_account"]["root_id"], tellings["well_echo"]["root_id"])
        self.assertEqual(tellings["trader_account"]["lineage"], tellings["well_echo"]["lineage"][:-1])

    def test_recollection_keeps_reported_origin(self) -> None:
        tellings = self.data["tellings"]
        self.assertEqual(tellings["quartermaster_account"]["root_id"], tellings["quartermaster_reflection"]["root_id"])
        self.assertNotEqual(tellings["quartermaster_account"]["text"], tellings["quartermaster_reflection"]["text"])

    def test_conflict_has_no_verdict(self) -> None:
        self.assertNotEqual(self.data["tellings"]["quartermaster_account"]["claim"], self.data["tellings"]["trader_account"]["claim"])
        self.assertNotIn("canonical_truth", self.data)
        self.assertIn("Neither tells you", self.data["trace"]["text"])

    def test_current_hierarchy_and_clock(self) -> None:
        chapter = (ROOT / "game/narrative/oral_memory/memory_chapter.gd").read_text()
        state = (ROOT / "game/narrative/oral_memory/memory_state.gd").read_text()
        self.assertIn('extends "res://mounts/riding_training_chapter.gd"', chapter)
        self.assertIn('extends "res://mounts/riding_skill_state.gd"', state)
        self.assertIn("save_path=WorkshopState.WORKSHOP_SAVE", chapter)
        self.assertNotIn("func advance(", state)
        self.assertNotIn("KEY_F7", chapter)


if __name__ == "__main__":
    unittest.main(verbosity=2)
