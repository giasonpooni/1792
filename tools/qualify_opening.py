"""Execute and independently qualify the fresh opening through household inquiry.

The retained execution binds source, executable, command and evidence. Verification
checks recorded consistency and native save rollback, not historical authenticity,
OS-level automation, human control feel or artistic approval.
"""
from __future__ import annotations

import argparse
import copy
from datetime import datetime, timezone
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import signal
import struct
import subprocess
import tarfile
import uuid
import zlib

from check_gujranwala_beauty_capture import decode_png

ROOT = Path(__file__).resolve().parents[1]
OPERATION = "1792.opening-household-inquiry.v1"
SCRIPT = "res://tests/render_opening_chapter.gd"
CAPTURES = (
    "family-opening", "riding-ready", "first-gate", "single-standing",
    "paired-standing", "four-matchlocks-spent", "mounted-reload",
    "horsecraft-return", "riding-course-complete", "practice-complete",
    "tracking-trail", "quarry-observed", "return-encounter", "household-return",
    "household-offer", "bend-observed", "household-report", "inquiry-complete",
)
SKILLS = ["single_standing", "paired_standing", "mounted_matchlock"]
MEMORIES = ["return_steward", "return_courier", "protection_offer",
            "household_escort", "bend_trace", "oral_return"]


def require(value: bool, message: str) -> None:
    if not value:
        raise ValueError(message)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def json_read(path: Path) -> dict:
    def invalid(value: str):
        raise ValueError("Nonfinite JSON constant: " + value)
    def unique(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, "Duplicate JSON field: " + key)
            result[key] = value
        return result
    data = json.loads(path.read_text(encoding="utf-8"), parse_constant=invalid,
                      object_pairs_hook=unique)
    require(isinstance(data, dict), "Expected JSON object: " + str(path))
    return data


def write_json(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True, allow_nan=False) + "\n", encoding="utf-8")


def whole(value, minimum: int = 0) -> bool:
    return type(value) in (int, float) and math.isfinite(value) and value == int(value) and value >= minimum


def hex_id(value, length: int = 64) -> bool:
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{%d}" % length, value) is not None


def normalize(value):
    if type(value) is float and value.is_integer():
        return int(value)
    if isinstance(value, dict):
        return {key: normalize(item) for key, item in value.items()}
    if isinstance(value, list):
        return [normalize(item) for item in value]
    return value


def native_save_projection(value: dict) -> dict:
    """Reconcile only the guard's native binary32 pose across Godot JSON parsing.

    Godot's decimal parser can move a persisted guard coordinate one double ULP.
    The source native Vector3 remains identical at binary32. Knowledge, clocks,
    receipts and all other authority retain exact decoded comparison; raw byte
    identities and the recorded original snapshots are never replaced.
    """
    result = copy.deepcopy(value)
    guard = result["aftermath"]["escort"]
    for field in ("position", "velocity"):
        if field not in guard:
            continue
        require(isinstance(guard[field], list) and len(guard[field]) == 3
                and all(type(item) in (int, float) and math.isfinite(item) for item in guard[field]),
                "Invalid persisted physical guard vector")
        guard[field] = [struct.unpack(">f", struct.pack(">f", item))[0] for item in guard[field]]
    if "yaw" in guard:
        require(type(guard["yaw"]) in (int, float) and math.isfinite(guard["yaw"]), "Invalid persisted guard yaw")
        guard["yaw"] = struct.unpack(">f", struct.pack(">f", guard["yaw"]))[0]
    return result


