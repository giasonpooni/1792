"""Offline packaging/contract tests. Synthetic headers are not executable builds."""
from __future__ import annotations

import json
import struct
import tempfile
import unittest
from pathlib import Path
from package_platform import ROOT, check_payload, sha256, stage


class PlatformChecks(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.source = self.root / "source"; self.source.mkdir()
        header = bytearray(96); header[:2] = b"MZ"
        struct.pack_into("<I", header, 0x3C, 64)
        header[64:70] = b"PE\0\0\x64\x86"
        (self.source / "1792.exe").write_bytes(header)
        (self.source / "1792.pck").write_bytes(b"GDPCsynthetic-test-not-a-real-pack")
        self.notices = self.root / "notices.json"
        self.notices.write_text(json.dumps({"schema": "cg.engine-notices.v1", "engine": "4.5.1-stable (synthetic)",
                                           "godot_license": "synthetic licence fixture",
                                           "components": [{"name": "test"}], "licenses": {"test": "test"}}))
        self.args = dict(source=self.source, output=self.root / "out", notices=self.notices,
                         target="windows_local", source_commit="a" * 40, source_tree="b" * 40,
                         execution_id="synthetic-packaging-test")

    def test_allowlist_and_hashes(self) -> None:
        (self.source / "private-key.pem").write_text("must not be copied")
        result = stage(**self.args)
        self.assertFalse((self.args["output"] / "content/private-key.pem").exists())
        self.assertEqual(result["files"]["1792.exe"]["sha256"], sha256(self.source / "1792.exe"))
        self.assertEqual(result["runtime_provider"], "cg.local-pc.v1")
        self.assertFalse(result["store_uploaded"] or result["signed"] or result["console_certified"])
        self.assertIn("ENGINE-NOTICES.json", result["files"])

    def test_existing_output_untouched(self) -> None:
        self.args["output"].mkdir(); sentinel = self.args["output"] / "keep"
        sentinel.write_text("original")
        with self.assertRaises(ValueError): stage(**self.args)
        self.assertEqual(sentinel.read_text(), "original")

    def test_bad_headers_rejected(self) -> None:
        for filename in ("1792.exe", "1792.pck"):
            original = (self.source / filename).read_bytes()
            (self.source / filename).write_bytes(b"not executable")
            with self.assertRaises(ValueError): check_payload(self.source)
            (self.source / filename).write_bytes(original)

    def test_other_architecture_rejected(self) -> None:
        data = bytearray((self.source / "1792.exe").read_bytes()); data[68:70] = b"\x4c\x01"
        (self.source / "1792.exe").write_bytes(data)
        with self.assertRaises(ValueError): stage(**self.args)

    def test_missing_notices_rejected(self) -> None:
        self.notices.write_text("{}")
        with self.assertRaises(ValueError): stage(**self.args)
        self.assertFalse(self.args["output"].exists())

    def test_unsupported_targets_fail_closed(self) -> None:
        for target in ("microsoft_pc", "xbox_series", "unknown"):
            with self.subTest(target=target), self.assertRaises(ValueError): stage(**(self.args | {"target": target}))
        self.assertFalse(self.args["output"].exists())

    def test_source_id_is_not_branch_name(self) -> None:
        for key in ("source_commit", "source_tree"):
            with self.assertRaises(ValueError): stage(**(self.args | {key: "main"}))

    def test_steam_requires_explicit_valid_ids(self) -> None:
        for app, depot in ((None, None), ("480", "481"), ("12", "12"), ('12"', "13"), ("0", "13")):
            with self.assertRaises(ValueError):
                stage(**(self.args | {"target": "steam_windows", "app_id": app, "depot_id": depot}))

    def test_steam_recipe_is_preview_only(self) -> None:
        stage(**(self.args | {"target": "steam_windows", "app_id": "1234567", "depot_id": "1234568"}))
        recipe = (self.args["output"] / "steam-preview/app_build.vdf").read_text()
        self.assertIn('"Preview" "1"', recipe)
        self.assertNotIn("SetLive", recipe)
        self.assertNotIn("password", recipe.lower())
        self.assertIn('"ContentRoot" "../content"', recipe)

    def test_local_target_rejects_store_identity(self) -> None:
        with self.assertRaises(ValueError): stage(**(self.args | {"app_id": "1234567"}))

    def test_target_declarations_are_honest(self) -> None:
        targets = json.loads((ROOT / "platforms/targets.v1.json").read_text())["targets"]
        self.assertEqual(set(targets), {"windows_local", "steam_windows", "microsoft_pc", "xbox_series"})
        self.assertTrue(all(not value["store_upload"] and not value["console_certification"] for value in targets.values()))

    def test_export_excludes_development_sources(self) -> None:
        text = (ROOT / "game/export_presets.cfg").read_text()
        for declaration in ('platform="Windows Desktop"', 'binary_format/architecture="x86_64"',
                            'exclude_filter="tests/*"', 'binary_format/embed_pck=false', 'codesign/enable=false'):
            self.assertIn(declaration, text)


if __name__ == "__main__":
    unittest.main(verbosity=2)
