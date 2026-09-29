"""Compare real Godot producer/consumer processes, not a second movement model."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ["game/player/player.gd", "game/player/locomotion_rules.gd",
           "game/player/traversal_probe.gd", "game/player/traversal_record.gd",
           "game/player/two_bone_ik.gd", "game/player/locomotion_proxy.gd",
           "game/mechanics/course.gd", "game/mechanics/course_layout.json",
           "game/tests/test_contact_restart.gd", "tools/check_contact_restart.py"]


def digest(value: object) -> str:
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"),
                                     allow_nan=False).encode()).hexdigest()


def run_engine(godot: str, mode: str, kind: str, segment: int, rate: int,
               output: Path) -> dict:
    env = dict(os.environ, CONTACT_RESTART_MODE=mode, CONTACT_RESTART_KIND=kind,
               CONTACT_RESTART_SEGMENT=str(segment), CONTACT_RESTART_RATE=str(rate))
    proc = subprocess.run([godot, "--headless", "--fixed-fps", str(rate), "--path", "game",
                           "--script", "res://tests/test_contact_restart.gd"], cwd=ROOT,
                          env=env, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, check=False, timeout=60)
    label = f"{kind}-{segment}-{mode}-{rate}"
    (output / f"{label}.log").write_text(proc.stdout, encoding="utf-8")
    print(proc.stdout)
    match = re.search(r"(?m)^CONTACT_RESTART_FILE: (.+)$", proc.stdout)
    if proc.returncode or re.search(r"(?m)^(SCRIPT ERROR|ERROR):", proc.stdout) or not match:
        raise RuntimeError(f"Native contact process failed: {label}")
    source = Path(match[1].strip())
    data = json.loads(source.read_text(encoding="utf-8"))
    if not data["completed"] or data["physics_hz"] != 60 or len(data["trace"]) != 80:
        raise RuntimeError(f"Incomplete contact execution: {label}")
    (output / f"{label}.json").write_bytes(source.read_bytes())
    return data


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    args = parser.parse_args()
    output = ROOT / "test-results" / "contact-restart"
    output.mkdir(parents=True, exist_ok=True)
    cases = []
    for kind in ("vault", "mantle"):
        for segment in range(3):
            produced = run_engine(args.godot, "produce", kind, segment, 60, output)
            observed = {"start": produced["start"], "trace": produced["trace"]}
            identity = digest(observed)
            for rate in (30, 60, 144):
                resumed = run_engine(args.godot, "resume", kind, segment, rate, output)
                current = {"start": resumed["start"], "trace": resumed["trace"]}
                if resumed["engine"] != produced["engine"] or current != observed:
                    raise RuntimeError(f"Cross-process replay differs: {kind}/{segment}/{rate}")
                cases.append({"kind": kind, "segment": segment, "render_schedule_fps": rate,
                              "physics_hz": 60, "ticks_compared": 80,
                              "observation_sha256": identity, "equal": True})
    evidence = {"cases": cases, "source_sha256": {
        path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in SOURCES}}
    report = {"model_id": "traversal-contact.v1",
              "operation_id": "traversal-cross-process-replay.v1",
              "execution_id": str(uuid.uuid4()), "evidence_id": digest(evidence),
              "verification_id": "exact-json-state-comparison.v1", "evidence": evidence,
              "limits": ["same Godot build and platform", "fixed 60 Hz physics",
                         "headless scheduling, not GPU frame-time or input-latency measurement",
                         "consistency, not save authentication or historical evidence"]}
    (output / "verification.json").write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
    print(f"CONTACT_RESTART_CHECKS: {len(cases)} comparisons passed; 0 failed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, OSError, ValueError, subprocess.TimeoutExpired) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1)