def receipt_check(receipt: dict) -> None:
    require(receipt.get("schema") == "1792.riding-training-receipt.v1"
            and receipt.get("lesson_id") == "mahan-horsecraft-training.v1"
            and receipt.get("subject_id") == "ranjit_singh"
            and receipt.get("flashback_actor_id") == "mahan_singh"
            and receipt.get("historical_status") == "user-attributed-unverified",
            "Unsupported earned riding receipt")
    require(hex_id(receipt.get("present_sha256")) and hex_id(receipt.get("completion_sha256")),
            "Missing riding receipt bindings")
    facts = receipt["facts"]
    require(whole(facts["single_hold_ticks"], 60) and whole(facts["paired_hold_ticks"], 60)
            and facts["volley_slots"] == [0, 1, 2, 3]
            and sorted(facts["reloaded_slots"]) == [0, 1, 2, 3], "Incomplete earned riding facts")
    milestones = receipt["milestones"]
    require([item["id"] for item in milestones] == SKILLS
            and all(whole(item["tick"]) for item in milestones)
            and whole(receipt["entry_tick"]) and whole(receipt["completed_tick"])
            and sorted(item["tick"] for item in milestones) == [item["tick"] for item in milestones]
            and milestones[-1]["tick"] <= receipt["completed_tick"], "Invalid earned milestone sequence")
    proof = {key: value for key, value in receipt.items()
             if key not in ("schema", "present_sha256", "completion_sha256")}
    encoded = json.dumps(normalize(proof), sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode()
    require(sha(encoded) == receipt["completion_sha256"], "Riding completion proof hash mismatch")


def snapshot_check(value: dict, receipt: dict, phase: str) -> None:
    child, after = value["childhood"], value["aftermath"]
    require(value["player"]["character_id"] == "ranjit_singh"
            and child["ambush"]["status"] == "escaped" and child["ambush"]["hits"] < 3
            and child["ride_gate"] == 3 and child["parries"] == 2 and child["counters"] == 1
            and child["tracks"] == 3 and child["quarry_seen"] is True,
            "Incomplete or nonliving native opening endpoint")
    require(value["riding_skills"]["lesson_receipts"] == [receipt], "Earned receipt was lost or replaced")
    require(after["decision"] == "household_escort" and after["heard"] == MEMORIES[:2]
            and after["offer_heard"] is True, "Missing actual household agreement")
    expected = MEMORIES if phase == "complete" else MEMORIES[:-1]
    require([item["id"] for item in after["memories"]] == expected,
            "Missing, duplicated or reordered household memory")
    require(all(whole(after[key]) for key in ("decision_tick", "clue_tick"))
            and after["decision_tick"] <= after["clue_tick"] <= child["tick"], "Noncausal inquiry ticks")
    ticks = [item["received_tick"] for item in after["memories"]]
    require(all(whole(tick) and tick <= child["tick"] for tick in ticks) and ticks == sorted(ticks),
            "Noncausal remembered testimony")
    if phase == "complete":
        require(whole(after["reported_tick"]) and after["clue_tick"] <= after["reported_tick"] <= child["tick"]
                and after["escort"]["active"] is False and after["escort"]["instruction"] == "hold"
                and after["escort"]["velocity"] == [0, 0, 0]
                and "unidentified" in after["memories"][-1]["text"], "Incomplete observed report/escort retirement")
    else:
        require(after["reported_tick"] == -1 and after["escort"]["active"] is True,
                "Midreturn save does not preserve the pending witnessed report")


def check_manifest(folder: Path, checkpoint: Path, final_save: Path) -> dict:
    manifest = json_read(folder / "manifest.json")
    require(manifest.get("schema") == "1792.opening-chapter-render.v2"
            and type(manifest.get("failures")) is int and manifest["failures"] == 0
            and whole(manifest.get("checks"), 1), "Failed or unsupported opening manifest")
    for field in ("progress_seeded", "capability_receipt_seeded", "camera_pose_injected",
                  "startup_save_seeded", "human_playtest", "historical_authentication"):
        require(manifest.get(field) is False, "Unsupported qualification claim: " + field)
    require(manifest.get("saved_pose_restored") is True and manifest.get("physics_hz") == 60
            and manifest.get("entry") == "actual HomeLaunch.enter"
            and str(manifest.get("engine", "")).startswith("4.5.1")
            and manifest.get("renderer") == "gl_compatibility", "Missing declared native execution boundaries")
    records = manifest["captures"]
    require(isinstance(records, list) and tuple(item["id"] for item in records) == CAPTURES,
            "Missing, extra or reordered opening captures")
    require({path.name for path in folder.glob("*.png")} == {name + ".png" for name in CAPTURES},
            "Missing or extra retained opening PNG")
    for record in records:
        name = record["id"]
        require(record["file"] == name + ".png" and record.get("camera_pose_injected") is False
                and record.get("inspection_camera_only") is False
                and record.get("pixel_format") == "rgba8"
                and record.get("width") == 1280 and record.get("height") == 720
                and record.get("camera_kind") in ("production-gameplay", "production-story-presentation")
                and hex_id(record.get("state_sha256")), "Invalid production capture metadata: " + name)
        data = (folder / record["file"]).read_bytes()
        width, height, pixels = decode_png(data)
        require(sha(data) == record["sha256"] and sha(pixels) == record["pixel_sha256"]
                and (width, height) == (record["width"], record["height"]), "PNG byte/pixel mismatch: " + name)
        require(pixels != pixels[:4] * (width * height), "Blank production frame: " + name)
    receipt = manifest["earned_training_receipt"]
    receipt_check(receipt)
    shots = manifest["native_shot_observations"]
    require([item["slot"] for item in shots] == [0, 1, 2, 3]
            and len({item["shot_id"] for item in shots}) == 4, "Missing distinct native weapon discharges")
    final = manifest["final_snapshot"]
    snapshot_check(final, receipt, "complete")
    persistence = manifest["midreturn_persistence"]
    saved, restored = persistence["saved_snapshot"], persistence["restored_snapshot"]
    progressed = persistence["progressed_snapshot"]
    snapshot_check(saved, receipt, "return")
    snapshot_check(restored, receipt, "return")
    snapshot_check(progressed, receipt, "complete")
    require(persistence.get("declared_saved_pose_restored") is True and saved == restored
            and progressed["childhood"]["tick"] > saved["childhood"]["tick"]
            and persistence["saved_tick"] == saved["childhood"]["tick"]
            and persistence["restored_tick"] == restored["childhood"]["tick"],
            "Native midreturn restore did not roll back the whole saved authority")
    require(persistence.get("retained_file") == "midreturn-save.json", "Missing retained native midreturn save")
    midreturn = folder / "midreturn-save.json"
    require(sha(midreturn.read_bytes()) == persistence["save_sha256"]
            and native_save_projection(json_read(midreturn)) == native_save_projection(saved),
            "Midreturn native-save digest or decoded authority mismatch")
    saved_final = json_read(final_save)
    require(sha(final_save.read_bytes()) == manifest["final_manual_save"]["sha256"]
            and native_save_projection(saved_final) == native_save_projection(manifest["final_manual_save"]["snapshot"]),
            "Final manual save digest or whole authority mismatch")
    snapshot_check(saved_final, receipt, "complete")
    require(saved_final["childhood"]["tick"] <= final["childhood"]["tick"]
            and native_save_projection(saved_final)["aftermath"] == native_save_projection(final)["aftermath"]
            and saved_final["riding_skills"] == final["riding_skills"],
            "Completed inquiry or earned receipt changed after the final save boundary")
    envelope = json_read(checkpoint)
    require(sha(checkpoint.read_bytes()) == manifest["production_automatic_checkpoint"]["sha256"]
            and envelope["schema"] == "1792.chapter-checkpoint.v1" and envelope["reason"] == "courtyard_return"
            and envelope["snapshot"]["childhood"]["ambush"]["status"] == "escaped"
            and envelope["snapshot"]["aftermath"]["memories"] == []
            and envelope["snapshot"]["riding_skills"]["lesson_receipts"] == [receipt],
            "Production courtyard checkpoint digest or earned-state mismatch")
    return {"captures": len(records), "native_checks": manifest["checks"],
            "manifest_sha256": sha((folder / "manifest.json").read_bytes()),
            "earned_receipt_sha256": receipt["completion_sha256"],
            "native_midreturn_rollback_verified": True, "final_phase": "complete", "decision": "household_escort",
            "native_save_comparison": "exact decoded authority except binary32 equality for physical guard position/velocity/yaw; exact bytes independently hashed"}


def archive_tree(path: Path) -> tuple[str, dict[str, bytes]]:
    """Recompute Git's exact source tree from retained archive bytes, without Git writes."""
    files, entries = {}, {}
    require(path.stat().st_size <= 256 * 1024 * 1024, "Source archive exceeds bound")
    with tarfile.open(path, "r:") as archive:
        for item in archive:
            require(not item.name.startswith("/") and ".." not in Path(item.name).parts,
                    "Unsafe source archive path")
            if item.isdir():
                continue
            require(item.name not in files, "Duplicate source archive path")
            require(item.isfile() or item.issym(), "Unsupported source archive entry")
            data = item.linkname.encode() if item.issym() else archive.extractfile(item).read()
            files[item.name] = data
            mode = "120000" if item.issym() else "100755" if item.mode & 0o111 else "100644"
            node = entries
            parts = item.name.split("/")
            for part in parts[:-1]:
                node = node.setdefault(part, {})
            require(parts[-1] not in node, "Conflicting source archive path")
            blob = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).digest()
            node[parts[-1]] = (mode, blob)
    def tree(node):
        encoded = bytearray()
        for name in sorted(node, key=lambda value: value.encode() + (b"/" if isinstance(node[value], dict) else b"")):
            item = node[name]
            mode, object_id = ("40000", tree(item)) if isinstance(item, dict) else item
            encoded.extend(mode.encode() + b" " + name.encode() + b"\0" + object_id)
        return hashlib.sha1(b"tree " + str(len(encoded)).encode() + b"\0" + encoded).digest()
    return tree(entries).hex(), files


