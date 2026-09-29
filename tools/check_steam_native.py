"""Synthetic lock/extraction/observation tests. These do not execute a native runtime."""
from __future__ import annotations
import copy
import hashlib
import io
import json
import tarfile
import tempfile
import unittest
from pathlib import Path
from steam_native import _extract_locked, digest, inspect, install, reference_record, validate_probe


class SteamNativeChecks(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "synthetic.tar.xz"
        self.destination = self.root / "out"; self.destination.mkdir()
        self.members = {"runtime.exe": (3, hashlib.sha256(b"abc").hexdigest()),
                        "library.dll": (3, hashlib.sha256(b"def").hexdigest())}
        self.selected = {"runtime.exe"}

    def archive(self, entries: list[tuple[str, bytes]], *, linked: bool = False) -> None:
        with tarfile.open(self.source, "w:xz") as out:
            for name, data in entries:
                entry = tarfile.TarInfo(name)
                if linked:
                    entry.type = tarfile.SYMTYPE; entry.linkname = "outside"
                    out.addfile(entry)
                else:
                    entry.size = len(data); out.addfile(entry, io.BytesIO(data))

    def extract(self) -> None:
        _extract_locked(self.source, self.destination, self.members, self.selected)

    def record(self) -> dict:
        return {"schema": "cg.steam-native-probe.v1", "source_commit": "a"*40, "source_tree": "b"*40,
                "build_execution_id": "synthetic-test", "os": "Windows", "engine": "4.5.1.stable.synthetic",
                "exported": True, "native_module_loaded": True, "adapter_contract_matches": True,
                "client_running": False, "adapter_preflight_refused_without_client": True,
                "sdk_session_initialized": False, "live_client_qualified": False,
                "physical_hardware_qualified": False, "store_uploaded": False, "errors": []}

    def validate(self, value: object) -> dict:
        return validate_probe(value, source_commit="a"*40, source_tree="b"*40, exported=True)

    def test_extract_exact_selected_regular_members(self) -> None:
        self.archive([("runtime.exe", b"abc"), ("library.dll", b"def")]); self.extract()
        self.assertEqual((self.destination/"runtime.exe").read_bytes(), b"abc")
        self.assertFalse((self.destination/"library.dll").exists())

    def test_missing_member_refused(self) -> None:
        self.archive([("runtime.exe", b"abc")])
        with self.assertRaises(ValueError): self.extract()

    def test_duplicate_member_refused(self) -> None:
        self.archive([("runtime.exe", b"abc"), ("runtime.exe", b"abc")])
        with self.assertRaises(ValueError): self.extract()

    def test_unexpected_path_refused(self) -> None:
        for name in ("../runtime.exe", "nested/runtime.exe", "RUNTIME.exe", "runtime.exe:stream"):
            self.archive([(name, b"abc")])
            with self.subTest(name=name), self.assertRaises(ValueError): self.extract()
        self.assertEqual(list(self.destination.iterdir()), [])

    def test_link_refused_without_touching_target(self) -> None:
        outside=self.root/"outside"; outside.write_bytes(b"protected")
        self.archive([("runtime.exe", b"")], linked=True)
        with self.assertRaises(ValueError): self.extract()
        self.assertEqual(outside.read_bytes(), b"protected")

    def test_size_and_digest_are_both_checked(self) -> None:
        for data in (b"abcd", b"abd"):
            self.archive([("library.dll", data)])
            with self.subTest(data=data), self.assertRaises(ValueError): self.extract()

    def test_existing_native_destination_is_never_replaced(self) -> None:
        target=self.destination/"keep"; target.write_bytes(b"original")
        with self.assertRaises(ValueError): install(self.destination, self.source)
        self.assertEqual(target.read_bytes(), b"original")

    def test_bad_archive_does_not_promote_or_leave_scratch(self) -> None:
        self.source.write_bytes(b"NOT THE NATIVE ARCHIVE")
        output=self.root/"new"
        with self.assertRaises(ValueError): install(output, self.source)
        self.assertFalse(output.exists())
        self.assertEqual(list(self.root.glob(".steam-reference-*")), [])
        self.assertEqual(self.source.read_bytes(), b"NOT THE NATIVE ARCHIVE")

    def test_existing_member_never_overwritten_by_extractor(self) -> None:
        target=self.destination/"runtime.exe"; target.write_bytes(b"protected")
        self.archive([("runtime.exe", b"abc"), ("library.dll", b"def")])
        with self.assertRaises(FileExistsError): self.extract()
        self.assertEqual(target.read_bytes(), b"protected")

    def test_reference_has_no_fabricated_client_or_redistribution_permission(self) -> None:
        record=reference_record()
        self.assertIs(record["steam_client_qualified"], False)
        self.assertIs(record["redistribution_authorized"], False)
        copy_record=copy.deepcopy(record); copy_record["files"].clear()
        self.assertTrue(reference_record()["files"])

    def test_reference_requires_actual_locked_files(self) -> None:
        (self.destination/"reference.json").write_text(json.dumps(reference_record()))
        with self.assertRaises(ValueError): inspect(self.destination)

    def test_digest_checks_regular_file_and_length(self) -> None:
        path=self.root/"small"; path.write_bytes(b"abc")
        self.assertEqual(digest(path,3), hashlib.sha256(b"abc").hexdigest())
        with self.assertRaises(ValueError): digest(path,4)
        with self.assertRaises(ValueError): digest(self.destination)

    def test_complete_synthetic_observation_shape(self) -> None:
        self.assertEqual(self.validate(self.record()), self.record())

    def test_no_missing_or_extra_observation_fields(self) -> None:
        for key in self.record():
            data=self.record(); del data[key]
            with self.subTest(key=key), self.assertRaises(ValueError): self.validate(data)
        with self.assertRaises(ValueError): self.validate(self.record() | {"account_id": "not collected"})

    def test_false_claims_or_wrong_source_rejected(self) -> None:
        for key,value in (("source_commit","c"*40),("source_tree","c"*40),("os","Linux"),("exported",False),
                          ("native_module_loaded",False),("adapter_contract_matches",False),
                          ("client_running",True),("sdk_session_initialized",True),("live_client_qualified",True),
                          ("physical_hardware_qualified",True),("store_uploaded",True),("errors",["incomplete"]),
                          ("adapter_preflight_refused_without_client",False),("engine","4.6.stable")):
            with self.subTest(key=key), self.assertRaises(ValueError): self.validate(self.record() | {key:value})

    def test_boolean_integer_substitution_rejected(self) -> None:
        for key,value in self.record().items():
            if type(value) is bool:
                with self.subTest(key=key), self.assertRaises(ValueError): self.validate(self.record() | {key:int(value)})

    def test_wrong_observation_types_refused(self) -> None:
        for value in (None, [], True, {}, "not a report"):
            with self.subTest(value=value), self.assertRaises(ValueError): self.validate(value)


if __name__ == "__main__": unittest.main(verbosity=2)
