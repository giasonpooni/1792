"""Independent catalogue/production-boundary and acquisition-plan regression tests."""
from __future__ import annotations
import copy
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
import world_atlas as w


class WorldAtlasTests(unittest.TestCase):
    def setUp(self):
        self.world = w.load(w.WORLD)
        self.plan = w.load(w.PLAN)
    def refused(self, mutate):
        mutate(self.world)
        with self.assertRaises(w.CatalogueError): w.validate_world(self.world)
    def test_current_catalogues(self):
        w.validate_world(self.world); w.validate_plan(self.plan, self.world)
    def test_scale_not_compressed(self):
        self.refused(lambda d: d.update(metres_per_unit=100))
    def test_boolean_is_not_scale(self):
        self.refused(lambda d: d.update(metres_per_unit=True))
    def test_explicit_vertical_datum(self):
        self.refused(lambda d: d.update(geodetic_datum='EGM96'))
    def test_axis_order(self):
        self.refused(lambda d: d.update(coordinate_order=['latitude','longitude','height']))
    def test_duplicate_json(self):
        with self.assertRaises(w.CatalogueError): w.loads('{"schema":1,"schema":2}')
    def test_nonfinite_json(self):
        for text in ('NaN', 'Infinity', '-Infinity'):
            with self.subTest(text=text), self.assertRaises(w.CatalogueError): w.loads(text)
    def test_duplicate_places(self):
        self.refused(lambda d: d['places'].append(copy.deepcopy(d['places'][0])))
    def test_unresolved_source(self):
        self.refused(lambda d: d['places'][0].update(source_ids=['not_read']))
    def test_scope_required(self):
        self.refused(lambda d: d['sources'][0].update(scope=''))
    def test_rights_required(self):
        self.refused(lambda d: d['sources'][0].update(rights=''))
    def test_source_not_designer_precision(self):
        self.refused(lambda d: d['places'][0].update(placement_class='A'))
    def test_unknown_location_remains_unknown(self):
        self.refused(lambda d: d['places'][0].update(placement_class='D',anchor=[74,32]))
    def test_no_invented_footprint(self):
        self.refused(lambda d: d['places'][0].update(geometry={'footprint':[]}))
    def test_no_unbound_terrain(self):
        self.refused(lambda d: d.update(terrain_assets=[{'claim':'loaded'}]))
    def test_no_historical_presence_from_design(self):
        self.refused(lambda d: d['places'][0].update(periods=[{'from':1200,'until':1874,'source_ids':['design']}]))
    def test_no_automatic_importance_rank(self):
        self.refused(lambda d: d['places'][0].update(importance=[5]))
    def test_no_enterable_religious_site(self):
        self.refused(lambda d: d['religious_policy'].update(site_interiors=True))
    def test_no_embodied_religious_figure(self):
        self.refused(lambda d: d['religious_policy'].update(figures_embodied=True))
    def test_era_is_half_open(self):
        self.refused(lambda d: d.update(epoch={'from':1200,'until':1873}))
    def test_theatre_is_not_political_border(self):
        self.refused(lambda d: d['theatres'][0].update(classification='verified_state_border'))
    def test_theatre_in_envelope(self):
        self.refused(lambda d: d['theatres'][0].update(bounds=[65,23,84,38]))
    def test_rohtas_reference_not_survey(self):
        record=next(p for p in self.world['places'] if p['id']=='rohtas')
        self.assertIsNone(record['geometry']); self.assertIsNone(record['uncertainty_m'])
        self.assertAlmostEqual(record['anchor'][0],73+35/60+20/3600)
        self.assertAlmostEqual(record['anchor'][1],32+57/60+45/3600)
    def test_only_childhood_active(self):
        self.plan['campaigns'][2]['status']='active'
        with self.assertRaises(w.CatalogueError): w.validate_plan(self.plan,self.world)
    def test_sada_kaur_not_playable(self):
        self.plan['campaigns'][2]['protagonists']=['sada_kaur']
        with self.assertRaises(w.CatalogueError): w.validate_plan(self.plan,self.world)
    def test_adina_beg_not_playable(self):
        self.plan['campaigns'][2]['protagonists']=['adina_beg']
        with self.assertRaises(w.CatalogueError): w.validate_plan(self.plan,self.world)
    def test_unreviewed_associate_not_claimed(self):
        self.plan['campaigns'][2]['protagonists']=['jawahir_singh_nalwa']
        with self.assertRaises(w.CatalogueError): w.validate_plan(self.plan,self.world)
    def test_no_completed_campaign_from_catalogue(self):
        self.plan['campaigns'][0]['playable_content_ready']=True
        with self.assertRaises(w.CatalogueError): w.validate_plan(self.plan,self.world)
    def test_total_tile_envelope(self):
        result=w.tile_plan(self.world,hashlib.sha256(w.WORLD.read_bytes()).hexdigest())
        self.assertEqual(len(result['cells']),252)
        self.assertEqual(len({x['id'] for x in result['cells']}),252)
        expected={(x,y) for x in range(66,84) for y in range(24,38)}
        self.assertEqual({tuple(x['bounds'][:2]) for x in result['cells']},expected)
        self.assertTrue(all(x['status']=='missing' and x['asset_id'] is None and not x['historical_surface_admitted'] for x in result['cells']))
    def test_planning_is_detached_and_deterministic(self):
        before=copy.deepcopy(self.world); a=w.tile_plan(self.world,'a'*64); b=w.tile_plan(self.world,'a'*64)
        self.assertEqual(a,b); a['cells'][0]['status']='fabricated'
        self.assertEqual(self.world,before);self.assertEqual(b['cells'][0]['status'],'missing')
    def test_bound_content_digest(self):
        with self.assertRaises(w.CatalogueError): w.tile_plan(self.world,'unknown')
    def test_cli_creates_but_does_not_overwrite(self):
        with tempfile.TemporaryDirectory() as tmp:
            out=Path(tmp)/'tiles.json';cmd=[sys.executable,str(w.ROOT/'tools/world_atlas.py'),'--plan-tiles',str(out)]
            first=subprocess.run(cmd,capture_output=True,text=True,check=False)
            self.assertEqual(first.returncode,0,first.stderr)
            old=out.read_bytes();second=subprocess.run(cmd,capture_output=True,text=True,check=False)
            self.assertNotEqual(second.returncode,0);self.assertEqual(out.read_bytes(),old)
    def test_native_vectors_are_independent_and_synthetic(self):
        data=w.load(w.ROOT/'game/data/geodesy_vectors.v1.json')
        self.assertEqual(data['classification'],'synthetic:qualification')
        self.assertTrue(data['generator'].startswith('pyproj 3.7.2'))
        self.assertEqual(len(data['cases']),6)
    def test_retained_launch_is_extended_not_replaced(self):
        launch=(w.ROOT/'game/childhood/home_launch.gd').read_text()
        adapter=(w.ROOT/'game/geography/atlas_chapter.gd').read_text()
        self.assertIn('res://world/home_territory.tscn',launch)
        self.assertIn('const Chapter := preload("res://workshops/home_workshop_chapter.gd")',launch)
        self.assertIn('extends "res://presentation/art_chapter.gd"',
                      (w.ROOT / "game/workshops/home_workshop_chapter.gd").read_text())
        visual=(w.ROOT/'game/presentation/art_chapter.gd').read_text()
        self.assertIn('extends "res://geography/atlas_chapter.gd"',visual.splitlines())
        self.assertIn('super._ready()',visual)
        self.assertIn('extends "res://youth/brawl_chapter.gd"',adapter)
        self.assertNotIn('save_path=',adapter)


if __name__=='__main__': unittest.main()