def verify_execution(folder: Path) -> dict:
    execution = json_read(folder / "execution.json")
    require(execution.get("schema") == "1792.opening-qualification-execution.v1"
            and execution["operation"]["id"] == OPERATION
            and execution["operation"]["script"] == SCRIPT
            and execution["execution"]["exit_code"] == 0, "Failed or unsupported qualification execution")
    uuid.UUID(execution["execution"]["id"])
    started = datetime.fromisoformat(execution["execution"]["started_at"])
    ended = datetime.fromisoformat(execution["execution"]["ended_at"])
    require(started.tzinfo is not None and ended.tzinfo is not None and ended >= started,
            "Invalid retained execution interval")
    source = execution["source"]
    require(source["repository_id"] == 1392110087 and hex_id(source["commit"], 40)
            and hex_id(source["tree"], 40) and source["before"] == source["after"]
            and source["before"] == {"commit": source["commit"], "tree": source["tree"], "dirty": False},
            "Dirty or changed source execution boundary")
    archive = folder / "source.tar"
    require(sha(archive.read_bytes()) == source["archive_sha256"], "Retained source archive digest mismatch")
    commit_object = (folder / "source-commit.txt").read_bytes()
    require(sha(commit_object) == source["commit_object_sha256"]
            and hashlib.sha1(b"commit " + str(len(commit_object)).encode() + b"\0" + commit_object).hexdigest() == source["commit"]
            and commit_object.splitlines()[0] == b"tree " + source["tree"].encode(),
            "Retained commit object does not bind the qualified commit and tree")
    tree, files = archive_tree(archive)
    require(tree == source["tree"], "Retained source archive does not reproduce qualified Git tree")
    for name in ("tools/qualify_opening.py", "tools/check_gujranwala_beauty_capture.py"):
        require(sha(files[name]) == sha((ROOT / name).read_bytes()), "Independent verifier differs from retained source: " + name)
    require(sha(files["game/tests/render_opening_chapter.gd"]) == execution["operation"]["script_sha256"],
            "Renderer operation source mismatch")
    runtime = execution["runtime"]
    require(hex_id(runtime["sha256"]) and whole(runtime["bytes"], 1)
            and runtime["after_sha256"] == runtime["sha256"]
            and re.match(r"^4\.5\.1[.-]stable", runtime["version"]), "Unqualified or changed Godot runtime identity")
    command = execution["execution"]["command"]
    expected_command = [runtime["executable"], "--fixed-fps", "60", "--path", "game", "--rendering-method",
                        "gl_compatibility", "--audio-driver", "Dummy", "--script", SCRIPT]
    require(command == expected_command or command == ["xvfb-run", "-a", *expected_command],
            "Retained command does not identify the qualified opening operation")
    log = (folder / "renderer.log").read_bytes()
    require(sha(log) == execution["execution"]["log_sha256"]
            and not re.search(rb"(?m)^(?:SCRIPT ERROR|SHADER ERROR|ERROR):", log), "Renderer errors or log digest mismatch")
    result = check_manifest(folder / "opening-chapter-images", folder / "courtyard-checkpoint.json", folder / "final-manual-save.json")
    require(result["manifest_sha256"] == execution["execution"]["manifest_sha256"], "Stale or replaced execution manifest")
    require(re.search(rb"(?m)^OPENING_CHAPTER_RENDER: 18 captures; " + str(result["native_checks"]).encode()
                      + rb" checks; 0 failures$", log) is not None, "Renderer did not reach the exact qualification marker")
    return {"schema": "1792.opening-qualification-verification.v1", "status": "passed",
            "verification_id": str(uuid.uuid4()), "verified_at": datetime.now(timezone.utc).isoformat(),
            "execution_id": execution["execution"]["id"], "operation_id": OPERATION,
            "source_commit": source["commit"], "source_tree": source["tree"],
            "runtime_sha256": runtime["sha256"], "execution_sha256": sha((folder / "execution.json").read_bytes()),
            "verifier_sha256": sha((ROOT / "tools/qualify_opening.py").read_bytes()),
            "png_decoder_sha256": sha((ROOT / "tools/check_gujranwala_beauty_capture.py").read_bytes()),
            **result, "scope": "independent source-tree, byte/pixel, receipt, save and recorded rollback consistency; not historical authentication, OS-level input routing or human playtesting"}


