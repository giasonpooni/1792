"""Contract tests use SYNTHETIC PE/PCK/logo/identity fixtures; no MakePkg or store account."""
from __future__ import annotations
import binascii
import hashlib
import json
import shutil
import struct
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path
from package_platform import stage
from microsoft_pc import LOGOS, game_config, inspect_stage, pack_pc, png_check, profile_error, stage_pc


def png(size: int, color: int = 2) -> bytes:
    def chunk(kind: bytes, body: bytes) -> bytes:
        return struct.pack('>I', len(body)) + kind + body + struct.pack('>I', binascii.crc32(kind+body) & 0xffffffff)
    data = (b'\0' + b'\x80' * size * (3 if color == 2 else 4)) * size
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, color, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(data)) + chunk(b'IEND', b'')


class StoreIntegrationChecks(unittest.TestCase):
    def setUp(self) -> None:
        temp = tempfile.TemporaryDirectory(); self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.raw = self.root / 'raw'; self.raw.mkdir()
        pe = bytearray(96);pe[:2] = b'MZ';struct.pack_into('<I',pe,60,64);pe[64:70] = b'PE\0\0\x64\x86'
        (self.raw/'1792.exe').write_bytes(pe);(self.raw/'1792.pck').write_bytes(b'GDPC-synthetic-not-a-game')
        notices = self.root/'notices.json'
        notices.write_text(json.dumps({'schema':'cg.engine-notices.v1','engine':'4.5.1-stable (synthetic)',
                                      'godot_license':'fixture','components':[{'name':'fixture'}],'licenses':{'fixture':'fixture'}}))
        self.package = self.root/'local-package'
        self.expected = dict(expected_commit='a'*40,expected_tree='b'*40)
        stage(self.raw,self.package,notices,target='windows_local',source_commit='a'*40,source_tree='b'*40,execution_id='synthetic')
        self.assets = self.root/'assets';self.assets.mkdir()
        for name,size in LOGOS.items(): (self.assets/(name+'.png')).write_bytes(png(size))
        self.profile = {'schema':'cg.microsoft-pc-identity.v1','identity_name':'12345.SyntheticFixture',
                        'identity_publisher':'CN=00000000-0000-0000-0000-000000000001','version':'1.0.0.0',
                        'store_id':'9XXXXXXXXXXX','display_name':'Fixture only','publisher_display_name':'Synthetic publisher',
                        'description':'Synthetic identity; not assigned by Microsoft'}
        self.output = self.root/'microsoft-stage'

    def prepare(self) -> dict:
        return stage_pc(self.package,self.profile,self.assets,self.output,**self.expected)

    def test_real_staging_code_on_labelled_fixtures(self) -> None:
        before = {p.relative_to(self.package):p.read_bytes() for p in self.package.rglob('*') if p.is_file()}
        result = self.prepare()
        self.assertEqual(inspect_stage(self.output), result)
        self.assertEqual(len(result['files']),11)
        for key in ('makepkg_executed','submission_validated','identity_assignment_verified','store_uploaded','console_port'):
            self.assertIs(result[key], False)
        self.assertEqual(before, {p.relative_to(self.package):p.read_bytes() for p in self.package.rglob('*') if p.is_file()})

    def test_zip_input_matches_directory(self) -> None:
        expected = self.prepare()
        archive = Path(shutil.make_archive(str(self.root/'input'), 'zip', self.package))
        actual = stage_pc(archive,self.profile,self.assets,self.root/'another',**self.expected)
        self.assertEqual(expected,actual)

    def test_explicit_source_identity(self) -> None:
        with self.assertRaises(ValueError): stage_pc(self.package,self.profile,self.assets,self.output,expected_commit='c'*40,expected_tree='b'*40)
        self.assertFalse(self.output.exists())

    def test_bad_identity_fields(self) -> None:
        for key in self.profile:
            candidate = dict(self.profile);del candidate[key]
            with self.subTest(key=key), self.assertRaises(ValueError): profile_error(candidate)
        for key,value in [('schema','unknown'),('version','0.0.0.0'),('version','1.65536.0.0'),('version','01.0.0.0'),
                          ('version','1.0.0'),('store_id',''),('identity_name','../bad'),('identity_publisher','not CN'),
                          ('description','line\ncontrol'),('display_name',True),('extra','no')]:
            with self.subTest(key=key,value=value), self.assertRaises(ValueError): profile_error(self.profile | {key:value})

    def test_xml_escaping_and_no_fake_xbox_services(self) -> None:
        p = self.profile | {'display_name':'A & B <C> "D"'}
        root = ET.fromstring(game_config(p))
        self.assertEqual(root.attrib,{'configVersion':'1'})
        self.assertEqual(root.find('ShellVisuals').get('DefaultDisplayName'),p['display_name'])
        self.assertEqual(root.find('ExecutableList/Executable').get('TargetDeviceFamily'),'PC')
        self.assertEqual(root.findtext('DesktopRegistration/ProcessorArchitecture'),'x64')
        self.assertIsNone(root.find('MSAAppId'));self.assertIsNone(root.find('TitleId'))
        self.assertIsNone(root.find('AdvancedUserModel'));self.assertIsNone(root.find('SaveGameStorage'))

    def test_input_payload_change_refused(self) -> None:
        (self.package/'content/1792.pck').write_bytes(b'changed')
        with self.assertRaises(ValueError): self.prepare()
        self.assertFalse(self.output.exists())

    def test_existing_output_preserved(self) -> None:
        self.prepare();before=(self.output/'stage.json').read_bytes()
        with self.assertRaises(ValueError): self.prepare()
        self.assertEqual(before,(self.output/'stage.json').read_bytes())

    def test_missing_logo_no_output(self) -> None:
        (self.assets/'StoreLogo.png').unlink()
        with self.assertRaises(ValueError): self.prepare()
        self.assertFalse(self.output.exists())

    def test_png_strict_shape_crc_and_bounds(self) -> None:
        for size in LOGOS.values(): png_check(png(size,6),size)
        for data in [b'',png(44)[:-1],png(44)+b'trailing',png(44).replace(b'IDAT',b'FAKE'),png(100),b'X'*1024*1025]:
            with self.subTest(length=len(data)),self.assertRaises(ValueError): png_check(data,44)

    def test_config_changed_even_with_rehash_refused(self) -> None:
        r=self.prepare();path=self.output/'loose/MicrosoftGame.config'
        data=path.read_bytes().replace(b'TargetDeviceFamily="PC"',b'TargetDeviceFamily="Scarlett"');path.write_bytes(data)
        r['files']['MicrosoftGame.config']={'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}
        (self.output/'stage.json').write_text(json.dumps(r))
        with self.assertRaises(ValueError): inspect_stage(self.output)

    def test_unexpected_or_missing_files(self) -> None:
        self.prepare();path=self.output/'loose/steam_api64.dll';path.write_bytes(b'not allowed')
        with self.assertRaises(ValueError): inspect_stage(self.output)
        path.unlink();(self.output/'loose/1792.exe').unlink()
        with self.assertRaises(ValueError): inspect_stage(self.output)

    def test_receipt_cannot_claim_approval(self) -> None:
        r=self.prepare()
        for key in ('makepkg_executed','submission_validated','store_uploaded','console_port','identity_assignment_verified'):
            (self.output/'stage.json').write_text(json.dumps(r | {key:True}))
            with self.subTest(key=key),self.assertRaises(ValueError): inspect_stage(self.output)

    def test_changed_loose_file_refused(self) -> None:
        self.prepare();p=self.output/'loose/1792.pck';p.write_bytes(p.read_bytes()[:-1]+b'X')
        with self.assertRaises(ValueError): inspect_stage(self.output)

    def test_plan_is_data_not_execution(self) -> None:
        self.prepare();tool=self.root/'makepkg.exe';tool.write_bytes(b'SYNTHETIC-NOT-EXECUTABLE')
        report=pack_pc(self.output,self.root/'packed',tool,hashlib.sha256(tool.read_bytes()).hexdigest())
        self.assertFalse(report['executed']);self.assertFalse((self.root/'packed').exists())
        self.assertEqual(report['commands'][0][1],'genmap');self.assertEqual(report['commands'][1][1],'pack')
        self.assertIn('/pc',report['commands'][1]);self.assertIn('/validationcritical',report['commands'][1])
        for forbidden in ('upload','/skipvalidation','/l','/lk','genkey','/msixvc2','/auth'):
            self.assertNotIn(forbidden, sum(report['commands'],[]))

    def test_changed_tool_hash_refused(self) -> None:
        self.prepare();tool=self.root/'makepkg.exe';tool.write_bytes(b'fixture')
        with self.assertRaises(ValueError): pack_pc(self.output,self.root/'packed',tool,'0'*64)
        self.assertFalse((self.root/'packed').exists())

    def test_output_cannot_pollute_inputs(self) -> None:
        with self.assertRaises(ValueError): stage_pc(self.package,self.profile,self.assets,self.package/'derived',**self.expected)
        self.assertFalse((self.package/'derived').exists())


if __name__=='__main__': unittest.main(verbosity=2)
