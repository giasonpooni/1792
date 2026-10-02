"""Adversarial evidence tests; these synthetic records are not gameplay evidence."""
from __future__ import annotations

import copy
import hashlib
import json
import math
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest
import zlib

from qualify_opening import CAPTURES, MEMORIES, SKILLS, archive_tree, check_manifest, native_save_projection, sha


def chunk(kind: bytes, content: bytes) -> bytes:
    return struct.pack(">I", len(content)) + kind + content + struct.pack(">I", zlib.crc32(kind + content) & 0xffffffff)


class OpeningEvidenceChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        pixels = bytes((40, 27, 48, 255, 41, 28, 50, 255)) * (1280 * 720 // 2)
        rows = b"".join(b"\0" + pixels[y * 1280 * 4:(y + 1) * 1280 * 4] for y in range(720))
        cls.image = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1280, 720, 8, 6, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b""))
        cls.pixel_sha = sha(pixels)
        cls.receipt = {"schema": "1792.riding-training-receipt.v1", "lesson_id": "mahan-horsecraft-training.v1",
                       "subject_id": "ranjit_singh", "flashback_actor_id": "mahan_singh",
                       "historical_status": "user-attributed-unverified", "present_sha256": "a" * 64,
                       "entry_tick": 5, "completed_tick": 1169,
                       "milestones": [{"id": name, "tick": tick} for name, tick in zip(SKILLS, (144, 297, 1169))],
                       "facts": {"single_hold_ticks": 60, "paired_hold_ticks": 60,
                                 "volley_slots": [0, 1, 2, 3], "reloaded_slots": [0, 1, 2, 3]}}
        proof = {key: value for key, value in cls.receipt.items() if key not in ("schema", "present_sha256")}
        cls.receipt["completion_sha256"] = sha(json.dumps(proof, sort_keys=True, separators=(",", ":")).encode())

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        self.images = self.folder / "opening-chapter-images"
        self.images.mkdir()
        self.checkpoint = self.folder / "courtyard-checkpoint.json"
        self.final_save = self.folder / "final-manual-save.json"
        saved = self.snapshot(False, 40)
        progressed = self.snapshot(True, 50)
        final = self.snapshot(True, 60)
        checkpoint_state = copy.deepcopy(saved)
        checkpoint_state["aftermath"]["memories"] = []
        self.write(self.checkpoint, {"schema": "1792.chapter-checkpoint.v1", "reason": "courtyard_return",
                                     "snapshot": checkpoint_state})
        self.write(self.final_save, final)
        self.write(self.images / "midreturn-save.json", saved)
        self.manifest = {"schema": "1792.opening-chapter-render.v2", "failures": 0, "checks": 200,
                         "progress_seeded": False, "capability_receipt_seeded": False, "camera_pose_injected": False,
                         "startup_save_seeded": False, "human_playtest": False, "historical_authentication": False,
                         "saved_pose_restored": True, "physics_hz": 60, "entry": "actual HomeLaunch.enter",
                         "engine": "4.5.1-stable (official)", "renderer": "gl_compatibility",
                         "earned_training_receipt": copy.deepcopy(self.receipt),
                         "native_shot_observations": [{"slot": slot, "shot_id": "shot-" + str(slot)} for slot in range(4)],
                         "final_snapshot": final,
                         "midreturn_persistence": {"saved_snapshot": saved, "restored_snapshot": copy.deepcopy(saved),
                                                   "progressed_snapshot": progressed, "saved_tick": 40, "restored_tick": 40,
                                                   "declared_saved_pose_restored": True, "retained_file": "midreturn-save.json",
                                                   "save_sha256": sha((self.images / "midreturn-save.json").read_bytes())},
                         "final_manual_save": {"sha256": sha(self.final_save.read_bytes()), "snapshot": final},
                         "production_automatic_checkpoint": {"sha256": sha(self.checkpoint.read_bytes())}, "captures": []}
        for name in CAPTURES:
            (self.images / (name + ".png")).write_bytes(self.image)
            self.manifest["captures"].append({"id": name, "file": name + ".png", "camera_pose_injected": False,
                                              "inspection_camera_only": False, "pixel_format": "rgba8", "width": 1280,
                                              "height": 720, "camera_kind": "production-gameplay", "state_sha256": "b" * 64,
                                              "sha256": sha(self.image), "pixel_sha256": self.pixel_sha})
        self.update()

    def snapshot(self, complete: bool, tick: int) -> dict:
        ids = MEMORIES if complete else MEMORIES[:-1]
        return {"player": {"character_id": "ranjit_singh"},
                "childhood": {"tick": tick, "ambush": {"status": "escaped", "hits": 0}, "ride_gate": 3,
                              "parries": 2, "counters": 1, "tracks": 3, "quarry_seen": True},
                "riding_skills": {"lesson_receipts": [copy.deepcopy(self.receipt)]},
                "aftermath": {"decision": "household_escort", "heard": MEMORIES[:2], "offer_heard": True,
                              "decision_tick": 10, "clue_tick": 20, "reported_tick": 30 if complete else -1,
                              "escort": {"active": not complete, "instruction": "hold" if complete else "follow",
                                         "position": [6.1432061195373535, 0.14, -11], "yaw": 0.0, "velocity": [0, 0, 0]},
                              "memories": [{"id": name, "received_tick": 5 + i * 5,
                                            "text": "The riders remain unidentified."} for i, name in enumerate(ids)]}}

    @staticmethod
    def write(path: Path, value: dict) -> None:
        path.write_text(json.dumps(value), encoding="utf-8")

    def update(self):
        self.write(self.images / "manifest.json", self.manifest)

    def verify(self):
        return check_manifest(self.images, self.checkpoint, self.final_save)

    def test_valid_recorded_consistency(self):
        result = self.verify()
        self.assertEqual(result["captures"], 18)
        self.assertTrue(result["native_midreturn_rollback_verified"])

    def test_png_byte_tamper_and_pixel_identity_are_independent(self):
        image = self.images / (CAPTURES[0] + ".png")
        image.write_bytes(self.image[:-12] + chunk(b"tEXt", b"note\0tampered") + self.image[-12:])
        with self.assertRaisesRegex(ValueError, "byte/pixel mismatch"):
            self.verify()
        image.write_bytes(self.image)
        self.manifest["captures"][0]["pixel_sha256"] = "c" * 64
        self.update()
        with self.assertRaisesRegex(ValueError, "byte/pixel mismatch"):
            self.verify()

    def test_missing_extra_and_reordered_captures_refused(self):
        self.manifest["captures"].pop()
        self.update()
        with self.assertRaisesRegex(ValueError, "opening captures"):
            self.verify()

    def test_stale_preinquiry_evidence_refused(self):
        self.manifest["schema"] = "1792.opening-chapter-render.v1"
        self.update()
        with self.assertRaisesRegex(ValueError, "unsupported opening manifest"):
            self.verify()

    def test_checkpoint_digest_tamper_refused(self):
        self.checkpoint.write_bytes(self.checkpoint.read_bytes() + b"\n")
        with self.assertRaisesRegex(ValueError, "checkpoint digest"):
            self.verify()

    def test_whole_save_rollback_mismatch_refused(self):
        self.manifest["midreturn_persistence"]["restored_snapshot"]["player"]["extra_progress"] = 1
        self.update()
        with self.assertRaisesRegex(ValueError, "whole saved authority"):
            self.verify()

    def test_retained_midreturn_save_tamper_refused(self):
        (self.images / "midreturn-save.json").write_bytes(b"{}")
        with self.assertRaisesRegex(ValueError, "native-save digest"):
            self.verify()

    def test_only_guard_binary32_pose_reconciles_json_rounding(self):
        original = self.snapshot(False, 40)
        parsed = copy.deepcopy(original)
        parsed["aftermath"]["escort"]["position"][0] = math.nextafter(6.1432061195373535, 0)
        self.assertEqual(native_save_projection(original), native_save_projection(parsed))
        parsed["aftermath"]["clue_tick"] = 21
        self.assertNotEqual(native_save_projection(original), native_save_projection(parsed))
        parsed = copy.deepcopy(original)
        parsed["aftermath"]["escort"]["position"][0] += 0.001
        self.assertNotEqual(native_save_projection(original), native_save_projection(parsed))

    def test_git_archive_reconstructs_exact_tree_modes_and_symlink(self):
        repository = self.folder / "source"
        repository.mkdir()
        def git(*args):
            return subprocess.check_output(["git", *args], cwd=repository, stderr=subprocess.DEVNULL).strip()
        git("init", "-q")
        (repository / "a").write_bytes(b"source\n")
        (repository / "dir").mkdir()
        (repository / "dir" / "execute").write_bytes(b"#!/bin/sh\n")
        (repository / "dir" / "execute").chmod(0o755)
        (repository / "alias").symlink_to("a")
        git("add", ".")
        git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture")
        archive = self.folder / "source.tar"
        archive.write_bytes(git("archive", "--format=tar", "HEAD"))
        tree, files = archive_tree(archive)
        self.assertEqual(tree, git("rev-parse", "HEAD^{tree}").decode())
        self.assertEqual(files["alias"], b"a")


if __name__ == "__main__":
    unittest.main()