def git_state() -> dict:
    def git(*args):
        return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()
    return {"commit": git("rev-parse", "HEAD"), "tree": git("rev-parse", "HEAD^{tree}"),
            "dirty": bool(git("status", "--porcelain", "--untracked-files=normal"))}


def execute(args) -> dict:
    before = git_state()
    require(not before["dirty"], "Commit the bounded source before qualification; checkout is dirty")
    require(not args.source_commit or args.source_commit == before["commit"], "Requested source commit is stale")
    require(not args.source_tree or args.source_tree == before["tree"], "Requested source tree is stale")
    folder = args.evidence_dir.resolve()
    require(not folder.exists() or not any(folder.iterdir()), "Evidence destination must be fresh and empty")
    godot = args.godot.resolve(strict=True)
    runtime_bytes = godot.read_bytes()
    version = subprocess.check_output([str(godot), "--version"], text=True, timeout=15).strip()
    require(re.match(r"^4\.5\.1[.-]stable", version) is not None, "Only pinned Godot 4.5.1 stable is qualified")
    folder.mkdir(parents=True, exist_ok=True)
    archive = subprocess.check_output(["git", "archive", "--format=tar", before["commit"]], cwd=ROOT)
    (folder / "source.tar").write_bytes(archive)
    commit_object = subprocess.check_output(["git", "cat-file", "commit", before["commit"]], cwd=ROOT)
    (folder / "source-commit.txt").write_bytes(commit_object)
    data_dir = folder / "isolated-user-data"
    data_dir.mkdir()
    command = [str(godot), "--fixed-fps", "60", "--path", "game", "--rendering-method",
               "gl_compatibility", "--audio-driver", "Dummy", "--script", SCRIPT]
    if args.xvfb:
        require(shutil.which("xvfb-run") is not None, "xvfb-run is unavailable")
        command = ["xvfb-run", "-a", *command]
    else:
        require(bool(os.environ.get("DISPLAY")), "A real display or --xvfb is required")
    env = {**os.environ, "XDG_DATA_HOME": str(data_dir), "LIBGL_ALWAYS_SOFTWARE": "1"}
    started = datetime.now(timezone.utc).isoformat()
    process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, start_new_session=True)
    try:
        log, _ = process.communicate(timeout=args.timeout)
        code = process.returncode
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            log, _ = process.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            log, _ = process.communicate(timeout=5)
        code = 124
    (folder / "renderer.log").write_bytes(log)
    print(log.decode(errors="replace"), end="", flush=True)
    after = git_state()
    user = data_dir / "godot/app_userdata/1792"
    manifest_folder = user / "opening-chapter-images"
    if manifest_folder.is_dir():
        shutil.copytree(manifest_folder, folder / "opening-chapter-images")
    manifest = json_read(manifest_folder / "manifest.json") if (manifest_folder / "manifest.json").exists() else {}
    for field, destination in (("production_automatic_checkpoint", "courtyard-checkpoint.json"),
                               ("final_manual_save", "final-manual-save.json")):
        name = manifest.get(field, {}).get("file", "")
        if name:
            require(name.startswith("user://") and "/" not in name[7:] and ".." not in name, "Unsafe renderer save reference")
            shutil.copyfile(user / name[7:], folder / destination)
    execution = {"schema": "1792.opening-qualification-execution.v1",
                 "source": {"repository_id": 1392110087, "commit": before["commit"], "tree": before["tree"],
                            "before": before, "after": after, "archive_sha256": sha(archive),
                            "commit_object_sha256": sha(commit_object)},
                 "runtime": {"executable": str(godot), "bytes": len(runtime_bytes), "sha256": sha(runtime_bytes),
                             "after_sha256": sha(godot.read_bytes()), "version": version},
                 "operation": {"id": OPERATION, "script": SCRIPT,
                               "script_sha256": sha((ROOT / "game/tests/render_opening_chapter.gd").read_bytes())},
                 "execution": {"id": str(uuid.uuid4()), "command": command, "started_at": started,
                               "ended_at": datetime.now(timezone.utc).isoformat(), "exit_code": code,
                               "log_sha256": sha(log), "manifest_sha256": sha((manifest_folder / "manifest.json").read_bytes()) if manifest else "absent"}}
    write_json(folder / "execution.json", execution)
    require(before == after, "Source changed during qualification")
    verification = verify_execution(folder)
    write_json(folder / "verification.json", verification)
    return verification


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path)
    parser.add_argument("--evidence-dir", type=Path, required=True)
    parser.add_argument("--source-commit")
    parser.add_argument("--source-tree")
    parser.add_argument("--xvfb", action="store_true")
    parser.add_argument("--timeout", type=int, default=240)
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()
    try:
        require(args.verify_only or args.godot is not None, "--godot is required for execution")
        require(1 <= args.timeout <= 600, "Execution timeout must be 1–600 seconds")
        result = verify_execution(args.evidence_dir.resolve()) if args.verify_only else execute(args)
        print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    except (OSError, ValueError, KeyError, TypeError, OverflowError, struct.error, zlib.error,
            tarfile.TarError, subprocess.SubprocessError) as error:
        parser.exit(1, "OPENING QUALIFICATION REFUSED: " + str(error) + "\n")


if __name__ == "__main__":
    raise SystemExit(main())
