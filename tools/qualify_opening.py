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
from godot451_json import differences, exact_raw_clock, verify_native_save_bytes

ROOT = Path(__file__).resolve().parents[1]
OPERATION = "1792.opening-household-inquiry.v1"
OPERATIONS = {"household_escort": OPERATION,
              "independent_inquiry": "1792.opening-independent-inquiry.v1"}
TASK_OPERATIONS = {"household_escort": "1792.opening-household-responsibility.v1",
                   "independent_inquiry": "1792.opening-independent-responsibility.v1"}
SCRIPT = "res://tests/render_opening_chapter.gd"
CAPTURES = (
    "family-opening", "riding-ready", "first-gate", "single-standing",
    "paired-standing", "four-matchlocks-spent", "mounted-reload",
    "horsecraft-return", "riding-course-complete", "practice-complete",
    "tracking-trail", "quarry-observed", "return-encounter", "household-return",
    "household-offer", "bend-observed", "household-report", "inquiry-complete",
)
TASK_CAPTURES = ("quartermaster-allowance", "household-commission", "smith-handover",
                 "smith-collection", "household-task-complete")
INITIAL_HOUSEHOLD_LEDGER = {
    "purse": 18, "treasury": 120, "stock": {"food": 10, "feed": 8, "grain": 8, "timber": 8, "tools": 2},
    "workers": 1, "guards": 0, "horses": 1, "watch": 0, "arrears": 0,
    "food_shortfall": 0, "feed_shortfall": 0, "duty_guards": 0, "favor": 50,
    "meeting": "pending", "satchel": False, "delivery": "available", "caravan": "locked", "cargo": 0,
    "build": "", "work_left": 0, "built": [],
    "last_notice": "A bounded household allowance, not ownership of all royal funds.",
}
SKILLS = ["single_standing", "paired_standing", "mounted_matchlock"]
MEMORIES = ["return_steward", "return_courier", "protection_offer",
            "household_escort", "bend_trace", "oral_return"]
UNDEPLOYED_GUARD = {"id": "fictional_household_guard", "active": False, "instruction": "hold",
                    "position": [-9, 0.14000000059604645, 8], "yaw": 0, "velocity": [0, 0, 0]}


def require(value: bool, message: str) -> None:
    if not value:
        raise ValueError(message)


def semantic_equal(left, right) -> bool:
    """Exact authority equality without Python Boolean/number aliases."""
    return not differences(left, right)


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
            and semantic_equal(facts["volley_slots"], [0, 1, 2, 3])
            and semantic_equal(sorted(facts["reloaded_slots"]), [0, 1, 2, 3]), "Incomplete earned riding facts")
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


def snapshot_check(value: dict, receipt: dict, phase: str, choice: str) -> None:
    child, after = value["childhood"], value["aftermath"]
    require(all(whole(child[field]) for field in ("tick", "ride_gate", "parries", "counters", "tracks"))
            and whole(child["ambush"]["hits"])
            and value["player"]["character_id"] == "ranjit_singh"
            and child["ambush"]["status"] == "escaped" and child["ambush"]["hits"] < 3
            and child["ride_gate"] == 3 and child["parries"] == 2 and child["counters"] == 1
            and child["tracks"] == 3 and child["quarry_seen"] is True,
            "Incomplete or nonliving native opening endpoint")
    require(semantic_equal(value["riding_skills"]["lesson_receipts"], [receipt]), "Earned receipt was lost or replaced")
    require(choice in OPERATIONS and after["decision"] == choice and after["heard"] == MEMORIES[:2]
            and after["offer_heard"] is True, "Missing actual household agreement")
    memories = [*MEMORIES[:3], choice, *MEMORIES[4:]]
    expected = memories if phase == "complete" else memories[:-1]
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
                and semantic_equal(after["escort"]["velocity"], [0, 0, 0])
                and "unidentified" in after["memories"][-1]["text"], "Incomplete observed report/escort retirement")
    else:
        require(after["reported_tick"] == -1 and after["escort"]["active"] is (choice == "household_escort"),
                "Midreturn save does not preserve the pending witnessed report")
    if choice == "independent_inquiry":
        require(semantic_equal(native_save_projection({"aftermath": after})["aftermath"]["escort"], UNDEPLOYED_GUARD),
                "Independent inquiry moved or deployed a household guard")


