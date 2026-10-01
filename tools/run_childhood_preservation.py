"""Run inherited childhood and received-memory projection boundaries."""
from pathlib import Path
import argparse,json,subprocess,re,hashlib
ROOT=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser();p.add_argument('--godot',required=True);args=p.parse_args()
 out=ROOT/'test-results/childhood-preservation';out.mkdir(parents=True,exist_ok=True)
 def run(name,extra,marker=None):
  r=subprocess.run([args.godot,'--headless','--fixed-fps','60','--path',str(ROOT/'game'),*extra],text=True,capture_output=True,timeout=90)
  log=r.stdout+r.stderr;(out/(name+'.log')).write_text(log);print(log)
  if r.returncode or re.search(r'(?m)^(?:SCRIPT ERROR|ERROR):',log):raise ValueError(name+' failed')
  if marker and marker not in log:raise ValueError('Completion marker missing')
 run('import',['--editor','--import'])
 run('childhood',['--script','res://tests/test_childhood.gd'],'110 passed, 0 failed')
 run('perspective',['--script','res://tests/test_perspective_view.gd'],'8 passed, 0 failed')
 # The standalone game qualification uses a Git commit as its source lock.
 # NET production separately computes a full content lock over game/data bytes.
 commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
 request=out/'request.json';request.write_text(json.dumps({'nonce':'hosted-childhood-qualification','source_lock_id':commit}))
 run('capture',['--script','res://foundry/childhood_slice.gd','--',str(request),str(out/'observations.json')],'50 passed, 0 failed')
 d=json.loads((out/'observations.json').read_text());assert len(d['samples'])==13 and d['failures']==0
 (out/'qualification.json').write_text(json.dumps({'source_commit':commit,'engine_sha256':hashlib.sha256(Path(args.godot).read_bytes()).hexdigest(),'samples':13,'historical_authentication':False,'human_playability_review':False},indent=2))
 return 0
if __name__=='__main__':raise SystemExit(main())
