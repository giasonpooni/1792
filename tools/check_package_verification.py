"""Adversarial package fixtures. Synthetic PE/PCK headers are never run as games."""
from __future__ import annotations

import hashlib
import json
import shutil
import stat
import struct
import tempfile
import unittest
import warnings
import zipfile
from pathlib import Path
from package_platform import stage
from verify_platform import verify


class PackageVerificationChecks(unittest.TestCase):
    def setUp(self) -> None:
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.source = self.root / "source"
        self.source.mkdir()
        pe = bytearray(96); pe[:2] = b"MZ"
        struct.pack_into("<I", pe, 60, 64); pe[64:70] = b"PE\0\0\x64\x86"
        (self.source / "1792.exe").write_bytes(pe)
        (self.source / "1792.pck").write_bytes(b"GDPC-not-a-real-game")
        self.notices = self.root / "notices.json"
        self.notices.write_text(json.dumps({"schema": "cg.engine-notices.v1", "engine": "4.5.1-stable (synthetic)",
                                            "godot_license": "test", "components": [{"name": "test"}], "licenses": {"test": "test"}}))
        self.output = self.root / "package"
        self.args = dict(source=self.source, output=self.output, notices=self.notices, target="windows_local",
                         source_commit="a" * 40, source_tree="b" * 40, execution_id="synthetic-package-test")
        self.expected = dict(expected_commit="a" * 40, expected_tree="b" * 40)

    def stage(self, steam: bool = False) -> dict:
        return stage(**(self.args | ({"target": "steam_windows", "app_id": "1234567", "depot_id": "1234568"} if steam else {})))

    def write_manifest(self, m: dict) -> None:
        (self.output / "manifest.json").write_text(json.dumps(m), encoding="utf-8")

    def archive(self) -> Path:
        return Path(shutil.make_archive(str(self.root / "package-archive"), "zip", self.output))

    def test_directory_and_archive_equivalent(self) -> None:
        self.stage()
        before = {p.relative_to(self.output).as_posix(): p.read_bytes() for p in self.output.rglob("*") if p.is_file()}
        report = verify(self.output, **self.expected)
        self.assertEqual(report, verify(self.archive(), **self.expected))
        self.assertEqual(report["files_checked"], 7)
        self.assertFalse(report["authenticity_verified"] or report["payload_executed_by_verifier"])
        self.assertEqual(before, {p.relative_to(self.output).as_posix(): p.read_bytes() for p in self.output.rglob("*") if p.is_file()})

    def test_legacy_local_v1_remains_readable(self) -> None:
        m = self.stage(); m["schema"] = "cg.platform-build.v1"; m.pop("recipes"); m.pop("steam_preview")
        self.write_manifest(m)
        self.assertEqual(verify(self.output)["manifest_schema"], "cg.platform-build.v1")

    def test_preview_recipes_bound_to_manifest(self) -> None:
        m = self.stage(steam=True)
        self.assertEqual(set(m["recipes"]), {"steam-preview/app_build.vdf", "steam-preview/depot_build.vdf"})
        report = verify(self.archive(), **self.expected)
        self.assertEqual(report["steam_preview"]["app_id"], "1234567")
        self.assertEqual(report["files_checked"], 9)

    def test_rehashed_steam_upload_recipe_still_refused(self) -> None:
        m = self.stage(steam=True)
        name = "steam-preview/app_build.vdf"
        p = self.output / name
        data = p.read_bytes().replace(b'"Preview" "1"', b'"Preview" "0"')
        p.write_bytes(data)
        m["recipes"][name] = {"bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
        self.write_manifest(m)
        with self.assertRaisesRegex(ValueError, "preview-only"):
            verify(self.output)

    def test_manifest_steam_ids_cannot_disagree_with_recipe(self) -> None:
        m = self.stage(steam=True); m["steam_preview"]["depot_id"] = "99999"
        self.write_manifest(m)
        with self.assertRaises(ValueError): verify(self.output)

    def test_local_cannot_carry_steam_identity(self) -> None:
        m = self.stage(); m["steam_preview"] = {"app_id": "1234567", "depot_id": "1234568", "preview": True}
        self.write_manifest(m)
        with self.assertRaises(ValueError): verify(self.output)

    def test_legacy_unbound_steam_recipe_refused(self) -> None:
        m = self.stage(steam=True); m["schema"] = "cg.platform-build.v1"; m.pop("recipes"); m.pop("steam_preview")
        self.write_manifest(m)
        with self.assertRaisesRegex(ValueError, "Legacy Steam"): verify(self.output)

    def test_expected_source_binding(self) -> None:
        self.stage()
        for expected in ({"expected_commit": "c" * 40}, {"expected_tree": "c" * 40}, {"expected_commit": "main"}):
            with self.subTest(expected=expected), self.assertRaises(ValueError): verify(self.output, **expected)

    def test_source_manifest_strict_fields(self) -> None:
        m = self.stage()
        for patch in ({"schema": "future"}, {"extra": "surprise"}, {"source_commit": 12}, {"execution_id": ""},
                      {"game_id": "other"}, {"runtime_provider": "steam"}, {"target": "xbox_series"}):
            self.write_manifest(m | patch)
            with self.subTest(patch=patch), self.assertRaises(ValueError): verify(self.output)

    def test_cannot_claim_signing_or_publication(self) -> None:
        m = self.stage()
        for key in ("signed", "store_uploaded", "console_certified"):
            self.write_manifest(m | {key: True})
            with self.subTest(key=key), self.assertRaises(ValueError): verify(self.output)
        self.write_manifest(m | {"signed": 0})
        with self.assertRaises(ValueError): verify(self.output)

    def test_duplicate_manifest_json_key_refused(self) -> None:
        self.stage()
        p = self.output / "manifest.json"
        p.write_text(p.read_text().replace('{', '{"schema":"cg.platform-build.v2",', 1))
        with self.assertRaisesRegex(ValueError, "Duplicate JSON"): verify(self.output)

    def test_nonfinite_manifest_json_refused(self) -> None:
        m = self.stage(); m["files"]["1792.exe"]["bytes"] = float("nan")
        self.write_manifest(m)
        with self.assertRaises(ValueError): verify(self.output)

    def test_changed_content_rejected(self) -> None:
        self.stage()
        p = self.output / "content/1792.pck"
        p.write_bytes(p.read_bytes()[:-1] + b"X")
        with self.assertRaisesRegex(ValueError, "hash mismatch"): verify(self.archive())

    def test_missing_payload_refused(self) -> None:
        self.stage(); (self.output / "content/1792.exe").unlink()
        with self.assertRaises(ValueError): verify(self.output)

    def test_extra_payload_and_directories_refused(self) -> None:
        self.stage(); p = self.output / "content/private.pem"; p.write_text("not for packaging")
        with self.assertRaises(ValueError): verify(self.output)
        p.unlink(); (self.output / "outside").mkdir()
        with self.assertRaises(ValueError): verify(self.output)

    def test_metadata_hash_record_types_strict(self) -> None:
        m = self.stage()
        for patch in ({"bytes": True}, {"sha256": "0" * 64}, {"bytes": -1}, {"extra": "x"}):
            bad = json.loads(json.dumps(m)); bad["files"]["1792.exe"].update(patch); self.write_manifest(bad)
            with self.subTest(patch=patch), self.assertRaises(ValueError): verify(self.output)

    def test_runtime_notices_engine_mismatch_refused(self) -> None:
        m = self.stage(); p = self.output / "content/ENGINE-NOTICES.json"
        data = json.loads(p.read_text()); data["engine"] = "different-runtime"
        p.write_text(json.dumps(data)); raw = p.read_bytes()
        m["files"][p.name] = {"bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}; self.write_manifest(m)
        with self.assertRaisesRegex(ValueError, "notices"): verify(self.output)

    def test_rehashed_wrong_executable_shape_refused(self) -> None:
        m = self.stage(); p = self.output / "content/1792.exe"; p.write_bytes(b"NOT-PE" * 20); raw = p.read_bytes()
        m["files"][p.name] = {"bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}; self.write_manifest(m)
        with self.assertRaisesRegex(ValueError, "PE"): verify(self.output)

    def test_traversal_backslash_absolute_and_drive_members_refused(self) -> None:
        self.stage()
        for name in ("../escape", "/absolute", "content/../escape", "content\\escape", "C:/escape", "content//escape"):
            p = self.archive()
            with zipfile.ZipFile(p, "a") as z: z.writestr(name, "bad")
            with self.subTest(name=name), self.assertRaises(ValueError): verify(p)
        self.assertFalse((self.root / "escape").exists())

    def test_duplicate_archive_member_refused(self) -> None:
        self.stage(); p = self.archive()
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            with zipfile.ZipFile(p, "a") as z: z.writestr("manifest.json", "{}")
        with self.assertRaisesRegex(ValueError, "Duplicate"): verify(p)

    def test_case_collision_refused(self) -> None:
        self.stage(); p = self.archive()
        with zipfile.ZipFile(p, "a") as z: z.writestr("CONTENT/1792.EXE", "duplicate-on-windows")
        with self.assertRaises(ValueError): verify(p)

    def test_archive_symlink_refused(self) -> None:
        self.stage(); p = self.archive()
        info = zipfile.ZipInfo("content/link"); info.create_system = 3; info.external_attr = (stat.S_IFLNK | 0o777) << 16
        with zipfile.ZipFile(p, "a") as z: z.writestr(info, "../../outside")
        with self.assertRaises(ValueError): verify(p)

    def test_archive_member_limit(self) -> None:
        p = self.root / "huge-entry-list.zip"
        with zipfile.ZipFile(p, "w") as z:
            for i in range(20): z.writestr(f"x{i}", "x")
        with self.assertRaisesRegex(ValueError, "Too many"): verify(p)

    def test_oversized_metadata_refused_before_parse(self) -> None:
        self.stage(); (self.output / "manifest.json").write_bytes(b" " * (2 * 1024 * 1024 + 1))
        with self.assertRaisesRegex(ValueError, "oversized"): verify(self.output)


if __name__ == "__main__":
    unittest.main(verbosity=2)