def operation_id(choice: str, task: str) -> str:
    require(choice in OPERATIONS and task in ("none", "smith-commission"), "Unsupported opening endpoint")
    return (TASK_OPERATIONS if task == "smith-commission" else OPERATIONS)[choice]


def task_check(folder: Path, manifest: dict, receipt: dict, choice: str) -> None:
    """Check exact custody, native replay and conservation through the existing commission."""
    persistence = manifest["household_task_persistence"]
    inquiry = persistence["inquiry_snapshot"]
    snapshot_check(inquiry, receipt, "complete", choice)
    require("misl" not in inquiry, "Inquiry endpoint already contains an unearned allowance")
    require(sha((folder / "inquiry-manual-save.json").read_bytes()) == persistence["inquiry_save_sha256"]
            and verify_native_save_bytes((folder / "inquiry-manual-save.json").read_bytes(), inquiry),
            "Retained inquiry save differs from the earned handoff")
    task_records = {item["id"]: item for item in manifest["captures"] if item["id"] in TASK_CAPTURES}
    states = {name: item["snapshot"] for name, item in task_records.items()}
    allowance = states["quartermaster-allowance"]["misl"]
    require(semantic_equal(allowance["ledger"], INITIAL_HOUSEHOLD_LEDGER),
            "Allowance grants quantities or actors outside the original finite household ledger")
    def stable_ledger(value):
        stable = copy.deepcopy(value)
        for field in ("workshop", "favor", "treasury"):
            stable.pop(field, None)
        for field in ("timber", "tools"):
            stable["stock"].pop(field)
        return stable
    expected_phases = ("unassigned", "fuel", "working", "tools", "complete")
    for name, phase in zip(TASK_CAPTURES, expected_phases):
        record = task_records[name]
        state = states[name]
        # These are live observations after native ticks, not cold save loads.
        # Cold snapshots remain bound to their original bytes/parser below.
        exact_raw_clock(state)
        require(semantic_equal(record.get("home_tick"), state["childhood"]["tick"])
                and semantic_equal(record.get("progress"), state["childhood"])
                and semantic_equal(record.get("economy"), state["misl"])
                and record.get("workshop_phase") == phase
                and semantic_equal(record.get("workshop"), state["misl"]["ledger"].get("workshop", {}))
                and semantic_equal(record.get("aftermath"), state["aftermath"]),
                "Household capture metadata disagrees with its whole authority")
        marker = record["objective_marker"]
        smith = phase in ("fuel", "working")
        target = [-15, 2.240000009536743, 8] if smith else [3, 2.240000009536743, 5]
        require(semantic_equal(marker, {"visible": True, "text": "Smith · E" if smith else "Quartermaster · E", "position": target}),
                "Compact household objective does not locate the actual custody speaker")
        require(record["hud"]["compact_visible"] is True and record["hud"]["legacy_visible"] is False,
                "Household custody boundary fell back to dense legacy guidance")
        if phase == "complete":
            require(record["hud"]["task"] == "First household responsibility complete",
                    "Missing compact settled first-responsibility handoff")
        snapshot_check(state, receipt, "complete", choice)
        require(semantic_equal(native_save_projection(state)["aftermath"], native_save_projection(inquiry)["aftermath"]),
                "Household task changed the completed inquiry or retired guard")
        ledger = state["misl"]["ledger"]
        require(ledger["purse"] == 18 and ledger["treasury"] == (120 if phase == "unassigned" else 116)
                and ledger["stock"]["timber"] == (8 if phase == "unassigned" else 6)
                and ledger["stock"]["tools"] == (4 if phase == "complete" else 2)
                and ledger["favor"] == (53 if phase == "complete" else 50)
                and semantic_equal(stable_ledger(ledger), stable_ledger(allowance["ledger"])),
                "Commission minted money or prematurely delivered materials")
        require(semantic_equal({key: value for key, value in state["misl"].items() if key not in ("ledger", "events")},
                               {key: value for key, value in allowance.items() if key not in ("ledger", "events")}),
                "Commission replaced its original economy or merchant authority")
        require(whole(state["misl"]["origin_tick"]) and inquiry["childhood"]["tick"] <= state["misl"]["origin_tick"] <= state["childhood"]["tick"],
                "Allowance precedes its physically earned inquiry")
        if phase == "unassigned":
            require("workshop" not in ledger and state["misl"]["events"] == [], "Allowance grants an unearned commission")
        else:
            require(ledger["workshop"]["phase"] == phase, "Missing physically earned commission phase: " + phase)
    saved, restored, progressed = (persistence[field] for field in ("saved_snapshot", "restored_snapshot", "progressed_snapshot"))
    exact_raw_clock(progressed)
    for state in (saved, restored, progressed):
        snapshot_check(state, receipt, "complete", choice)
        require(semantic_equal(native_save_projection(state)["aftermath"], native_save_projection(inquiry)["aftermath"]),
                "Fuel recovery changed its completed inquiry or retired guard")
    require(persistence["declared_saved_pose_restored"] is True and semantic_equal(saved, restored)
            and progressed["childhood"]["tick"] > saved["childhood"]["tick"]
            and saved["misl"]["ledger"]["workshop"]["phase"] == "fuel"
            and progressed["misl"]["ledger"]["workshop"]["phase"] == "working",
            "Native fuel save did not restore the exact whole carried custody")
    require(persistence["retained_file"] == "household-fuel-save.json"
            and sha((folder / persistence["retained_file"]).read_bytes()) == persistence["save_sha256"]
            and verify_native_save_bytes((folder / persistence["retained_file"]).read_bytes(), saved),
            "Household fuel save bytes or whole authority mismatch")
    final = manifest["final_snapshot"]
    exact_raw_clock(final)
    for state in (*states.values(), saved, restored, progressed, final, manifest["final_manual_save"]["snapshot"]):
        economy = state["misl"]
        prior = economy["origin_tick"]
        require(whole(prior) and prior <= state["childhood"]["tick"], "Economic origin is in the future")
        for index, receipt_item in enumerate(economy["events"], 1):
            tick = receipt_item["tick"]
            require(whole(tick) and prior <= tick <= state["childhood"]["tick"]
                    and whole(receipt_item["seq"], 1) and receipt_item["seq"] == index and receipt_item["arg"] == str(int(tick)),
                    "Household economic receipt predates its origin or exceeds its snapshot clock")
            prior = tick
    require(semantic_equal(native_save_projection(final)["aftermath"], native_save_projection(inquiry)["aftermath"]),
            "Settled household task changed its completed inquiry or retired guard")
    receipts = final["misl"]["events"]
    kinds = [item["kind"] for item in receipts]
    require(kinds == ["smith.reserve", "smith.start", "smith.ready", "smith.collect", "smith.deliver"]
            and semantic_equal([item["seq"] for item in receipts], [1, 2, 3, 4, 5])
            and all(item["arg"] == str(int(item["tick"])) for item in receipts),
            "Missing, duplicated or unrelated household custody receipts")
    ticks = [item["tick"] for item in receipts]
    require(all(whole(tick) for tick in ticks) and ticks == sorted(ticks)
            and ticks[2] == ticks[1] + 600 and ticks[-1] <= final["childhood"]["tick"],
            "Smith work skipped its native deadline or reordered custody")
    for name, prefix in zip(TASK_CAPTURES, (0, 1, 2, 4, 5)):
        captured_receipts = progressed["misl"]["events"] if name == "smith-handover" else receipts[:prefix]
        captured_ticks = [item["tick"] for item in captured_receipts]
        require(semantic_equal(states[name]["misl"]["events"], captured_receipts),
                "Captured household phase does not match its actual receipt prefix")
        if not prefix:
            continue
        phase = states[name]["misl"]["ledger"]["workshop"]["phase"]
        expected = {"schema": "home-courtyard-smith.v2", "phase": phase,
                    "reserved_tick": captured_ticks[0], "started_tick": captured_ticks[1] if prefix >= 2 else -1,
                    "ready_tick": captured_ticks[2] if prefix >= 3 else -1,
                    "picked_up_tick": captured_ticks[3] if prefix >= 4 else -1,
                    "settled_tick": captured_ticks[4] if prefix >= 5 else -1,
                    "fuel_carried": 2 if prefix == 1 else 0, "fuel_used": 0 if prefix == 1 else 2,
                    "tools_carried": 2 if prefix == 4 else 0, "fee_held": 4 if prefix == 1 else 0,
                    "fee_paid": 0 if prefix == 1 else 4}
        require(semantic_equal(states[name]["misl"]["ledger"]["workshop"], expected),
                "Captured commission custody or deadline differs from its receipts")
        require(captured_ticks == sorted(captured_ticks)
                and captured_ticks[-1] <= states[name]["childhood"]["tick"],
                "Captured custody receipt is reordered or in the future")
    require(semantic_equal(saved["misl"], restored["misl"])
            and semantic_equal(saved["misl"], states["household-commission"]["misl"])
            and semantic_equal(progressed["misl"], states["smith-handover"]["misl"])
            and semantic_equal(saved["misl"]["events"], receipts[:1])
            and semantic_equal(progressed["misl"]["events"][0], receipts[0])
            and len(progressed["misl"]["events"]) == 2
            and progressed["misl"]["events"][1]["kind"] == "smith.start",
            "Fuel rollback retained a later handover or lost its reservation")
    expected_workshop = {"schema": "home-courtyard-smith.v2", "phase": "complete",
                         "reserved_tick": ticks[0], "started_tick": ticks[1], "ready_tick": ticks[2],
                         "picked_up_tick": ticks[3], "settled_tick": ticks[4], "fuel_carried": 0,
                         "fuel_used": 2, "tools_carried": 0, "fee_held": 0, "fee_paid": 4}
    require(semantic_equal(final["misl"]["ledger"], states["household-task-complete"]["misl"]["ledger"])
            and final["misl"]["ledger"]["workshop"]["phase"] == "complete"
            and final["misl"]["ledger"]["workshop"]["tools_carried"] == 0
            and final["misl"]["ledger"]["workshop"]["fuel_used"] == 2
            and final["misl"]["ledger"]["workshop"]["fee_paid"] == 4,
            "Final commission is not physically settled")
    require(semantic_equal(final["misl"]["ledger"]["workshop"], expected_workshop),
            "Settled commission fields disagree with native custody receipts")
    require(semantic_equal(manifest["final_manual_save"]["snapshot"]["misl"], final["misl"]),
            "Final manual save lost its settled household custody")
    require(persistence["final_task_completed"] is True
            and semantic_equal(persistence["final_snapshot"], final),
            "Household final persistence disagrees with its whole authority")
    for name, state in (("saved", saved), ("restored", restored),
                        ("progressed", progressed), ("final", final)):
        tick = persistence[name + "_tick"]
        require(whole(tick) and semantic_equal(tick, state["childhood"]["tick"]),
                "Household replay tick mirror disagrees with its whole authority: " + name)


