"""Recheck the retained game observations without launching a game or a NET provider.

This validates the declared bounded integration, not an authenticated human playtest,
all possible contacts, or historical correctness. Original game tests remain separate.
"""
from __future__ import annotations
import argparse
from copy import deepcopy
import hashlib
import json
import math
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
ASSET='60ea4b4657f9c73d12c956e20498e99afa0f892a7b3167ecb033c53d3ec50736'
SOURCE='edcb0b2f09ccd351de3e977dec1c1a910d021cd3'

def require(condition: bool, message: str) -> None:
    if not condition: raise ValueError(message)

def vector(value: object) -> list[float]:
    require(isinstance(value,list) and len(value)==3,'three-coordinate vector required')
    require(all(type(x) in (int,float) and math.isfinite(x) for x in value),'nonfinite vector')
    return value

def near(a, b, tolerance=1e-5):
    return len(a)==len(b) and all(abs(x-y)<=tolerance for x,y in zip(a,b))

def asset_identity(raw: bytes, provenance: dict) -> None:
    require(len(raw)==11076 and hashlib.sha256(raw).hexdigest()==ASSET,'not the accepted GLB')
    require(provenance['asset_sha256']=='sha256:'+ASSET,'provenance asset mismatch')
    require(provenance['source_worker']['commit']==SOURCE,'wrong producing revision')
    require(provenance['source_acceptance']['asset_sha256']=='sha256:'+ASSET,'different accepted primary')
    require(provenance['source_acceptance']['parent_task_acceptance']=='not_performed','upstream acceptance is not art approval')
    require(provenance['consumer_collision']['owner']=='1792','collision must remain game-owned')
    require(provenance['historical_class']=='original_fictional_blockout','do not invent historical evidence')

def inspect(data: dict) -> dict:
    require(data['schema']=='1792.accepted-bench-gameplay.v1','unsupported observations')
    require(data['engine']=='4.5.1-stable (official)' and data['physics_hz']==60,'wrong engine/physics profile')
    require(data['failed']==0 and data['passed']>=100 and data['dropped']==0,'incomplete native check campaign')
    g=data['metrics']['geometry']
    require(g['asset_sha256']==ASSET and g['parts']==9 and g['triangles']==108,'wrong in-engine mesh')
    require(near(g['min'],[-.9,0,-.35]) and near(g['size'],[1.8,.9,.7]),'altered imported geometry')
    require(near(g['position'],[-46,.132,-5.4]) and abs(g['tool_underside_y']-.905)<1e-5,'placement or tool support changed')
    require(len(data['metrics']['collisions'])==4,'missing side collision observations')
    for c in data['metrics']['collisions']:
        p,offset=vector(c['end_local']),vector(c['start_offset'])
        require(c['bench_contact'] is True,'no real bench contact recorded')
        axis=0 if offset[0] else 2
        require(p[axis]*math.copysign(1,offset[axis])> (1.24 if axis==0 else .69),'player crossed collision boundary')
        require(abs(p[1])<.04,'collision raised player to top')
    access=data['metrics']['access']
    require(access['stale_collect_before']==access['stale_collect_after'],'late obstruction changed live state')
    stages=data['stages'];require(set(stages)=={'initial','ready','carried','delivered'},'missing played stage')
    first=stages['initial']['misl']['ledger'];last=stages['delivered']['misl']['ledger']
    require(first['watch']==last['watch']==0,'this bounded route unexpectedly incurred a supply watch')
    require(last['treasury']==first['treasury']-4 and last['purse']==first['purse'],'money was created or double spent')
    expected=dict(first['stock']);expected['timber']-=2;expected['tools']+=2
    require(last['stock']==expected,'incorrect custody/stock settlement')
    for stage,phase in [('ready','ready'),('carried','tools'),('delivered','complete')]:
        s=stages[stage]['misl']['ledger'];require(s['workshop']['phase']==phase,'wrong custody phase')
        require(s['stock']['tools']==first['stock']['tools']+(2 if stage=='delivered' else 0),'credit before physical delivery')
    events=[e for e in stages['delivered']['misl']['events'] if e['kind'].startswith('smith.')]
    require([e['kind'] for e in events]==['smith.reserve','smith.start','smith.ready','smith.collect','smith.deliver'],'missing or duplicated workshop transition')
    require(events[2]['tick']-events[1]['tick']==600,'workshop production timer changed')
    samples=data['trace'];require(isinstance(samples,list) and 500<len(samples)<20000,'incomplete movement trace')
    minimum=math.inf;max_step=0.0;epochs=set();previous=None
    for i,s in enumerate(samples):
        require(s['sample']==i and type(s['tick']) is int and type(s['epoch']) is int,'invalid sample identity')
        p=vector(s['position']);vector(s['velocity']);epochs.add(s['epoch'])
        # Exact full-height capsule's horizontal cross section against the authored box.
        dx=max(0,abs(p[0]+46)-.9);dz=max(0,abs(p[2]+5.4)-.35)
        gap=math.hypot(dx,dz);minimum=min(minimum,gap)
        require(gap>=.345,'observed player capsule penetrates the bench footprint')
        if previous is not None and s['epoch']==previous['epoch']:
            dt=s['tick']-previous['tick'];require(dt>0,'clock rewound without a new restore epoch')
            displacement=math.dist([p[0],p[2]],[previous['position'][0],previous['position'][2]])
            require(displacement<=7.5*dt/60+.06,'unexplained position jump in an uninterrupted epoch')
            max_step=max(max_step,displacement/dt)
        previous=s
    require(epochs=={0,1,2},'expected both real whole-world save restores')
    require({'fuel','working','ready','tools'}<=set(s['phase'] for s in samples),'missing actual task phases')
    return {'schema':'1792.workbench-observation-check.v1','status':'passed','samples':len(samples),
        'restore_epochs':sorted(epochs),'min_horizontal_capsule_center_distance_to_box_m':minimum,
        'max_horizontal_step_per_recorded_tick_m':max_step,'asset_sha256':ASSET,
        'physics_hz':60,'native_assertions':data['passed'],'independent_gameplay_recheck':True,
        'fresh_game_execution':False,'human_playtest':False,'release_authorized':False,
        'scope':'recorded input-journey/collision/custody consistency; not hostile-host authentication'}

