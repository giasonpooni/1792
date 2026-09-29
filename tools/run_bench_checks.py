"""Keep all inherited checks, then qualify the accepted bench in the real workshop."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import uuid
from run_checks import run
from check_bench_artifact import inspect

ROOT=Path(__file__).resolve().parents[1]

def main() -> int:
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--godot',default=shutil.which('godot') or shutil.which('godot4'))
    args=ap.parse_args()
    if not args.godot:raise ValueError('Godot unavailable; native integration NOT RUN')
    subprocess.run([sys.executable,'tools/run_checks.py','--godot',args.godot],cwd=ROOT,check=True)
    run([sys.executable,'tools/check_bench_artifact.py'],'bench-artifact')
    run([args.godot,'--headless','--fixed-fps','60','--path','game','--script','res://tests/test_workbench_integration.gd'],
        'bench-integration','BENCH_INTEGRATION_TESTS:')
    log=(ROOT/'test-results/bench-integration.log').read_text()
    match=re.search(r'(?m)^BENCH_EVIDENCE: (.+)$',log)
    if not match:raise ValueError('Native test produced no artifact location')
    raw=Path(match[1].strip()).read_bytes()
    if len(raw)>8*1024*1024:raise ValueError('Gameplay evidence exceeds bound')
    data=json.loads(raw);recheck=inspect(data)
    # Challenge the separate rechecker with altered retained observations.
    from copy import deepcopy
    variants={}
    for fault in ('asset','part_count','teleport','money','early_stock','duplicate_settlement','unmarked_rewind','late_obstruction'):
        bad=deepcopy(data)
        if fault=='asset':bad['metrics']['geometry']['asset_sha256']='0'*64
        elif fault=='part_count':bad['metrics']['geometry']['parts']=8
        elif fault=='teleport':bad['trace'][100]['position'][0]+=10
        elif fault=='money':bad['stages']['delivered']['misl']['ledger']['treasury']+=1
        elif fault=='early_stock':bad['stages']['ready']['misl']['ledger']['stock']['tools']+=2
        elif fault=='duplicate_settlement':bad['stages']['delivered']['misl']['events'].append(bad['stages']['delivered']['misl']['events'][-1])
        elif fault=='unmarked_rewind':
            for s in bad['trace']:s['epoch']=0
        elif fault=='late_obstruction':bad['metrics']['access']['stale_collect_after']['misl']['ledger']['stock']['tools']+=1
        try:inspect(bad)
        except ValueError:variants[fault]='refused'
        else:raise ValueError('Rechecker accepted altered observations: '+fault)
    out=ROOT/'test-results';(out/'bench-gameplay.json').write_bytes(raw)
    sources={}
    # Includes importer settings and unchanged simulation code; no .godot caches.
    for folder in ['game','tools']:
        for p in sorted((ROOT/folder).rglob('*')):
            if p.is_file() and '.godot' not in p.parts and '__pycache__' not in p.parts and not p.name.endswith('.uid'):
                sources[p.relative_to(ROOT).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
    report={'schema':'1792.bench-integration-check.v1','execution_id':uuid.uuid4().hex,
        'operation_id':'workshop-bench-integration-check.v1','native_evidence_sha256':hashlib.sha256(raw).hexdigest(),
        'godot_executable_sha256':hashlib.sha256(Path(args.godot).read_bytes()).hexdigest(),
        'source_sha256':sources,'observation_recheck':recheck,'altered_observation_checks':variants,
        'publication':'not_performed','state_admission':'not_performed','human_playtests':0}
    (out/'bench-verification.json').write_text(json.dumps(report,indent=2)+'\n')
    print('BENCH_RECHECK: observed gameplay passed; 8 altered-observation cases refused')
    return 0

if __name__=='__main__':
    try:raise SystemExit(main())
    except (ValueError,OSError,RuntimeError,TypeError,KeyError,subprocess.SubprocessError) as error:
        print(error,file=sys.stderr);raise SystemExit(1)
