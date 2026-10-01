"""Source/asset contracts; not a certificate of artistic or historical fidelity."""
from __future__ import annotations
import hashlib,json,struct,tempfile,unittest
from pathlib import Path
from inspect_stl import inspect
from capture_home_art import max_numeric_error
ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'game/assets/courtyard'

def glb(path):
    raw=path.read_bytes()
    if raw[:4]!=b'glTF' or struct.unpack_from('<II',raw,4)!=(2,len(raw)): raise ValueError('Invalid GLB')
    n,kind=struct.unpack_from('<II',raw,12)
    if kind!=0x4e4f534a: raise ValueError('No JSON chunk')
    return json.loads(raw[20:20+n])

class CourtyardContracts(unittest.TestCase):
    def test_asset_identity(self):
        r=json.loads((ASSETS/'build.json').read_text());self.assertFalse(r['georeferenced']);self.assertFalse(r['historically_verified'])
        for a in r['assets']:
            self.assertEqual(hashlib.sha256((ASSETS/a['file']).read_bytes()).hexdigest(),a['sha256'])
            self.assertLess((ASSETS/a['file']).stat().st_size,2*1024*1024)
        self.assertEqual(r['generator_sha256'],hashlib.sha256((ROOT/'tools/art/build_courtyard.py').read_bytes()).hexdigest())
    def test_bundled_geometry(self):
        for name in ['courtyard_bay','childhood_costume']:
            data=glb(ASSETS/(name+'.glb'));self.assertEqual(len(data['meshes']),1)
            for b in data['buffers']: self.assertNotIn('uri',b)
            self.assertFalse(data.get('images'))
            for n in data['nodes']: self.assertFalse(n.get('name','').endswith(('-col','-colonly','-navmesh')))
    def test_named_rig(self):
        d=glb(ASSETS/'childhood_costume.glb');self.assertEqual(len(d['skins']),1)
        self.assertEqual({d['nodes'][j]['name'] for j in d['skins'][0]['joints']},{'pelvis','spine','head','upper_legL','lower_legL','upper_legR','lower_legR','upper_armL','forearmL','upper_armR','forearmR'})
        for p in d['meshes'][0]['primitives']: self.assertIn('JOINTS_0',p['attributes']);self.assertIn('WEIGHTS_0',p['attributes'])
    def test_surface_rights_and_content(self):
        root=ROOT/'game/assets/surfaces';r=json.loads((root/'sources.json').read_text());self.assertEqual(r['license'],'CC0-1.0');self.assertFalse(r['historical_evidence']);self.assertEqual(len(r['files']),6)
        for e in r['files']:
            self.assertEqual(Path(e['file']).name,e['file']);b=(root/e['file']).read_bytes()
            self.assertEqual(hashlib.sha256(b).hexdigest(),e['sha256']);self.assertEqual(b[:8],b'\x89PNG\r\n\x1a\n');self.assertEqual(struct.unpack('>II',b[16:24]),(1024,1024));self.assertFalse(e['historical_evidence'])
    def test_import_settings_preserve_close_detail(self):
        self.assertIn('meshes/generate_lods=false',(ASSETS/'childhood_costume.glb.import').read_text())
        for p in (ROOT/'game/assets/surfaces').glob('*.import'):
            self.assertIn('mipmaps/generate=true',p.read_text())
            self.assertIn('detect_3d/compress_to=0',p.read_text())
    def test_original_home(self):
        self.assertEqual(hashlib.sha256((ROOT/'game/world/home_territory.tscn').read_bytes()).hexdigest(),'383ef8004ca41c84c084801f2ddb4a57f1730f66206f58cf32be7c3e1f2fb5c0')
    def test_one_game_clock(self):
        for name in ['courtyard_art.gd','courtyard_detail.gd','courtyard_hud.gd']:
            s=(ROOT/'game/presentation'/name).read_text()
            for f in ['func _physics_process(', 'func _process(', 'Timer.new','HTTPRequest','model.restore','model.operate','model.advance']: self.assertNotIn(f,s)
        self.assertNotIn('TIME',(ROOT/'game/presentation/courtyard_surface.gdshader').read_text())
    def test_same_workbench_entry(self):
        s=(ROOT/'tools/capture_home_art.py').read_text();self.assertIn('default="home"',s);self.assertIn('exist_ok=False',s);self.assertIn('camera_basis',s)
        self.assertIn('extends "res://presentation/home_art.gd"',(ROOT/'game/presentation/courtyard_art.gd').read_text())
    def test_native_tests_and_recording(self):
        s=(ROOT/'game/tests/test_courtyard.gd').read_text()
        for x in ['noncollapsed finite bone','input body blocked by pier','same tick same pose','whole-run load']: self.assertIn(x,s)
        self.assertIn('recorded-input-observation-replay',(ROOT/'game/tests/render_courtyard_walk.gd').read_text())
    def test_reference_intake_not_assets(self):
        r=json.loads((ROOT/'data/art_intake/reference_batch_20260929.json').read_text())
        self.assertTrue(r['user_direction']['ranjit_default_face_uncovered']);self.assertFalse(r['historical_admission'])
        self.assertFalse(r['stl']['runtime_admission']);self.assertEqual(r['stl']['triangles'],914973)
        self.assertEqual(len({i['sha256'] for i in r['images']}),len(r['images']))
        self.assertFalse((ROOT/'game/assets/desert_cavalier.stl').exists())
    def test_replay_numeric_tolerance(self):
        self.assertEqual(max_numeric_error([1,2],[1,2]),0);self.assertLess(max_numeric_error([1,2],[1,2.0000001]),1e-5)
        self.assertGreater(max_numeric_error([1,2],[1,2.001]),1e-5);self.assertEqual(max_numeric_error([1],[1,2]),float('inf'))
        self.assertEqual(max_numeric_error(float('nan'),0),float('inf'))
    def test_stl_inspection_is_not_promotion(self):
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory)/'test.stl';raw=bytes(80)+struct.pack('<I',1)+struct.pack('<12fH',0,0,1,0,0,0,1,0,0,0,1,0,0);p.write_bytes(raw)
            r=inspect(p);self.assertEqual(r['triangles'],1);self.assertFalse(r['runtime_admission']);self.assertFalse(r['redistribution'])
            p.write_bytes(raw[:-1])
            with self.assertRaises(ValueError): inspect(p)
            p.write_bytes(bytes(80)+struct.pack('<I',1)+struct.pack('<12fH',0,0,1,float('nan'),0,0,1,0,0,0,1,0,0))
            with self.assertRaises(ValueError): inspect(p)

if __name__=='__main__':unittest.main(verbosity=2)
