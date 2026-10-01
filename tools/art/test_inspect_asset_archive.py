"""Synthetic and optional real-package checks for the read-only intake inspector."""
from __future__ import annotations

import hashlib
import io
import json
import re
from pathlib import Path
import stat
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import warnings
import zipfile

from inspect_asset_archive import inspect, inspect_blend, checked_name


def fixture(pointer: int = 8, endian: str = '<') -> bytes:
    names = ['name[32]', '*packedfile', 'totvert', 'totedge', 'totface', 'totpoly']
    types = ['char', 'void', 'int', 'Library', 'Image', 'Mesh']
    sizes = [1, 0, 4, 32, 32 + pointer, 16]
    def integer(n, fmt='I'): return struct.pack(endian + fmt, n)
    dna = bytearray(b'SDNANAME' + integer(len(names)))
    for name in names: dna.extend(name.encode()+b'\0')
    dna.extend(b'\0' * (-len(dna) % 4)); dna.extend(b'TYPE'+integer(len(types)))
    for name in types: dna.extend(name.encode()+b'\0')
    dna.extend(b'\0' * (-len(dna) % 4)); dna.extend(b'TLEN')
    for n in sizes: dna.extend(integer(n, 'H'))
    dna.extend(b'\0' * (-len(dna) % 4)); dna.extend(b'STRC'+integer(3))
    for typ, fields in [(3, [(0,0)]), (4, [(0,0),(1,1)]), (5,[(2,i) for i in range(2,6)])]:
        dna.extend(integer(typ, 'H')+integer(len(fields), 'H'))
        for typ, name in fields: dna.extend(integer(typ,'H')+integer(name,'H'))
    def block(code, value, schema=0):
        return struct.pack(endian+'4sI'+('Q' if pointer == 8 else 'I')+'II', code, len(value), 0, schema, 1)+value
    return (b'BLENDER'+(b'-' if pointer == 8 else b'_')+(b'v' if endian=='<' else b'V')+b'270'
            +block(b'LI', b'//private/trees.blend\0'.ljust(32,b'\0'), 0)
            +block(b'IM', b'/private/albedo.png\0'.ljust(32,b'\0')+(1).to_bytes(pointer,'little' if endian=='<' else 'big'), 1)
            +block(b'ME', struct.pack(endian+'4i', 12,24,0,6), 2)
            +block(b'DNA1', bytes(dna))+block(b'ENDB', b''))


class InspectionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.root = Path(self.tmp.name)
    def tearDown(self): self.tmp.cleanup()
    def archive(self, items=None):
        p = self.root/'input.zip'
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', UserWarning)
            with zipfile.ZipFile(p, 'w', zipfile.ZIP_DEFLATED) as z:
                for name, value in items or [('source.blend', fixture()),('LICENSE.txt',b'Fixture only')]:
                    z.writestr(name, value)
        return p
    def test_valid_endian_and_pointer_matrix(self):
        for pointer in (4, 8):
            for endian in ('<','>'):
                with self.subTest(pointer=pointer,endian=endian):
                    d=inspect_blend(fixture(pointer,endian))
                    self.assertEqual(d['libraries'],[{'basename':'trees.blend','resolved':False}])
                    self.assertEqual(d['images'][0]['basename'],'albedo.png')
                    self.assertTrue(d['images'][0]['legacy_packedfile_pointer_nonzero'])
                    self.assertEqual(d['mesh_totals_saved_not_evaluated']['totvert'],12)
    def test_no_source_mutation_or_extraction(self):
        p=self.archive();before=p.read_bytes();d=inspect(p)
        self.assertEqual(p.read_bytes(),before);self.assertEqual(list(self.root.iterdir()),[p])
        self.assertEqual(d['archive_sha256'],hashlib.sha256(before).hexdigest())
        self.assertFalse(d['runtime_admission']);self.assertFalse(d['source_files_executed'])
        self.assertTrue(all(m['crc_checked'] for m in d['members']))
    def test_unsafe_member_names(self):
        for n in ('../escape','/absolute','C:/bad','a\\b','a/../b','a//b','./bad','a\nb'):
            with self.subTest(n=n),self.assertRaises(ValueError):inspect(self.archive([(n,b'x')]))
    def test_duplicate_names(self):
        with self.assertRaises(ValueError):inspect(self.archive([('A',b'x'),('a',b'y')]))
    def test_symlink_member(self):
        info=zipfile.ZipInfo('link');info.create_system=3;info.external_attr=(stat.S_IFLNK|0o777)<<16
        with self.assertRaises(ValueError):inspect(self.archive([(info,b'/elsewhere')]))
    def test_encrypted_member(self):
        p=self.archive([('payload',b'x')]);raw=bytearray(p.read_bytes())
        for sig,offset in ((b'PK\x03\x04',6),(b'PK\x01\x02',8)):
            pos=raw.index(sig)+offset;struct.pack_into('<H',raw,pos,1)
        p.write_bytes(raw)
        with self.assertRaises(ValueError):inspect(p)
    def test_input_symlink(self):
        p=self.archive();link=self.root/'link.zip';link.symlink_to(p)
        with self.assertRaises(ValueError):inspect(link)
    def test_byte_and_member_budgets(self):
        p=self.archive()
        for key in ('MAX_ARCHIVE','MAX_TOTAL','MAX_MEMBER','MAX_MEMBERS'):
            with patch('inspect_asset_archive.'+key,1),self.assertRaises(ValueError):inspect(p)
    def test_corrupt_crc(self):
        p=self.archive([('file',b'abc')]);raw=bytearray(p.read_bytes());pos=raw.index(b'PK\x01\x02')+16
        struct.pack_into('<I',raw,pos,0);p.write_bytes(raw)
        with self.assertRaises(zipfile.BadZipFile):inspect(p)
    def test_blend_invalid_header(self):
        for raw in (b'',b'BLENDER',b'not_a_blend!',b'\x1f\x8b'+fixture()):
            with self.subTest(raw=raw[:12]),self.assertRaises(ValueError):inspect_blend(raw)
    def test_blend_incomplete_trailing_or_bad_dna(self):
        for raw in (fixture()[:-1],fixture()+b'x',fixture().replace(b'SDNANAME',b'BADDNAME',1)):
            with self.assertRaises(ValueError):inspect_blend(raw)
    def test_blend_wrong_schema_type(self):
        raw=bytearray(fixture());struct.pack_into('<I',raw,12+16,2)
        with self.assertRaises(ValueError):inspect_blend(raw)
    def test_blend_block_and_dna_budgets(self):
        with patch('inspect_asset_archive.MAX_BLOCKS',2),self.assertRaises(ValueError):inspect_blend(fixture())
        with patch('inspect_asset_archive.MAX_DNA_ITEMS',2),self.assertRaises(ValueError):inspect_blend(fixture())
    def test_target_count_and_negative_mesh_totals(self):
        raw=bytearray(fixture());struct.pack_into('<I',raw,12+20,2)
        with self.assertRaises(ValueError):inspect_blend(raw)
        raw=fixture().replace(struct.pack('<4i',12,24,0,6),struct.pack('<4i',-1,24,0,6),1)
        with self.assertRaises(ValueError):inspect_blend(raw)
    def test_unsupported_compression(self):
        p=self.root/'bzip.zip'
        with zipfile.ZipFile(p,'w',zipfile.ZIP_BZIP2) as z:z.writestr('payload',b'x')
        with self.assertRaises(ValueError):inspect(p)
    def test_directory_payload(self):
        with self.assertRaises(ValueError):inspect(self.archive([('folder/',b'not empty')]))
    def test_cli_invalid_source_does_not_create_output(self):
        p=self.archive([('../bad',b'x')]);out=self.root/'absent.json'
        result=subprocess.run([sys.executable,str(Path(__file__).with_name('inspect_asset_archive.py')),str(p),'--output',str(out)],capture_output=True,timeout=10)
        self.assertEqual(result.returncode,2);self.assertFalse(out.exists())
    def test_cli_creates_new_report_and_refuses_overwrite(self):
        p=self.archive();out=self.root/'report.json'
        cmd=[sys.executable,str(Path(__file__).with_name('inspect_asset_archive.py')),str(p),'--output',str(out)]
        r=subprocess.run(cmd,capture_output=True,timeout=10);self.assertEqual(r.returncode,0,r.stderr)
        raw=out.read_bytes();self.assertEqual(json.loads(raw)['archive_name'],'input.zip')
        r=subprocess.run(cmd,capture_output=True,timeout=10);self.assertEqual(r.returncode,2)
        self.assertEqual(raw,out.read_bytes())