def check_manifest(folder: Path, checkpoint: Path, final_save: Path, choice: str = "household_escort", task: str = "none") -> dict:
    manifest = json_read(folder / "manifest.json")
    require(manifest.get("schema") == "1792.opening-chapter-render.v2"
            and type(manifest.get("failures")) is int and manifest["failures"] == 0
            and whole(manifest.get("checks"), 1), "Failed or unsupported opening manifest")
    require(choice in OPERATIONS and manifest.get("inquiry_choice") == choice,
            "Requested inquiry choice differs from recorded route")
    operation_id(choice, task)
    require(manifest.get("household_task", "none") == task, "Requested household task differs from recorded endpoint")
    for field in ("progress_seeded", "capability_receipt_seeded", "camera_pose_injected",
                  "startup_save_seeded", "human_playtest", "historical_authentication"):
        require(manifest.get(field) is False, "Unsupported qualification claim: " + field)
    require(manifest.get("saved_pose_restored") is True and manifest.get("physics_hz") == 60
            and manifest.get("entry") == "actual HomeLaunch.enter"
            and str(manifest.get("engine", "")).startswith("4.5.1")
            and manifest.get("renderer") == "gl_compatibility", "Missing declared native execution boundaries")
    records = manifest["captures"]
    expected_captures = CAPTURES + (TASK_CAPTURES if task == "smith-commission" else ())
    require(isinstance(records, list) and tuple(item["id"] for item in records) == expected_captures,
            "Missing, extra or reordered opening captures")
    require({path.name for path in folder.glob("*.png")} == {name + ".png" for name in expected_captures},
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
    if choice == "independent_inquiry":
        expected_guard = {"visible": False, "collision_layer": 0,
                          "position": UNDEPLOYED_GUARD["position"], "yaw": 0, "velocity": [0, 0, 0]}
        require(manifest.get("route") and all(semantic_equal(item.get("escort_observation"), expected_guard)
                for item in [*records, *manifest["route"]]),
                "Independent route has a visible, colliding or moved native guard")
        refusal = manifest["independent_guard_refusal"]
        before, after = refusal["before_aftermath"], refusal["after_aftermath"]
        require(semantic_equal(before, after) and before["decision"] == choice
                and semantic_equal(before["escort"], UNDEPLOYED_GUARD)
                and semantic_equal(refusal["before_guard"], refusal["after_guard"]) and semantic_equal(refusal["after_guard"], expected_guard)
                and refusal["message"] == "No deployed household escort."
                and refusal["world_paused"] is False
                and whole(refusal["before_tick"]) and whole(refusal["after_tick"])
                and refusal["after_tick"] > refusal["before_tick"],
                "Independent guard refusal changed authority or stopped the ordinary clock")
        positions = [refusal[field] for field in ("before_player_position", "after_player_position")]
        require(all(isinstance(position, list) and len(position) == 3
                    and all(type(item) in (int, float) and math.isfinite(item) for item in position)
                    for position in positions)
                and math.hypot(positions[1][0]-positions[0][0], positions[1][2]-positions[0][2]) < .001,
                "Independent guard refusal displaced the stationary player")
    receipt = manifest["earned_training_receipt"]
    receipt_check(receipt)
    shots = manifest["native_shot_observations"]
    require(semantic_equal([item["slot"] for item in shots], [0, 1, 2, 3])
            and len({item["shot_id"] for item in shots}) == 4, "Missing distinct native weapon discharges")
    final = manifest["final_snapshot"]
    snapshot_check(final, receipt, "complete", choice)
    persistence = manifest["midreturn_persistence"]
    saved, restored = persistence["saved_snapshot"], persistence["restored_snapshot"]
    progressed = persistence["progressed_snapshot"]
    snapshot_check(saved, receipt, "return", choice)
    snapshot_check(restored, receipt, "return", choice)
    snapshot_check(progressed, receipt, "complete", choice)
    require(persistence.get("declared_saved_pose_restored") is True and semantic_equal(saved, restored)
            and progressed["childhood"]["tick"] > saved["childhood"]["tick"]
            and persistence["saved_tick"] == saved["childhood"]["tick"]
            and persistence["restored_tick"] == restored["childhood"]["tick"],
            "Native midreturn restore did not roll back the whole saved authority")
    require(persistence.get("retained_file") == "midreturn-save.json", "Missing retained native midreturn save")
    midreturn = folder / "midreturn-save.json"
    require(sha(midreturn.read_bytes()) == persistence["save_sha256"]
            and verify_native_save_bytes(midreturn.read_bytes(), saved),
            "Midreturn native-save digest or decoded authority mismatch")
    saved_final = json_read(final_save)
    require(sha(final_save.read_bytes()) == manifest["final_manual_save"]["sha256"]
            and verify_native_save_bytes(final_save.read_bytes(), manifest["final_manual_save"]["snapshot"]),
            "Final manual save digest or whole authority mismatch")
    snapshot_check(saved_final, receipt, "complete", choice)
    require(saved_final["childhood"]["tick"] <= final["childhood"]["tick"]
            and semantic_equal(native_save_projection(saved_final)["aftermath"], native_save_projection(final)["aftermath"])
            and semantic_equal(saved_final["riding_skills"], final["riding_skills"]),
            "Completed inquiry or earned receipt changed after the final save boundary")
    envelope = json_read(checkpoint)
    require(sha(checkpoint.read_bytes()) == manifest["production_automatic_checkpoint"]["sha256"]
            and envelope["schema"] == "1792.chapter-checkpoint.v1" and envelope["reason"] == "courtyard_return"
            and envelope["snapshot"]["childhood"]["ambush"]["status"] == "escaped"
            and envelope["snapshot"]["aftermath"]["memories"] == []
            and envelope["snapshot"]["aftermath"]["decision"] == ""
            and envelope["snapshot"]["aftermath"]["heard"] == []
            and envelope["snapshot"]["aftermath"]["offer_heard"] is False
            and semantic_equal(envelope["snapshot"]["aftermath"]["escort"], UNDEPLOYED_GUARD)
            and semantic_equal(envelope["snapshot"]["riding_skills"]["lesson_receipts"], [receipt]),
            "Production courtyard checkpoint digest or earned-state mismatch")
    if task == "smith-commission":
        task_check(folder, manifest, receipt, choice)
    return {"captures": len(records), "native_checks": manifest["checks"],
            "manifest_sha256": sha((folder / "manifest.json").read_bytes()),
            "earned_receipt_sha256": receipt["completion_sha256"],
            "native_midreturn_rollback_verified": True, "final_phase": "complete", "decision": choice,
            "household_task": task, "native_household_custody_rollback_verified": task == "smith-commission",
            "native_task_observation_clocks_verified": task == "smith-commission",
            "native_task_replay_tick_mirrors_verified": task == "smith-commission",
            "native_save_comparison": "exact original save bytes hashed; raw clock must equal integer-tick derivation; all original numeric lexemes reconstructed by pinned Godot4.5.1 parser; whole cold authority exact except declared binary32 escort poses"}


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


def verify_execution(folder: Path, source_commit: str | None = None, source_tree: str | None = None) -> dict:
    execution = json_read(folder / "execution.json")
    require(not source_commit or execution.get("source", {}).get("commit") == source_commit,
            "Requested source commit differs from retained execution")
    require(not source_tree or execution.get("source", {}).get("tree") == source_tree,
            "Requested source tree differs from retained execution")
    choice = execution["operation"]["parameters"]["inquiry_choice"]
    task = execution["operation"]["parameters"].get("household_task", "none")
    require(execution.get("schema") == "1792.opening-qualification-execution.v1"
            and choice in OPERATIONS and execution["operation"]["id"] == operation_id(choice, task)
            and execution["operation"]["script"] == SCRIPT
            and whole(execution["execution"]["exit_code"]) and execution["execution"]["exit_code"] == 0, "Failed or unsupported qualification execution")
    uuid.UUID(execution["execution"]["id"])
    started = datetime.fromisoformat(execution["execution"]["started_at"])
    ended = datetime.fromisoformat(execution["execution"]["ended_at"])
    require(started.tzinfo is not None and ended.tzinfo is not None and ended >= started,
            "Invalid retained execution interval")
    source = execution["source"]
    require(source["repository_id"] == 1392110087 and hex_id(source["commit"], 40)
            and hex_id(source["tree"], 40) and semantic_equal(source["before"], source["after"])
            and semantic_equal(source["before"], {"commit": source["commit"], "tree": source["tree"], "dirty": False}),
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
    for name in ("tools/qualify_opening.py", "tools/check_gujranwala_beauty_capture.py", "tools/godot451_json.py"):
        require(sha(files[name]) == sha((ROOT / name).read_bytes()), "Independent verifier differs from retained source: " + name)
    require(sha(files["game/tests/render_opening_chapter.gd"]) == execution["operation"]["script_sha256"],
            "Renderer operation source mismatch")
    runtime = execution["runtime"]
    require(hex_id(runtime["sha256"]) and whole(runtime["bytes"], 1)
            and runtime["after_sha256"] == runtime["sha256"]
            and re.match(r"^4\.5\.1[.-]stable", runtime["version"]), "Unqualified or changed Godot runtime identity")
    command = execution["execution"]["command"]
    expected_command = [runtime["executable"], "--fixed-fps", "60", "--path", "game", "--rendering-method",
                        "gl_compatibility", "--audio-driver", "Dummy", "--script", SCRIPT,
                        "--", "--inquiry-choice=" + choice]
    if task != "none":
        expected_command.append("--through-household-task=" + task)
    require(command == expected_command or command == ["xvfb-run", "-a", *expected_command],
            "Retained command does not identify the qualified opening operation")
    log = (folder / "renderer.log").read_bytes()
    require(sha(log) == execution["execution"]["log_sha256"]
            and not re.search(rb"(?m)^(?:SCRIPT ERROR|SHADER ERROR|ERROR):", log), "Renderer errors or log digest mismatch")
    result = check_manifest(folder / "opening-chapter-images", folder / "courtyard-checkpoint.json", folder / "final-manual-save.json", choice, task)
    require(result["manifest_sha256"] == execution["execution"]["manifest_sha256"], "Stale or replaced execution manifest")
    require(re.search(rb"(?m)^OPENING_CHAPTER_RENDER: " + str(result["captures"]).encode() + rb" captures; " + str(result["native_checks"]).encode()
                      + rb" checks; 0 failures$", log) is not None, "Renderer did not reach the exact qualification marker")
    return {"schema": "1792.opening-qualification-verification.v1", "status": "passed",
            "verification_id": str(uuid.uuid4()), "verified_at": datetime.now(timezone.utc).isoformat(),
            "execution_id": execution["execution"]["id"], "operation_id": operation_id(choice, task),
            "source_commit": source["commit"], "source_tree": source["tree"],
            "runtime_sha256": runtime["sha256"], "execution_sha256": sha((folder / "execution.json").read_bytes()),
            "verifier_sha256": sha((ROOT / "tools/qualify_opening.py").read_bytes()),
            "png_decoder_sha256": sha((ROOT / "tools/check_gujranwala_beauty_capture.py").read_bytes()),
            "godot_json_parser_sha256": sha((ROOT / "tools/godot451_json.py").read_bytes()),
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
               "gl_compatibility", "--audio-driver", "Dummy", "--script", SCRIPT,
               "--", "--inquiry-choice=" + args.inquiry_choice]
    if args.through_household_task != "none":
        command.append("--through-household-task=" + args.through_household_task)
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
                 "operation": {"id": operation_id(args.inquiry_choice, args.through_household_task), "script": SCRIPT,
                               "parameters": {"inquiry_choice": args.inquiry_choice, "household_task": args.through_household_task},
                               "script_sha256": sha((ROOT / "game/tests/render_opening_chapter.gd").read_bytes())},
                 "execution": {"id": str(uuid.uuid4()), "command": command, "started_at": started,
                               "ended_at": datetime.now(timezone.utc).isoformat(), "exit_code": code,
                               "log_sha256": sha(log), "manifest_sha256": sha((manifest_folder / "manifest.json").read_bytes()) if manifest else "absent"}}
    write_json(folder / "execution.json", execution)
    require(semantic_equal(before, after), "Source changed during qualification")
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
    parser.add_argument("--inquiry-choice", choices=tuple(OPERATIONS), default="household_escort")
    parser.add_argument("--through-household-task", choices=("none", "smith-commission"), default="none")
    args = parser.parse_args()
    try:
        require(args.verify_only or args.godot is not None, "--godot is required for execution")
        require(1 <= args.timeout <= 600, "Execution timeout must be 1–600 seconds")
        result = verify_execution(args.evidence_dir.resolve(), args.source_commit, args.source_tree) if args.verify_only else execute(args)
        require(result["decision"] == args.inquiry_choice,
                "Verified inquiry choice differs from caller's requested qualification")
        require(result["household_task"] == args.through_household_task,
                "Verified household task differs from caller's requested qualification")
        print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    except (OSError, ValueError, KeyError, TypeError, OverflowError, struct.error, zlib.error,
            tarfile.TarError, subprocess.SubprocessError) as error:
        parser.exit(1, "OPENING QUALIFICATION REFUSED: " + str(error) + "\n")


if __name__ == "__main__":
    raise SystemExit(main())
