"""Negative capture cases: image substitution and misleading comparison metadata."""
from __future__ import annotations
import copy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from check_gujranwala_daily_detail_capture import check_capture
from test_check_gujranwala_beauty_capture import png, SIZE


class DailyDetailCaptureChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.images, cls.pixels = {}, {}
        cls.template = {
            "schema": "1792.gujranwala-daily-detail-render.v1", "failures": 0,
            "inspection_camera_only": True, "historical_authentication": False,
            "human_art_approval": False, "engine": "4.5.1", "renderer": "gl_compatibility",
            "device": "synthetic-negative-fixture", "source_commit": "c"*40,
            "source_tree": "d"*40, "captures": [],
        }
        for view in ("door", "market", "well"):
            for enabled in (False, True):
                name = view + ("-detail" if enabled else "-baseline")
                pixels = bytes((60 if enabled else 40, 30, 25, 255, 41, 31, 26, 255)) * (SIZE[0]*SIZE[1]//2)
                data = png(pixels)
                cls.images[name], cls.pixels[name] = data, pixels
                cls.template["captures"].append({
                    "id": name, "comparison": view, "preset": "daylight", "file": name+".png",
                    "sha256": hashlib.sha256(data).hexdigest(), "pixel_sha256": hashlib.sha256(pixels).hexdigest(),
                    "pixel_format": "rgba8", "width": SIZE[0], "height": SIZE[1],
                    "tick": 8, "campaign_snapshot_sha256": "a"*64, "frozen_state": True,
                    "camera_position": [0, 2, 5], "target": [0, 1, 8], "fov": 52,
                    "camera_kind": "explicit-art-inspection", "gameplay_camera": False,
                    "daily_detail_enabled": enabled,
                })

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        self.manifest = copy.deepcopy(self.template)
        for name, data in self.images.items(): (self.folder/(name+".png")).write_bytes(data)

    def record(self, name):
        return next(r for r in self.manifest["captures"] if r["id"] == name)

    def verify(self):
        (self.folder/"manifest.json").write_text(json.dumps(self.manifest))
        return check_capture(self.folder)

    def test_complete_frozen_pairs_pass(self):
        self.assertEqual(self.verify()["captures"], 6)

    def test_metadata_only_image_change_is_refused(self):
        pixels = self.pixels["door-baseline"]
        data = png(pixels, b"changed label without changed geometry")
        (self.folder/"door-detail.png").write_bytes(data)
        self.record("door-detail").update(sha256=hashlib.sha256(data).hexdigest(), pixel_sha256=hashlib.sha256(pixels).hexdigest())
        with self.assertRaisesRegex(ValueError, "not visibly represented"): self.verify()

    def test_substituted_baseline_with_false_pixel_hash_is_refused(self):
        data = self.images["market-baseline"]
        (self.folder/"market-detail.png").write_bytes(data)
        self.record("market-detail")["sha256"] = hashlib.sha256(data).hexdigest()
        with self.assertRaisesRegex(ValueError, "identity mismatch"): self.verify()

    def test_changed_camera_tick_or_state_cannot_prove_detail(self):
        for key, value in (("camera_position", [1, 2, 5]), ("fov", 54), ("tick", 9), ("campaign_snapshot_sha256", "b"*64)):
            with self.subTest(key=key):
                self.manifest = copy.deepcopy(self.template)
                self.record("door-detail")[key] = value
                with self.assertRaisesRegex(ValueError, "comparison changes"): self.verify()

    def test_incorrect_layer_or_gameplay_labels_are_refused(self):
        for key, value in (("daily_detail_enabled", False), ("gameplay_camera", True), ("frozen_state", False)):
            with self.subTest(key=key):
                self.manifest = copy.deepcopy(self.template)
                self.record("door-detail")[key] = value
                with self.assertRaisesRegex(ValueError, "comparison labels"): self.verify()

    def test_source_identity_and_failure_cannot_be_removed(self):
        self.manifest["source_tree"] = ""
        with self.assertRaisesRegex(ValueError, "source identity"): self.verify()
        self.manifest = copy.deepcopy(self.template)
        self.manifest["failures"] = 1
        with self.assertRaisesRegex(ValueError, "Failed or mislabeled"): self.verify()


if __name__ == "__main__":
    unittest.main(verbosity=2)
