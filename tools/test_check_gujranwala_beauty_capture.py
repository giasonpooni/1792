"""Adversarial capture fixtures for independent beauty verification."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest
import zlib

from check_gujranwala_beauty_capture import CAPTURES, SIZE, check_capture


def chunk(kind: bytes, content: bytes) -> bytes:
    return (struct.pack(">I", len(content)) + kind + content
            + struct.pack(">I", zlib.crc32(kind + content) & 0xffffffff))


def png(pixels: bytes, metadata: bytes = b"") -> bytes:
    width, height = SIZE
    rows = b"".join(b"\0" + pixels[y * width * 4:(y + 1) * width * 4] for y in range(height))
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
            + (chunk(b"tEXt", b"note\0" + metadata) if metadata else b"")
            + chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b""))


class BeautyCaptureChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.images = {}
        cls.pixels = {}
        cls.template = {
            "schema": "1792.gujranwala-beauty-render.v2", "failures": 0,
            "inspection_camera_only": True, "historical_authentication": False,
            "human_art_approval": False, "engine": "4.5.1", "renderer": "gl_compatibility",
            "device": "fixture", "captures": [],
        }
        for i, (name, preset) in enumerate(CAPTURES.items()):
            pixels = bytes((40 + i * 10, 27, 48, 255, 41 + i * 10, 28, 50, 255)) * (SIZE[0] * SIZE[1] // 2)
            data = png(pixels)
            cls.images[name] = data
            cls.pixels[name] = pixels
            cls.template["captures"].append({
                "id": name, "preset": preset, "file": name + ".png",
                "sha256": hashlib.sha256(data).hexdigest(),
                "pixel_sha256": hashlib.sha256(pixels).hexdigest(),
                "pixel_format": "rgba8", "width": SIZE[0], "height": SIZE[1],
                "tick": 8, "campaign_snapshot_sha256": "a" * 64, "frozen_state": True,
                "camera_position": [0, 4.7, -3], "target": [0, 1.65, 10.2], "fov": 52,
                "camera_kind": "explicit-art-inspection", "gameplay_camera": False,
            })

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        self.manifest = copy.deepcopy(self.template)
        for name, data in self.images.items():
            (self.folder / (name + ".png")).write_bytes(data)
        self.write_manifest()

    def write_manifest(self):
        (self.folder / "manifest.json").write_text(json.dumps(self.manifest))

    def record(self, name):
        return next(r for r in self.manifest["captures"] if r["id"] == name)

    def assert_rejected(self, text):
        self.write_manifest()
        with self.assertRaisesRegex(ValueError, text):
            check_capture(self.folder)

    def test_accepts_complete_frozen_same_camera_capture(self):
        result = check_capture(self.folder)
        self.assertEqual((result["status"], result["captures"], result["same_camera_lighting_presets"]), ("passed", 6, 3))

    def test_metadata_only_png_changes_do_not_prove_evening_lighting(self):
        name = "courtyard-evening"
        pixels = self.pixels["courtyard-golden"]
        data = png(pixels, b"evening metadata makes PNG bytes different")
        self.assertNotEqual(data, self.images["courtyard-golden"])
        (self.folder / (name + ".png")).write_bytes(data)
        self.record(name).update(sha256=hashlib.sha256(data).hexdigest(), pixel_sha256=hashlib.sha256(pixels).hexdigest())
        self.assert_rejected("Same-camera lighting pixels")

    def test_forged_pixel_hash_cannot_disguise_identical_lighting(self):
        name = "courtyard-evening"
        data = self.images["courtyard-daylight"]
        (self.folder / (name + ".png")).write_bytes(data)
        self.record(name)["sha256"] = hashlib.sha256(data).hexdigest()
        self.assert_rejected("PNG byte/pixel identity mismatch")

    def test_changed_camera_or_campaign_state_rejects_lighting_comparison(self):
        for field, value in (("camera_position", [1, 4.7, -3]), ("fov", 54), ("tick", 9), ("campaign_snapshot_sha256", "b" * 64)):
            with self.subTest(field=field):
                self.manifest = copy.deepcopy(self.template)
                self.record("courtyard-evening")[field] = value
                self.assert_rejected("Lighting comparison changes")

    def test_incomplete_failed_or_gameplay_mislabeled_capture_rejected(self):
        for field, value in (("failures", 1), ("inspection_camera_only", False), ("historical_authentication", True)):
            with self.subTest(field=field):
                self.manifest = copy.deepcopy(self.template)
                self.manifest[field] = value
                self.assert_rejected("Failed or mislabeled")
        self.manifest = copy.deepcopy(self.template)
        self.record("courtyard-evening")["gameplay_camera"] = True
        self.assert_rejected("Invalid capture labels")
        self.manifest = copy.deepcopy(self.template)
        self.manifest["captures"].pop()
        self.assert_rejected("Expected six")

    def test_valid_hash_for_blank_or_broken_png_still_rejected(self):
        name = "courtyard-evening"
        pixels = bytes((0, 0, 0, 255)) * (SIZE[0] * SIZE[1])
        data = png(pixels)
        (self.folder / (name + ".png")).write_bytes(data)
        self.record(name).update(sha256=hashlib.sha256(data).hexdigest(), pixel_sha256=hashlib.sha256(pixels).hexdigest())
        self.assert_rejected("Blank inspection image")
        data = self.images[name][:-12]
        (self.folder / (name + ".png")).write_bytes(data)
        self.record(name)["sha256"] = hashlib.sha256(data).hexdigest()
        self.assert_rejected("Incomplete PNG")

    def test_missing_png_and_duplicate_capture_rejected(self):
        self.manifest["captures"][-1] = copy.deepcopy(self.manifest["captures"][0])
        self.assert_rejected("Unexpected or duplicate")
        self.manifest = copy.deepcopy(self.template)
        (self.folder / "courtyard-evening.png").unlink()
        self.write_manifest()
        with self.assertRaises(FileNotFoundError):
            check_capture(self.folder)


if __name__ == "__main__":
    unittest.main(verbosity=2)