class ArtifactIdentityTests(unittest.TestCase):
    def setUp(self):
        self.raw=(ROOT/'game/assets/props/workbench.glb').read_bytes()
        self.p=json.loads((ROOT/'game/assets/props/workbench.provenance.json').read_text())
    def test_exact_asset(self): asset_identity(self.raw,self.p)
    def test_changed_byte(self):
        with self.assertRaises(ValueError): asset_identity(self.raw[:-1]+bytes([self.raw[-1]^1]),self.p)
    def test_missing_bytes(self):
        with self.assertRaises(ValueError): asset_identity(b'',self.p)
    def test_different_primary(self):
        self.p['source_acceptance']['asset_sha256']='sha256:'+'0'*64
        with self.assertRaises(ValueError): asset_identity(self.raw,self.p)
    def test_no_art_approval(self):
        self.p['source_acceptance']['parent_task_acceptance']='approved'
        with self.assertRaises(ValueError): asset_identity(self.raw,self.p)
    def test_no_historical_relabel(self):
        self.p['historical_class']='documented_antique'
        with self.assertRaises(ValueError): asset_identity(self.raw,self.p)
    def test_world_collision_owner(self):
        self.p['consumer_collision']['owner']='NET'
        with self.assertRaises(ValueError): asset_identity(self.raw,self.p)
    def test_no_embedded_runtime_scripts(self):
        import struct
        length=struct.unpack_from('<I',self.raw,12)[0];doc=json.loads(self.raw[20:20+length])
        self.assertNotIn('extensions',doc);self.assertNotIn('extensionsUsed',doc)
        self.assertNotIn('animations',doc);self.assertNotIn('images',doc)
        for b in doc['buffers']:self.assertNotIn('uri',b)

if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--evidence',type=Path)
    args=ap.parse_args()
    if args.evidence:
        print(json.dumps(inspect(json.loads(args.evidence.read_text())),indent=2,allow_nan=False))
    else:
        suite=unittest.defaultTestLoader.loadTestsFromTestCase(ArtifactIdentityTests)
        raise SystemExit(0 if unittest.TextTestRunner(verbosity=2).run(suite).wasSuccessful() else 1)