class RetainedIntakeTests(unittest.TestCase):
    """Consistency checks on source observations; not a reinspection of absent ZIPs."""
    @classmethod
    def setUpClass(cls):
        cls.root = Path(__file__).resolve().parents[2]
        cls.path = cls.root / 'data/art_intake/map_architecture_20260929.json'
        cls.data = json.loads(cls.path.read_text(encoding='utf-8'))

    def test_reference_ids_and_source_links(self):
        d = self.data
        sources = {s['id'] for s in d['sources']}
        self.assertEqual(len(sources), len(d['sources']))
        entries = d['images'] + d['archives'] + d['caption_leads']
        self.assertEqual(len({e['id'] for e in entries}), len(entries))
        for e in entries:
            self.assertTrue(set(e.get('source_ids', [])).issubset(sources), e['id'])
        for e in d['images'] + d['archives']:
            self.assertRegex(e['sha256'], r'^[0-9a-f]{64}$')
            self.assertGreater(e['bytes'], 0)
            self.assertFalse(e['raw_file_committed'])

    def test_inspector_and_report_content_bindings(self):
        d = self.data
        tool = self.root / d['inspector']['path']
        self.assertEqual(hashlib.sha256(tool.read_bytes()).hexdigest(), d['inspector']['sha256'])
        for item in d['archives']:
            raw = (self.path.parent / item['inspection_report']).read_bytes()
            self.assertEqual(hashlib.sha256(raw).hexdigest(), item['inspection_report_sha256'])
            report = json.loads(raw)
            self.assertEqual(report['archive_sha256'], item['sha256'])
            self.assertEqual(report['archive_bytes'], item['bytes'])
            self.assertEqual(report['archive_name'], item['filename'])
            self.assertEqual(report['expanded_bytes'], sum(m['bytes'] for m in report['members']))
            self.assertTrue(all(m['crc_checked'] for m in report['members']))
            self.assertFalse(report['source_files_executed'])
            self.assertFalse(report['files_extracted'])
            self.assertFalse(report['runtime_admission'])

    def test_missing_dependencies_are_not_claimed_present(self):
        d = self.data
        grass = next(a for a in d['archives'] if a['id'] == 'PACK02')
        report = json.loads((self.path.parent / grass['inspection_report']).read_text())
        blend = next(m['blend'] for m in report['members'] if 'blend' in m)
        self.assertEqual({v['basename'] for v in blend['libraries']}, {'Shrubs6.blend', 'Boulders.blend'})
        self.assertTrue(all(not v['resolved'] for v in blend['libraries']))
        self.assertFalse(grass['render_qualified'])
        self.assertFalse(grass['runtime_admitted'])

    def test_date_roles_and_unmatched_caption_pixels(self):
        captions = {c['id']: c for c in self.data['caption_leads']}
        funeral = captions['CAPTION01']; fort = captions['CAPTION02']
        self.assertEqual(funeral['depicted_event_year'], 1839)
        self.assertEqual(funeral['artwork_date'], {'year': 1840, 'qualifier': 'circa'})
        self.assertEqual(fort['photograph_date'], {'from': 1858, 'through': 1861})
        self.assertEqual(fort['fort_conversion_date_source_reported'], {'from': 1809, 'through': 1812})
        for c in captions.values():
            self.assertFalse(c['pixels_matched']); self.assertIsNone(c['sha256'])
            self.assertFalse(c['source_image_acquired']); self.assertFalse(c['runtime_admitted'])
        self.assertEqual(self.data['protected_scope']['terrain_cells_promoted'], 0)

    def test_intake_relative_document_targets_exist(self):
        path = self.root / 'docs/MAP_ARCHITECTURE_INTAKE.md'
        for target in re.findall(r'\]\(([^)]+)\)', path.read_text()):
            if '://' not in target and not target.startswith('#'):
                self.assertTrue((path.parent / target.split('#')[0]).is_file(), target)


if __name__=='__main__': unittest.main()
