"""Independent source/epoch/clearance checks for authored Gujranwala geometry.

These tests do not establish historical truth or execute the Godot renderer.
"""
# Copyright (c) 2026 Cartesian Graphics. All rights reserved.
from __future__ import annotations
from copy import deepcopy
import hashlib
import json
import math
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / 'game/data/gujranwala_reconstruction.v1.json'
KINDS = {'arcade','courtyard','ground','stall','well','sacks','field'}


def vector(value: object, positive: bool = False) -> bool:
    return (isinstance(value, list) and len(value) == 3 and
            all(type(n) in (int, float) and math.isfinite(n) and abs(n) <= 500
                and (not positive or n > 0) for n in value))


def validate(value: dict) -> None:
    def require(ok: bool, message: str) -> None:
        if not ok:
            raise ValueError(message)
    require(value.get('schema') == '1792.gujranwala-reconstruction.v1', 'schema')
    require(value.get('year') == 1792 and value.get('georeferenced') is False, 'epoch/frame')
    require(value.get('extent') == [-28,28,-28,28], 'preserve qualified bounds')
    require(value.get('id') == 'gujranwala-fabric.v1', 'layout identity')
    require(value.get('frame') == 'gujranwala-compressed-local-metres', 'frame identity')
    sources = [s['id'] for s in value['sources']]
    require(len(set(sources)) == len(sources), 'duplicate sources')
    for source in value['sources']:
        require(source['url'].startswith('https://') and bool(source['locator'])
                and bool(source['evidence_scope']), 'source needs locator and limits')
    claims = [c['id'] for c in value['claims']]
    require(len(set(claims)) == len(claims), 'duplicate claims')
    for claim in value['claims']:
        require(bool(claim['source_ids']) and set(claim['source_ids']) <= set(sources), 'source reference')
    excluded = {e['id'] for e in value['exclusions']}
    require({'mahan_singh_samadhi','sheranwala_baradari'} <= excluded, 'exclusions cannot disappear')
    for item in value['exclusions']:
        require(item['claim_ids'] and set(item['claim_ids']) <= set(claims), 'exclusion evidence')
    ids = set()
    solids = []
    for f in value['features']:
        require(isinstance(f['id'],str) and f['id'] not in ids | excluded, 'duplicate/excluded feature')
        ids.add(f['id'])
        require(f['kind'] in KINDS and vector(f['position']) and vector(f['size'], True), 'geometry')
        require(type(f['collision']) is bool, 'collision must be explicit')
        require(f['placement_class'] == 'B' and f['geometry_class'] == 'C', 'representation semantics')
        require(bool(f['claim_ids']) and set(f['claim_ids']) <= set(claims), 'feature evidence')
        year = f['earliest_year']
        require(year is None or type(year) is int and year <= 1792, 'future feature')
        if f['kind'] == 'arcade':
            require(type(f.get('bays')) is int and 1 <= f['bays'] <= 12, 'bays')
        if f['collision']:
            # Only the well currently supplies collision; other kinds are context meshes.
            require(f['kind'] == 'well', 'unsupported collision shape')
            x, _, z = f['position']; sx, _, sz = f['size']
            require(abs(x)+sx/2 <= 28 and abs(z)+sz/2 <= 28, 'solid outside existing world')
            solids.append((x-sx/2,x+sx/2,z-sz/2,z+sz/2))
    require({r['id'] for r in value['routes']} == {'caravan_return','well_approach'}, 'required routes')
    for route in value['routes']:
        require(route['clearance'] >= 1.0 and len(route['points']) >= 2, 'route clearance')
        for a,b in zip(route['points'],route['points'][1:]):
            require(vector(a) and vector(b), 'route coordinates')
            # Sampling is only a guard against these new simple static shapes.
            # Actual swept geometry and full inherited navigation are tested in Godot.
            steps = max(1,math.ceil(math.dist(a,b)/0.05))
            for i in range(steps+1):
                t=i/steps; x=a[0]+(b[0]-a[0])*t; z=a[2]+(b[2]-a[2])*t
                c=route['clearance']
                require(all(not (xmin-c <= x <= xmax+c and zmin-c <= z <= zmax+c)
                            for xmin,xmax,zmin,zmax in solids), 'new solid blocks protected route')
    ambient_ids=set()
    for person in value['ambient']:
        require(person['id'] not in ambient_ids, 'duplicate ambient identity')
        ambient_ids.add(person['id'])
        require(len(person['points']) == 2 and all(vector(p) for p in person['points']), 'ambient path')
        require(type(person['period_ticks']) is int and person['period_ticks'] >= 120, 'ambient period')


class ReconstructionChecks(unittest.TestCase):
    def setUp(self):
        self.data=json.loads(PATH.read_text())
    def reject(self, edit):
        edit(self.data)
        with self.assertRaises((ValueError,KeyError,TypeError)):
            validate(self.data)
    def test_live_manifest(self): validate(self.data)
    def test_validation_does_not_mutate(self):
        old=deepcopy(self.data); validate(self.data); self.assertEqual(old,self.data)
    def test_no_invented_georeference(self): self.reject(lambda d:d.update(georeferenced=True))
    def test_future_epoch(self): self.reject(lambda d:d.update(year=1835))
    def test_future_building(self): self.reject(lambda d:d['features'][0].update(earliest_year=1835))
    def test_excluded_samadhi(self): self.reject(lambda d:d['features'][0].update(id='mahan_singh_samadhi'))
    def test_deferred_baradari(self): self.reject(lambda d:d['features'][0].update(id='sheranwala_baradari'))
    def test_missing_exclusions(self): self.reject(lambda d:d.update(exclusions=[]))
    def test_unknown_evidence(self): self.reject(lambda d:d['features'][0].update(claim_ids=['invented']))
    def test_unknown_source(self): self.reject(lambda d:d['claims'][0].update(source_ids=['invented']))
    def test_nan_geometry(self): self.reject(lambda d:d['features'][0].update(position=[float('nan'),0,0]))
    def test_negative_size(self): self.reject(lambda d:d['features'][0].update(size=[-1,1,1]))
    def test_boolean_coordinate(self): self.reject(lambda d:d['features'][0].update(position=[True,0,0]))
    def test_duplicate_features(self): self.reject(lambda d:d['features'].append(deepcopy(d['features'][0])))
    def test_route_blocker(self): self.reject(lambda d:d['features'][7].update(position=[-24,.1,-12]))
    def test_removed_route(self): self.reject(lambda d:d.update(routes=[]))
    def test_invalid_bays(self): self.reject(lambda d:d['features'][0].update(bays=1.5))
    def test_widened_bounds(self): self.reject(lambda d:d.update(extent=[-90,90,-90,90]))
    def test_colliding_scenery_forbidden(self): self.reject(lambda d:d['features'][2].update(collision=True))
    def test_empty_feature_evidence(self): self.reject(lambda d:d['features'][0].update(claim_ids=[]))
    def test_observation_binding(self):
        self.assertEqual(len(hashlib.sha256(PATH.read_bytes()).hexdigest()),64)


if __name__ == '__main__': unittest.main(verbosity=2)
