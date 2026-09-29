"""Offline boundaries for the additive Home visual study, not artistic certification."""
from __future__ import annotations
import hashlib
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def unique_pairs(pairs: list[tuple[str, object]]) -> dict:
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


class ArtContracts(unittest.TestCase):
    def test_manifest(self):
        data = json.loads((ROOT / "game/data/home_art.v1.json").read_text(), object_pairs_hook=unique_pairs)
        self.assertFalse(data["georeferenced"])
        self.assertEqual(data["classification"], "original-authoring-study")
        self.assertEqual(set(data["presets"]), {"daylight", "golden_hour", "evening"})

    def test_duplicate_keys_refuse(self):
        with self.assertRaises(ValueError):
            json.loads('{"seed":1,"seed":2}', object_pairs_hook=unique_pairs)

    def test_original_home_scene_retained(self):
        self.assertEqual(hashlib.sha256((ROOT / "game/world/home_territory.tscn").read_bytes()).hexdigest(),
                         "383ef8004ca41c84c084801f2ddb4a57f1730f66206f58cf32be7c3e1f2fb5c0")

    def test_no_second_simulation(self):
        text = (ROOT / "game/presentation/home_art.gd").read_text()
        for forbidden in (".model.restore", ".model._state", "StaticBody3D.new", "CollisionShape3D.new", "HTTPRequest", "Timer.new"):
            self.assertNotIn(forbidden, text)

    def test_shaders_use_supplied_clock(self):
        for p in (ROOT / "game/presentation").glob("*.gdshader"):
            source = re.sub(r"//[^\n]*", "", p.read_text())
            self.assertNotRegex(source, r"\bTIME\b")
        self.assertIn('set_shader_parameter("sampled_seconds",seconds)',
                      (ROOT / "game/presentation/workshop_kit.gd").read_text())

    def test_mesh_kit_cannot_introduce_collision(self):
        text = (ROOT / "game/presentation/workshop_kit.gd").read_text()
        for forbidden in ("StaticBody", "RigidBody", "CollisionShape", "NavigationRegion", "HTTPRequest"):
            self.assertNotIn(forbidden, text)

    def test_same_launch_not_a_second_world(self):
        text = (ROOT / "game/childhood/home_launch.gd").read_text()
        self.assertIn('preload("res://world/home_territory.tscn")', text)
        self.assertIn('preload("res://presentation/art_chapter.gd")', text)
        self.assertIn('extends "res://geography/atlas_chapter.gd"',
                      (ROOT / "game/presentation/art_chapter.gd").read_text())

    def test_ui_binding_does_not_replace_existing_keys(self):
        text = (ROOT / "game/presentation/art_chapter.gd").read_text()
        self.assertIn("KEY_F7", text)
        for key in ("KEY_F4", "KEY_F6", "KEY_F5", "KEY_F9"):
            self.assertNotIn(key, text)


if __name__ == "__main__":
    unittest.main(verbosity=2)
