"""Adversarial evidence tests; these synthetic records are not gameplay evidence."""
from __future__ import annotations

import copy
import hashlib
import json
import math
from pathlib import Path
import re
import struct
import subprocess
import tempfile
import unittest
import zlib

from qualify_opening import CAPTURES, TASK_CAPTURES, MEMORIES, SKILLS, UNDEPLOYED_GUARD, archive_tree, check_manifest, native_save_projection, operation_id, semantic_equal, sha, task_check, verify_execution
from godot451_json import NATIVE_SAVE_LIMIT, godot451_number, strict_json, verify_native_save_bytes


def chunk(kind: bytes, content: bytes) -> bytes:
    return struct.pack(">I", len(content)) + kind + content + struct.pack(">I", zlib.crc32(kind + content) & 0xffffffff)


class OpeningEvidenceChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        pixels = bytes((40, 27, 48, 255, 41, 28, 50, 255)) * (1280 * 720 // 2)
        rows = b"".join(b"\0" + pixels[y * 1280 * 4:(y + 1) * 1280 * 4] for y in range(720))
        cls.image = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1280, 720, 8, 6, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b""))
        cls.pixel_sha = sha(pixels)
        cls.receipt = {"schema": "1792.riding-training-receipt.v1", "lesson_id": "mahan-horsecraft-training.v1",
                       "subject_id": "ranjit_singh", "flashback_actor_id": "mahan_singh",
                       "historical_status": "user-attributed-unverified", "present_sha256": "a" * 64,
                       "entry_tick": 5, "completed_tick": 1169,
                       "milestones": [{"id": name, "tick": tick} for name, tick in zip(SKILLS, (144, 297, 1169))],
                       "facts": {"single_hold_ticks": 60, "paired_hold_ticks": 60,
                                 "volley_slots": [0, 1, 2, 3], "reloaded_slots": [0, 1, 2, 3]}}
        proof = {key: value for key, value in cls.receipt.items() if key not in ("schema", "present_sha256")}
        cls.receipt["completion_sha256"] = sha(json.dumps(proof, sort_keys=True, separators=(",", ":")).encode())

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        self.images = self.folder / "opening-chapter-images"
        self.images.mkdir()
        self.checkpoint = self.folder / "courtyard-checkpoint.json"
        self.final_save = self.folder / "final-manual-save.json"
        saved = self.snapshot(False, 40)
        progressed = self.snapshot(True, 50)
        final = self.snapshot(True, 60)
        checkpoint_state = copy.deepcopy(saved)
        checkpoint_state["aftermath"]["memories"] = []
        checkpoint_state["aftermath"].update(decision="", heard=[], offer_heard=False,
                                              escort=copy.deepcopy(UNDEPLOYED_GUARD))
        self.write(self.checkpoint, {"schema": "1792.chapter-checkpoint.v1", "reason": "courtyard_return",
                                     "snapshot": checkpoint_state})
        self.write(self.final_save, final)
        self.write(self.images / "midreturn-save.json", saved)
        self.manifest = {"schema": "1792.opening-chapter-render.v2", "failures": 0, "checks": 200,
                         "inquiry_choice": "household_escort",
                         "progress_seeded": False, "capability_receipt_seeded": False, "camera_pose_injected": False,
                         "startup_save_seeded": False, "human_playtest": False, "historical_authentication": False,
                         "saved_pose_restored": True, "physics_hz": 60, "entry": "actual HomeLaunch.enter",
                         "engine": "4.5.1-stable (official)", "renderer": "gl_compatibility",
                         "earned_training_receipt": copy.deepcopy(self.receipt),
                         "native_shot_observations": [{"slot": slot, "shot_id": "shot-" + str(slot)} for slot in range(4)],
                         "earned_focus_motion": {
                             "classification": "automated earned player-input journey; not a human playtest",
                             "actor": "production household escort",
                             "movement_source": "displayed protection choice, native G orders and production escort motor",
                             "observer_id": "ranjit_singh", "sensor_id": "character-eye",
                             "identified_observation": {"id": "household_guard", "label": "Household guard", "kind": "ally",
                                                        "observer_id": "ranjit_singh", "sensor_id": "character-eye",
                                                        "position": [-6.9, 1.25, 9.2], "seen_tick": 70, "expires_tick": 670},
                             "estimate": {"position": [-1.1, 1.25, 1.1], "origin_position": [-5.8, 1.25, 7.6],
                                          "from_ticks": [45, 75], "expires_tick": 195, "kind": "estimate",
                                          "observer_id": "ranjit_singh", "sensor_id": "character-eye"},
                             "estimate_tick": 75, "retracted_tick": 90,
                             "actor_pose_or_velocity_injected": False, "sensor_pose_injected": False,
                             "route_read": False, "affiliation_read": False, "authored_gameplay_envelope": True,
                             "measured_physiology": False, "authenticated_history": False},
                         "route": [{"id": "household-escort-focus-motion-earned", "home_tick": 92,
                                    "aftermath": {"escort": {"active": True, "instruction": "follow"}},
                                    "escort_observation": {"visible": True, "collision_layer": 2}}],
                         "final_snapshot": final,
                         "midreturn_persistence": {"saved_snapshot": saved, "restored_snapshot": copy.deepcopy(saved),
                                                   "progressed_snapshot": progressed, "saved_tick": 40, "restored_tick": 40,
                                                   "declared_saved_pose_restored": True, "retained_file": "midreturn-save.json",
                                                   "save_sha256": sha((self.images / "midreturn-save.json").read_bytes())},
                         "final_manual_save": {"sha256": sha(self.final_save.read_bytes()), "snapshot": final},
                         "production_automatic_checkpoint": {"sha256": sha(self.checkpoint.read_bytes())}, "captures": []}
        for name in CAPTURES:
            (self.images / (name + ".png")).write_bytes(self.image)
            self.manifest["captures"].append({"id": name, "file": name + ".png", "camera_pose_injected": False,
                                              "inspection_camera_only": False, "pixel_format": "rgba8", "width": 1280,
                                              "height": 720, "camera_kind": "production-gameplay", "state_sha256": "b" * 64,
                                              "sha256": sha(self.image), "pixel_sha256": self.pixel_sha})
        self.update()

    def snapshot(self, complete: bool, tick: int) -> dict:
        ids = MEMORIES if complete else MEMORIES[:-1]
        return {"player": {"character_id": "ranjit_singh"},
                "game_time": self.clock_for_tick(tick),
                "childhood": {"tick": tick, "ambush": {"status": "escaped", "hits": 0}, "ride_gate": 3,
                              "parries": 2, "counters": 1, "tracks": 3, "quarry_seen": True},
                "riding": {"horse": {"grounded": True}},
                "riding_skills": {"lesson_receipts": [copy.deepcopy(self.receipt)]},
                "aftermath": {"decision": "household_escort", "heard": MEMORIES[:2], "offer_heard": True,
                              "decision_tick": 10, "clue_tick": 20, "reported_tick": 30 if complete else -1,
                              "escort": {"active": not complete, "instruction": "hold" if complete else "follow",
                                         "position": [6.1432061195373535, 0.14, -11], "yaw": 0.0, "velocity": [0, 0, 0]},
                              "memories": [{"id": name, "received_tick": 5 + i * 5,
                                            "text": "The riders remain unidentified."} for i, name in enumerate(ids)]}}

    @staticmethod
    def clock_for_tick(tick):
        hours = 7.0 + tick / 216000.0
        return {"year": 1792, "day": 1 + int(hours / 24.0), "hour": math.fmod(hours, 24.0)}

    @staticmethod
    def write(path: Path, value: dict) -> None:
        path.write_text(json.dumps(value), encoding="utf-8")

    def update(self):
        self.write(self.images / "manifest.json", self.manifest)

    def verify(self):
        return check_manifest(self.images, self.checkpoint, self.final_save)

    def independent(self):
        self.manifest["inquiry_choice"] = "independent_inquiry"
        self.manifest["earned_focus_motion"] = {}
        snapshots = [self.manifest["final_snapshot"], self.manifest["final_manual_save"]["snapshot"],
                     *[self.manifest["midreturn_persistence"][field]
                       for field in ("saved_snapshot", "restored_snapshot", "progressed_snapshot")]]
        for snapshot in snapshots:
            after = snapshot["aftermath"]
            after["decision"] = "independent_inquiry"
            after["escort"] = copy.deepcopy(UNDEPLOYED_GUARD)
            after["memories"][3]["id"] = "independent_inquiry"
        observed = {"visible": False, "collision_layer": 0,
                    "position": UNDEPLOYED_GUARD["position"], "yaw": 0, "velocity": [0, 0, 0]}
        for record in self.manifest["captures"]:
            record["escort_observation"] = copy.deepcopy(observed)
        self.manifest["route"] = [{"escort_observation": copy.deepcopy(observed)}]
        refusal_after = copy.deepcopy(self.manifest["midreturn_persistence"]["saved_snapshot"]["aftermath"])
        self.manifest["independent_guard_refusal"] = {
            "before_aftermath": refusal_after, "after_aftermath": copy.deepcopy(refusal_after),
            "before_guard": copy.deepcopy(observed), "after_guard": copy.deepcopy(observed),
            "message": "No deployed household escort.", "world_paused": False,
            "before_tick": 10, "after_tick": 13,
            "before_player_position": [-5, .1, 7], "after_player_position": [-5, .1, 7]}
        self.write(self.final_save, self.manifest["final_manual_save"]["snapshot"])
        self.manifest["final_manual_save"]["sha256"] = sha(self.final_save.read_bytes())
        self.write(self.images / "midreturn-save.json", self.manifest["midreturn_persistence"]["saved_snapshot"])
        self.manifest["midreturn_persistence"]["save_sha256"] = sha((self.images / "midreturn-save.json").read_bytes())
        self.update()

    def task_manifest(self, choice="household_escort"):
        """Synthetic canonical commission; no model execution or gameplay claim.

        Exercise custody directly so the existing image adversaries are not
        repeated for each independently tampered economic boundary.
        """
        inquiry = self.snapshot(True, 2000)
        if choice == "independent_inquiry":
            inquiry["aftermath"]["decision"] = choice
            inquiry["aftermath"]["memories"][3]["id"] = choice
            inquiry["aftermath"]["escort"] = copy.deepcopy(UNDEPLOYED_GUARD)
        ledger = {"purse": 18, "treasury": 120,
                  "stock": {"food": 10, "feed": 8, "grain": 8, "timber": 8, "tools": 2},
                  "workers": 1, "guards": 0, "horses": 1, "watch": 0, "arrears": 0,
                  "food_shortfall": 0, "feed_shortfall": 0, "duty_guards": 0,
                  "favor": 50, "meeting": "pending", "satchel": False,
                  "delivery": "available", "caravan": "locked", "cargo": 0,
                  "build": "", "work_left": 0, "built": [],
                  "last_notice": "A bounded household allowance, not ownership of all royal funds."}
        economy = {"schema": "gujranwala-misl.v1", "cell_id": "gujranwala-home-cell.v1", "seed": 1792,
                   "origin_tick": 2005, "ledger": ledger, "events": [],
                   "merchant": {"id": "home_caravan_01", "position": [-23, .14, -15],
                                "yaw": 0, "velocity": [0, 0, 0]}}
        ticks = (2020, 2100, 2700, 2710, 2800)
        events = [{"seq": i + 1, "tick": tick, "kind": "smith." + kind, "arg": str(tick)}
                  for i, (tick, kind) in enumerate(zip(ticks, ("reserve", "start", "ready", "collect", "deliver")))]
        phases = ("unassigned", "fuel", "working", "tools", "complete")
        records = []
        for name, phase, tick, prefix in zip(TASK_CAPTURES, phases, (2008, 2030, 2103, 2713, 2803), (0, 1, 2, 4, 5)):
            state = copy.deepcopy(inquiry)
            state["childhood"]["tick"] = tick
            state["game_time"] = self.clock_for_tick(tick)
            state["misl"] = copy.deepcopy(economy)
            state["misl"]["events"] = copy.deepcopy(events[:prefix])
            stock = state["misl"]["ledger"]
            if phase != "unassigned":
                stock["treasury"] = 116
                stock["stock"]["timber"] = 6
                started = phase in ("working", "tools", "complete")
                collected = phase in ("tools", "complete")
                stock["workshop"] = {"schema": "home-courtyard-smith.v2", "phase": phase,
                                     "reserved_tick": ticks[0], "started_tick": ticks[1] if started else -1,
                                     "ready_tick": ticks[2] if collected else -1,
                                     "picked_up_tick": ticks[3] if collected else -1,
                                     "settled_tick": ticks[4] if phase == "complete" else -1,
                                     "fuel_carried": 0 if started else 2, "fuel_used": 2 if started else 0,
                                     "tools_carried": 2 if phase == "tools" else 0,
                                     "fee_held": 0 if started else 4, "fee_paid": 4 if started else 0}
            if phase == "complete":
                stock["stock"]["tools"] = 4
                stock["favor"] = 53
            smith = phase in ("fuel", "working")
            records.append({"id": name, "snapshot": state,
                            # Keep authority adversaries internally coherent; the
                            # metadata-only adversary below detaches each mirror.
                            "home_tick": tick, "progress": state["childhood"],
                            "economy": state["misl"], "workshop_phase": phase,
                            "workshop": state["misl"]["ledger"].get("workshop", {}),
                            "aftermath": state["aftermath"],
                            "hud": {"compact_visible": True, "legacy_visible": False,
                                    "task": "First household responsibility complete" if phase == "complete" else "Synthetic custody boundary"},
                            "objective_marker": {"visible": True, "text": "Smith · E" if smith else "Quartermaster · E",
                                                 "position": [-15, 2.240000009536743, 8] if smith else [3, 2.240000009536743, 5]}})
        final = copy.deepcopy(records[-1]["snapshot"])
        final["childhood"]["tick"] = 2806
        final["game_time"] = self.clock_for_tick(2806)
        saved = copy.deepcopy(records[1]["snapshot"])
        persistence = {"inquiry_snapshot": inquiry, "saved_snapshot": saved,
                       "restored_snapshot": copy.deepcopy(saved),
                       "progressed_snapshot": copy.deepcopy(records[2]["snapshot"]),
                       "saved_tick": 2030, "restored_tick": 2030, "progressed_tick": 2103,
                       "final_snapshot": copy.deepcopy(final), "final_tick": 2806,
                       "final_task_completed": True,
                       "declared_saved_pose_restored": True, "retained_file": "household-fuel-save.json"}
        manual = copy.deepcopy(final)
        manual["childhood"]["tick"] = 2803
        manual["game_time"] = self.clock_for_tick(2803)
        manifest = {"captures": records, "final_snapshot": final,
                    "final_manual_save": {"snapshot": manual}, "household_task_persistence": persistence}
        self.write(self.images / "inquiry-manual-save.json", inquiry)
        persistence["inquiry_save_sha256"] = sha((self.images / "inquiry-manual-save.json").read_bytes())
        self.task_save(manifest)
        return manifest

    def task_save(self, manifest):
        """Keep raw-save bindings current while testing semantic tampering."""
        persistence = manifest["household_task_persistence"]
        self.write(self.images / "household-fuel-save.json", persistence["saved_snapshot"])
        persistence["save_sha256"] = sha((self.images / "household-fuel-save.json").read_bytes())

    def verify_task(self, manifest, choice="household_escort"):
        return task_check(self.images, manifest, self.receipt, choice)

    def test_synthetic_commission_custody_is_valid_for_each_inquiry_choice(self):
        for choice in ("household_escort", "independent_inquiry"):
            with self.subTest(choice=choice):
                self.verify_task(self.task_manifest(choice), choice)
                self.assertEqual(operation_id(choice, "smith-commission"),
                                 "1792.opening-" + ("household" if choice == "household_escort" else "independent") + "-responsibility.v1")

    def test_commission_cannot_shorten_native_six_hundred_tick_deadline(self):
        manifest = self.task_manifest()
        event = manifest["final_snapshot"]["misl"]["events"][2]
        event.update(tick=2699, arg="2699")
        with self.assertRaisesRegex(ValueError, "native deadline"):
            self.verify_task(manifest)

    def test_commission_cannot_duplicate_a_physical_delivery(self):
        manifest = self.task_manifest()
        events = manifest["final_snapshot"]["misl"]["events"]
        duplicate = copy.deepcopy(events[-1])
        duplicate["seq"] = 6
        events.append(duplicate)
        with self.assertRaisesRegex(ValueError, "duplicated"):
            self.verify_task(manifest)

    def test_commission_cannot_claim_free_output_or_missing_carried_custody(self):
        for record, field, value in ((1, "fuel_carried", 1), (1, "fee_held", 0),
                                     (2, "tools_carried", 2), (3, "tools_carried", 0)):
            with self.subTest(record=record, field=field):
                manifest = self.task_manifest()
                manifest["captures"][record]["snapshot"]["misl"]["ledger"]["workshop"][field] = value
                with self.assertRaises(ValueError):
                    self.verify_task(manifest)

    def test_commission_conserves_personal_and_household_money_and_stock(self):
        for field, key in (("purse", None), ("treasury", None), ("stock", "timber"), ("stock", "tools"), ("stock", "food")):
            with self.subTest(field=field, key=key):
                manifest = self.task_manifest()
                ledger = manifest["captures"][2]["snapshot"]["misl"]["ledger"]
                if key is None:
                    ledger[field] += 1
                else:
                    ledger[field][key] += 1
                with self.assertRaisesRegex(ValueError, "minted money|delivered materials"):
                    self.verify_task(manifest)

    def test_commission_keeps_original_merchant_and_cell_identity(self):
        manifest = self.task_manifest()
        manifest["captures"][3]["snapshot"]["misl"]["merchant"]["id"] = "free-replacement-caravan"
        with self.assertRaisesRegex(ValueError, "merchant authority"):
            self.verify_task(manifest)

    def test_commission_keeps_earned_skill_receipt_and_retired_guard(self):
        for field in ("receipt", "guard"):
            with self.subTest(field=field):
                manifest = self.task_manifest()
                state = manifest["captures"][2]["snapshot"]
                if field == "receipt":
                    state["riding_skills"]["lesson_receipts"] = []
                else:
                    state["aftermath"]["escort"]["position"][0] += .5
                with self.assertRaisesRegex(ValueError, "receipt was lost|retired guard"):
                    self.verify_task(manifest)

    def test_commission_fuel_rollback_is_whole_and_keeps_carried_custody(self):
        manifest = self.task_manifest()
        manifest["household_task_persistence"]["restored_snapshot"]["player"]["extra_progress"] = 1
        with self.assertRaisesRegex(ValueError, "exact whole carried custody"):
            self.verify_task(manifest)

    def test_commission_fuel_save_cannot_preserve_a_moved_guard_or_missing_load(self):
        for field in ("guard", "fuel"):
            with self.subTest(field=field):
                manifest = self.task_manifest()
                persistence = manifest["household_task_persistence"]
                for key in ("saved_snapshot", "restored_snapshot"):
                    state = persistence[key]
                    if field == "guard":
                        state["aftermath"]["escort"]["position"][0] += .5
                    else:
                        state["misl"]["ledger"]["workshop"]["fuel_carried"] = 1
                self.task_save(manifest)
                with self.assertRaises(ValueError):
                    self.verify_task(manifest)

    def test_commission_final_live_guard_cannot_diverge_from_earned_inquiry(self):
        manifest = self.task_manifest()
        manifest["final_snapshot"]["aftermath"]["escort"]["position"][0] += .5
        with self.assertRaises(ValueError):
            self.verify_task(manifest)

    def test_commission_receipt_prefix_and_settled_workshop_clocks_are_exact(self):
        for field in ("prefix", "workshop"):
            with self.subTest(field=field):
                manifest = self.task_manifest()
                if field == "prefix":
                    event = manifest["captures"][1]["snapshot"]["misl"]["events"][0]
                    event.update(tick=2021, arg="2021")
                else:
                    for state in (manifest["final_snapshot"], manifest["captures"][-1]["snapshot"]):
                        state["misl"]["ledger"]["workshop"]["ready_tick"] -= 1
                with self.assertRaisesRegex(ValueError, "receipt prefix|custody.*receipts"):
                    self.verify_task(manifest)

    def test_commission_capture_cannot_precede_its_custody_receipt(self):
        manifest = self.task_manifest()
        record = manifest["captures"][2]
        record["snapshot"]["childhood"]["tick"] = 2099
        record["snapshot"]["game_time"] = self.clock_for_tick(2099)
        record["home_tick"] = 2099
        with self.assertRaises(ValueError):
            self.verify_task(manifest)

    def test_commission_inquiry_cannot_have_a_premature_allowance(self):
        manifest = self.task_manifest()
        persistence = manifest["household_task_persistence"]
        persistence["inquiry_snapshot"]["misl"] = copy.deepcopy(manifest["captures"][0]["snapshot"]["misl"])
        with self.assertRaisesRegex(ValueError, "unearned allowance"):
            self.verify_task(manifest)

    def test_commission_native_fuel_bytes_remain_independently_bound(self):
        manifest = self.task_manifest()
        (self.images / "household-fuel-save.json").write_bytes(b"{}")
        with self.assertRaisesRegex(ValueError, "fuel save bytes"):
            self.verify_task(manifest)

    def test_commission_cannot_seed_extra_allowance_food_consistently(self):
        manifest = self.task_manifest()
        persistence = manifest["household_task_persistence"]
        states = [*[item["snapshot"] for item in manifest["captures"]], manifest["final_snapshot"],
                  manifest["final_manual_save"]["snapshot"],
                  *[persistence[key] for key in ("saved_snapshot", "restored_snapshot", "progressed_snapshot")]]
        for state in states:
            state["misl"]["ledger"]["stock"]["food"] += 1
        self.task_save(manifest)
        with self.assertRaises(ValueError):
            self.verify_task(manifest)

    def test_commission_every_saved_boundary_binds_receipts_to_its_own_clock(self):
        for boundary in ("fuel", "progressed", "final_manual"):
            with self.subTest(boundary=boundary):
                manifest = self.task_manifest()
                persistence = manifest["household_task_persistence"]
                if boundary == "fuel":
                    for key in ("saved_snapshot", "restored_snapshot"):
                        persistence[key]["childhood"]["tick"] = 2019
                        persistence[key]["game_time"] = self.clock_for_tick(2019)
                    persistence["saved_tick"] = persistence["restored_tick"] = 2019
                    self.task_save(manifest)
                elif boundary == "progressed":
                    persistence["progressed_snapshot"]["childhood"]["tick"] = 2099
                    persistence["progressed_snapshot"]["game_time"] = self.clock_for_tick(2099)
                    persistence["progressed_tick"] = 2099
                else:
                    manifest["final_manual_save"]["snapshot"]["childhood"]["tick"] = 2799
                    manifest["final_manual_save"]["snapshot"]["game_time"] = self.clock_for_tick(2799)
                with self.assertRaises(ValueError):
                    self.verify_task(manifest)

    def test_commission_progressed_handover_cannot_hide_a_money_grant(self):
        manifest = self.task_manifest()
        manifest["household_task_persistence"]["progressed_snapshot"]["misl"]["ledger"]["purse"] += 10
        with self.assertRaises(ValueError):
            self.verify_task(manifest)

    def test_commission_requires_the_visible_actual_custody_target(self):
        for defect in ("missing", "wrong", "hidden"):
            with self.subTest(defect=defect):
                manifest = self.task_manifest()
                marker = manifest["captures"][1]["objective_marker"]
                if defect == "missing":
                    marker.pop("position")
                elif defect == "wrong":
                    marker.update(text="Quartermaster · E", position=[3, 2.240000009536743, 5])
                else:
                    marker["visible"] = False
                with self.assertRaisesRegex(ValueError, "actual custody speaker"):
                    self.verify_task(manifest)

    def test_commission_capture_mirrors_cannot_disagree_with_whole_authority(self):
        for field in ("home_tick", "progress", "economy", "workshop_phase", "workshop", "aftermath"):
            with self.subTest(field=field):
                manifest = self.task_manifest()
                record = manifest["captures"][2]
                original = copy.deepcopy(record["snapshot"])
                record[field] = copy.deepcopy(record[field])
                if field == "home_tick":
                    record[field] += 1
                elif field == "progress":
                    record[field]["tick"] += 1
                elif field == "economy":
                    record[field]["ledger"]["treasury"] += 1
                elif field == "workshop_phase":
                    record[field] = "ready"
                elif field == "workshop":
                    record[field]["fuel_used"] = 0
                else:
                    record[field]["reported_tick"] += 1
                self.assertEqual(record["snapshot"], original)
                with self.assertRaisesRegex(ValueError, "Household capture metadata disagrees with its whole authority"):
                    self.verify_task(manifest)

    def test_midreturn_whole_rollback_cannot_alias_a_boolean_to_an_integer(self):
        self.manifest["midreturn_persistence"]["restored_snapshot"]["riding"]["horse"]["grounded"] = 1
        self.update()
        with self.assertRaisesRegex(ValueError, "whole saved authority"):
            self.verify()

    def test_commission_whole_fuel_rollback_cannot_alias_a_boolean_to_an_integer(self):
        manifest = self.task_manifest()
        manifest["household_task_persistence"]["restored_snapshot"]["riding"]["horse"]["grounded"] = 1
        with self.assertRaisesRegex(ValueError, "exact whole carried custody"):
            self.verify_task(manifest)

    def test_commission_capture_mirrors_refuse_boolean_numeric_aliases(self):
        for field in ("progress", "economy"):
            with self.subTest(field=field):
                manifest = self.task_manifest()
                record = manifest["captures"][2]
                original = copy.deepcopy(record["snapshot"])
                record[field] = copy.deepcopy(record[field])
                if field == "progress":
                    record[field]["quarry_seen"] = 1
                else:
                    record[field]["ledger"]["satchel"] = 0
                self.assertIs(record["snapshot"]["childhood"]["quarry_seen"], True)
                self.assertIs(record["snapshot"]["misl"]["ledger"]["satchel"], False)
                self.assertEqual(record["snapshot"], original)
                with self.assertRaisesRegex(ValueError, "Household capture metadata disagrees with its whole authority"):
                    self.verify_task(manifest)

    def test_commission_ledger_and_expected_custody_refuse_boolean_numeric_aliases(self):
        for boundary in ("initial", "stable", "workshop"):
            with self.subTest(boundary=boundary):
                manifest = self.task_manifest()
                if boundary == "initial":
                    manifest["captures"][0]["snapshot"]["misl"]["ledger"]["satchel"] = 0
                elif boundary == "stable":
                    manifest["captures"][2]["snapshot"]["misl"]["ledger"]["satchel"] = 0
                else:
                    manifest["captures"][1]["snapshot"]["misl"]["ledger"]["workshop"]["fuel_used"] = False
                with self.assertRaises(ValueError):
                    self.verify_task(manifest)

    def test_independent_guard_visibility_cannot_alias_false_to_zero(self):
        self.independent()
        self.manifest["captures"][-1]["escort_observation"]["visible"] = 0
        self.update()
        with self.assertRaisesRegex(ValueError, "native guard"):
            check_manifest(self.images, self.checkpoint, self.final_save, "independent_inquiry")

    def test_commission_marker_visibility_cannot_alias_true_to_one(self):
        manifest = self.task_manifest()
        manifest["captures"][1]["objective_marker"]["visible"] = 1
        with self.assertRaisesRegex(ValueError, "actual custody speaker"):
            self.verify_task(manifest)

    def test_commission_equivalent_finite_integer_float_metadata_stays_valid(self):
        manifest = self.task_manifest()
        record = manifest["captures"][1]
        record["home_tick"] = float(record["home_tick"])
        record["snapshot"]["misl"]["ledger"]["workers"] = 1.0
        self.verify_task(manifest)

    def test_nested_semantic_equality_refuses_nonfinite_and_boolean_numeric_aliases(self):
        self.assertTrue(semantic_equal({"nested": [1, {"value": 0}]},
                                       {"nested": [1.0, {"value": 0.0}]}))
        for expected, recorded in ((True, 1), (False, 0), (math.inf, math.inf),
                                   (-math.inf, -math.inf), (math.nan, math.nan)):
            with self.subTest(expected=expected, recorded=recorded):
                self.assertFalse(semantic_equal({"nested": [expected]}, {"nested": [recorded]}))

    def test_opening_numeric_receipt_shot_and_progress_slots_refuse_booleans(self):
        original = copy.deepcopy(self.manifest)
        retained = (self.final_save, self.images / "midreturn-save.json", self.checkpoint)
        raw_hashes = [sha(path.read_bytes()) for path in retained]
        for field in ("volley_slot", "reloaded_slot", "shot_slot", "counter", "ambush_hits", "tick"):
            with self.subTest(field=field):
                self.manifest = copy.deepcopy(original)
                if field in ("volley_slot", "reloaded_slot"):
                    slots = "volley_slots" if field == "volley_slot" else "reloaded_slots"
                    self.manifest["earned_training_receipt"]["facts"][slots][0] = False
                elif field == "shot_slot":
                    self.manifest["native_shot_observations"][0]["slot"] = False
                elif field == "ambush_hits":
                    self.manifest["final_snapshot"]["childhood"]["ambush"]["hits"] = False
                else:
                    child = self.manifest["final_snapshot"]["childhood"]
                    child["counters" if field == "counter" else "tick"] = True
                self.update()
                with self.assertRaisesRegex(ValueError, "Incomplete earned riding facts|distinct native weapon|nonliving native opening"):
                    self.verify()
                self.assertEqual([sha(path.read_bytes()) for path in retained], raw_hashes)

    def test_midreturn_progressed_guard_velocity_cannot_alias_false_to_zero(self):
        retained = (self.final_save, self.images / "midreturn-save.json")
        raw_hashes = [sha(path.read_bytes()) for path in retained]
        self.manifest["midreturn_persistence"]["progressed_snapshot"]["aftermath"]["escort"]["velocity"][0] = False
        self.update()
        with self.assertRaisesRegex(ValueError, "report/escort retirement"):
            self.verify()
        self.assertEqual([sha(path.read_bytes()) for path in retained], raw_hashes)

    def test_commission_fresh_observation_clock_must_match_its_exact_tick(self):
        for boundary in ("capture", "progressed", "final"):
            for field in ("hour", "year", "day", "tick_boolean", "hour_lower_ulp", "hour_upper_ulp", "nonfinite_hour", "missing_clock"):
                with self.subTest(boundary=boundary, field=field):
                    manifest = self.task_manifest()
                    if boundary == "capture":
                        state = manifest["captures"][3]["snapshot"]
                    elif boundary == "progressed":
                        state = manifest["household_task_persistence"]["progressed_snapshot"]
                    else:
                        state = manifest["final_snapshot"]
                    if field == "tick_boolean":
                        state["childhood"]["tick"] = True
                    elif field in ("hour_lower_ulp", "hour_upper_ulp"):
                        direction = -math.inf if field == "hour_lower_ulp" else math.inf
                        state["game_time"]["hour"] = math.nextafter(state["game_time"]["hour"], direction)
                    elif field == "nonfinite_hour":
                        state["game_time"]["hour"] = math.inf
                    elif field == "missing_clock":
                        state.pop("game_time")
                    else:
                        state["game_time"][field] += 1
                    raw_hash = sha((self.images / "household-fuel-save.json").read_bytes())
                    with self.assertRaises(ValueError):
                        self.verify_task(manifest)
                    self.assertEqual(sha((self.images / "household-fuel-save.json").read_bytes()), raw_hash)

    def test_commission_all_native_tick_mirrors_require_whole_matching_numbers(self):
        for field in ("saved_tick", "restored_tick", "progressed_tick", "final_tick"):
            for defect in ("boolean", "string", "fractional", "wrong_tick", "nonfinite", "missing"):
                with self.subTest(field=field, defect=defect):
                    manifest = self.task_manifest()
                    persistence = manifest["household_task_persistence"]
                    original = persistence[field]
                    if defect == "missing":
                        persistence.pop(field)
                    else:
                        persistence[field] = {"boolean": False, "string": str(original),
                                              "fractional": original + .5, "wrong_tick": original + 1,
                                              "nonfinite": math.inf}[defect]
                    raw_hash = sha((self.images / "household-fuel-save.json").read_bytes())
                    with self.assertRaises((ValueError, KeyError) if defect == "missing" else ValueError):
                        self.verify_task(manifest)
                    self.assertEqual(sha((self.images / "household-fuel-save.json").read_bytes()), raw_hash)
        manifest = self.task_manifest()
        manifest["household_task_persistence"]["inquiry_snapshot"]["childhood"]["tick"] = True
        with self.assertRaises(ValueError):
            self.verify_task(manifest)
        manifest = self.task_manifest()
        for field in ("saved_tick", "restored_tick", "progressed_tick", "final_tick"):
            manifest["household_task_persistence"][field] = float(manifest["household_task_persistence"][field])
        self.verify_task(manifest)

    def test_commission_final_persistence_requires_the_actual_complete_whole_observation(self):
        for defect in ("boolean_alias", "incomplete", "clock", "whole_state"):
            with self.subTest(defect=defect):
                manifest = self.task_manifest()
                persistence = manifest["household_task_persistence"]
                if defect == "boolean_alias":
                    persistence["final_task_completed"] = 1
                elif defect == "incomplete":
                    persistence["final_task_completed"] = False
                elif defect == "clock":
                    persistence["final_snapshot"]["game_time"]["hour"] += 1
                else:
                    persistence["final_snapshot"]["player"]["invented_progress"] = True
                with self.assertRaises(ValueError):
                    self.verify_task(manifest)

    def test_commission_receipt_sequence_and_capture_prefix_refuse_boolean_one(self):
        for boundary in ("prefix", "final"):
            with self.subTest(boundary=boundary):
                manifest = self.task_manifest()
                raw_hash = sha((self.images / "household-fuel-save.json").read_bytes())
                state = manifest["captures"][1]["snapshot"] if boundary == "prefix" else manifest["final_snapshot"]
                state["misl"]["events"][0]["seq"] = True
                with self.assertRaisesRegex(ValueError, "Household economic receipt"):
                    self.verify_task(manifest)
                self.assertEqual(sha((self.images / "household-fuel-save.json").read_bytes()), raw_hash)

    def test_commission_final_handoff_cannot_fall_back_to_legacy_guidance(self):
        for field, value in (("legacy_visible", True), ("compact_visible", False), ("task", "Speak to the quartermaster")):
            with self.subTest(field=field):
                manifest = self.task_manifest()
                manifest["captures"][-1]["hud"][field] = value
                with self.assertRaisesRegex(ValueError, "dense legacy guidance|settled first-responsibility handoff"):
                    self.verify_task(manifest)

    def test_requested_choice_cannot_be_relabelled(self):
        self.manifest["inquiry_choice"] = "independent_inquiry"
        self.update()
        with self.assertRaisesRegex(ValueError, "Requested inquiry choice"):
            self.verify()

    def test_explicit_verification_source_commit_cannot_be_ignored(self):
        self.write(self.folder / "execution.json", {"source": {"commit": "a" * 40, "tree": "b" * 40}})
        with self.assertRaisesRegex(ValueError, "Requested source commit"):
            verify_execution(self.folder, source_commit="c" * 40)

    def test_explicit_verification_source_tree_cannot_be_ignored(self):
        self.write(self.folder / "execution.json", {"source": {"commit": "a" * 40, "tree": "b" * 40}})
        with self.assertRaisesRegex(ValueError, "Requested source tree"):
            verify_execution(self.folder, source_tree="c" * 40)

    def test_independent_consistency_and_no_free_guard(self):
        self.independent()
        result = check_manifest(self.images, self.checkpoint, self.final_save, "independent_inquiry")
        self.assertEqual(result["decision"], "independent_inquiry")
        self.manifest["captures"][-1]["escort_observation"]["collision_layer"] = 1
        self.update()
        with self.assertRaisesRegex(ValueError, "native guard"):
            check_manifest(self.images, self.checkpoint, self.final_save, "independent_inquiry")

    def test_independent_branch_cannot_gain_deployed_guard(self):
        self.independent()
        self.manifest["final_snapshot"]["aftermath"]["escort"]["active"] = True
        self.update()
        with self.assertRaisesRegex(ValueError, "report/escort retirement"):
            check_manifest(self.images, self.checkpoint, self.final_save, "independent_inquiry")

    def test_independent_refusal_cannot_grant_knowledge_or_stop_time(self):
        self.independent()
        self.manifest["independent_guard_refusal"]["after_tick"] = 10
        self.update()
        with self.assertRaisesRegex(ValueError, "guard refusal changed authority"):
            check_manifest(self.images, self.checkpoint, self.final_save, "independent_inquiry")

    def test_valid_recorded_consistency(self):
        result = self.verify()
        self.assertEqual(result["captures"], 18)
        self.assertTrue(result["native_midreturn_rollback_verified"])

    def test_earned_focus_motion_refuses_actor_state_or_overstated_claims(self):
        for defect in ("velocity", "route", "human", "physiology", "history"):
            with self.subTest(defect=defect):
                original = copy.deepcopy(self.manifest["earned_focus_motion"])
                if defect in ("velocity", "route"):
                    self.manifest["earned_focus_motion"]["estimate"][defect] = [1, 0, 0]
                elif defect == "human":
                    self.manifest["earned_focus_motion"]["classification"] = "human playtest"
                elif defect == "physiology":
                    self.manifest["earned_focus_motion"]["measured_physiology"] = True
                else:
                    self.manifest["earned_focus_motion"]["authenticated_history"] = True
                self.update()
                with self.assertRaises(ValueError):
                    self.verify()
                self.manifest["earned_focus_motion"] = original
        self.update()

    def test_png_byte_tamper_and_pixel_identity_are_independent(self):
        image = self.images / (CAPTURES[0] + ".png")
        image.write_bytes(self.image[:-12] + chunk(b"tEXt", b"note\0tampered") + self.image[-12:])
        with self.assertRaisesRegex(ValueError, "byte/pixel mismatch"):
            self.verify()
        image.write_bytes(self.image)
        self.manifest["captures"][0]["pixel_sha256"] = "c" * 64
        self.update()
        with self.assertRaisesRegex(ValueError, "byte/pixel mismatch"):
            self.verify()

    def test_missing_extra_and_reordered_captures_refused(self):
        self.manifest["captures"].pop()
        self.update()
        with self.assertRaisesRegex(ValueError, "opening captures"):
            self.verify()

    def test_stale_preinquiry_evidence_refused(self):
        self.manifest["schema"] = "1792.opening-chapter-render.v1"
        self.update()
        with self.assertRaisesRegex(ValueError, "unsupported opening manifest"):
            self.verify()

    def test_checkpoint_digest_tamper_refused(self):
        self.checkpoint.write_bytes(self.checkpoint.read_bytes() + b"\n")
        with self.assertRaisesRegex(ValueError, "checkpoint digest"):
            self.verify()

    def test_whole_save_rollback_mismatch_refused(self):
        self.manifest["midreturn_persistence"]["restored_snapshot"]["player"]["extra_progress"] = 1
        self.update()
        with self.assertRaisesRegex(ValueError, "whole saved authority"):
            self.verify()

    def test_retained_midreturn_save_tamper_refused(self):
        (self.images / "midreturn-save.json").write_bytes(b"{}")
        with self.assertRaisesRegex(ValueError, "native-save digest"):
            self.verify()

    def test_guard_binary32_pose_reconciles_json_rounding_only_in_physical_fields(self):
        original = self.snapshot(False, 40)
        parsed = copy.deepcopy(original)
        parsed["aftermath"]["escort"]["position"][0] = math.nextafter(6.1432061195373535, 0)
        self.assertEqual(native_save_projection(original), native_save_projection(parsed))
        parsed["aftermath"]["clue_tick"] = 21
        self.assertNotEqual(native_save_projection(original), native_save_projection(parsed))
        parsed = copy.deepcopy(original)
        parsed["aftermath"]["escort"]["position"][0] += 0.001
        self.assertNotEqual(native_save_projection(original), native_save_projection(parsed))

    def clock_pose_snapshot(self):
        """Synthetic authority with the measured native vector/clock values."""
        value = self.snapshot(False, 6522)
        position = [2.9739980697631836, 0.10094200819730759, 3.797171115875244]
        value["player"]["position"] = position.copy()
        value["actors"] = {"ranjit_singh": {"position": position.copy()}}
        value["game_time"] = {"year": 1792, "day": 1,
                              "hour": math.fmod(7.0 + 6522 / 216000.0, 24.0)}
        value["misl"] = {"ledger": {"purse": 18}}
        return value

    def parser_raw(self, value=None):
        """Synthetic save retaining the actual observed native numeric lexemes."""
        text = json.dumps(self.clock_pose_snapshot() if value is None else value, allow_nan=False)
        text = re.sub(r'("hour": )7\.030194444444445(?=[,}])', r'\g<1>7.03019444444444463', text)
        return text.replace("2.9739980697631836", "2.97399806976318359").encode()

    def restored_parser_snapshot(self, raw):
        """Model the production cold restore of a valid native save fixture."""
        value = strict_json(raw, godot_numbers=True)
        value["game_time"] = self.clock_for_tick(value["childhood"]["tick"])
        return value

    def test_pinned_parser_reproduces_observed_original_numeric_lexemes(self):
        self.assertEqual(godot451_number("7.03019444444444463"), 7.030194444444444)
        self.assertEqual(godot451_number("2.97399806976318359"), 2.973998069763183)
        self.assertEqual(godot451_number("7.030194444444445"), 7.030194444444445)
        self.assertNotEqual(godot451_number("7.03019444444444463"),
                            godot451_number("7.030194444444445"))

    def test_native_save_binds_the_entire_exact_reconstructed_cold_snapshot(self):
        raw = self.parser_raw()
        staged = self.restored_parser_snapshot(raw)
        original = strict_json(raw)
        before = copy.deepcopy(staged)
        result = verify_native_save_bytes(raw, staged)
        self.assertTrue(result["whole_cold_authority_exact"])
        self.assertEqual(result["save_sha256"], sha(raw))
        self.assertEqual({item["path"] for item in result["all_numeric_parser_changes"]},
                         {"actors.ranjit_singh.position[0]", "actors.ranjit_singh.position[1]",
                          "player.position[0]", "player.position[1]", "game_time.hour"})
        self.assertEqual(original["game_time"]["hour"], self.clock_for_tick(6522)["hour"])
        self.assertEqual(original["game_time"]["hour"], staged["game_time"]["hour"])
        self.assertNotEqual(result["original_parsed_hour"], staged["game_time"]["hour"])
        self.assertEqual(staged, before)

    def test_native_save_raw_clock_refuses_both_immediate_ulp_neighbors(self):
        for direction in (-math.inf, math.inf):
            with self.subTest(direction=direction):
                value = self.clock_pose_snapshot()
                value["game_time"]["hour"] = math.nextafter(value["game_time"]["hour"], direction)
                raw = self.parser_raw(value)
                with self.assertRaisesRegex(ValueError, "exact integer-tick derivation"):
                    verify_native_save_bytes(raw, strict_json(raw, godot_numbers=True))

    def test_native_save_raw_clock_refuses_wrong_identity_tick_and_boolean(self):
        for field in ("tick", "year", "day", "fractional_tick", "over_limit_tick", "bool_tick", "bool_year"):
            with self.subTest(field=field):
                value = self.clock_pose_snapshot()
                if field in ("year", "day"):
                    value["game_time"][field] += 1
                else:
                    if field == "bool_year":
                        value["game_time"]["year"] = True
                    else:
                        value["childhood"]["tick"] = {"tick": 6523, "fractional_tick": 6522.5,
                                                       "over_limit_tick": 10000001, "bool_tick": True}[field]
                raw = self.parser_raw(value)
                with self.assertRaises(ValueError):
                    verify_native_save_bytes(raw, strict_json(raw, godot_numbers=True))

    def test_native_save_cold_clock_requires_the_single_exact_native_restore_result(self):
        raw = self.parser_raw()
        expected = self.clock_for_tick(6522)["hour"]
        for hour in (strict_json(raw, godot_numbers=True)["game_time"]["hour"], math.nextafter(expected, -math.inf),
                     math.nextafter(expected, math.inf)):
            with self.subTest(hour=hour):
                staged = self.restored_parser_snapshot(raw)
                staged["game_time"]["hour"] = hour
                with self.assertRaisesRegex(ValueError, "Native cold authority mismatch"):
                    verify_native_save_bytes(raw, staged)

    def test_native_save_restored_clock_remains_exact_across_day_boundaries(self):
        for tick in (3671999, 3672000, 3672001, 10000000):
            with self.subTest(tick=tick):
                value = self.clock_pose_snapshot()
                value["childhood"]["tick"] = tick
                value["game_time"] = self.clock_for_tick(tick)
                raw = self.parser_raw(value)
                staged = self.restored_parser_snapshot(raw)
                result = verify_native_save_bytes(raw, staged)
                self.assertEqual(staged["game_time"], value["game_time"])
                self.assertEqual(result["reconstructed_cold_hour"], value["game_time"]["hour"])
                staged["game_time"]["day"] += 1
                with self.assertRaisesRegex(ValueError, "Native cold authority mismatch"):
                    verify_native_save_bytes(raw, staged)

    def test_native_save_refuses_all_other_cold_authority_changes(self):
        raw = self.parser_raw()
        for field in ("knowledge", "money", "hero", "player", "guard", "receipt", "clock_tick", "clock_year", "clock_day", "bool"):
            with self.subTest(field=field):
                staged = self.restored_parser_snapshot(raw)
                if field == "knowledge":
                    staged["aftermath"]["memories"][0]["received_tick"] += 1
                elif field == "money":
                    staged["misl"]["ledger"]["purse"] += 1
                elif field in ("hero", "player"):
                    item = staged["actors"]["ranjit_singh"] if field == "hero" else staged["player"]
                    item["position"][0] = math.nextafter(item["position"][0], math.inf)
                elif field == "guard":
                    staged["aftermath"]["escort"]["position"][0] += .001
                elif field == "receipt":
                    staged["riding_skills"]["lesson_receipts"][0]["entry_tick"] += 1
                elif field.startswith("clock_"):
                    item = staged["childhood"] if field == "clock_tick" else staged["game_time"]
                    item[field.removeprefix("clock_")] += 1
                else:
                    staged["aftermath"]["escort"]["yaw"] = False
                with self.assertRaises(ValueError):
                    verify_native_save_bytes(raw, staged)

    def test_native_save_preserves_only_the_declared_escort_physical_projection(self):
        raw = self.parser_raw()
        staged = self.restored_parser_snapshot(raw)
        y = staged["aftermath"]["escort"]["position"][1]
        staged["aftermath"]["escort"]["position"][1] = math.nextafter(y, math.inf)
        result = verify_native_save_bytes(raw, staged)
        self.assertTrue(result["whole_cold_authority_exact"])
        self.assertEqual(result["physical_projection"], "aftermath.escort.position/velocity/yaw only; binary32")

    def test_pinned_decimal_parser_enforces_original_grammar_and_bounded_domain(self):
        for token, expected in (("0", 0.0), ("-0", -0.0), ("6522", 6522.0), ("-1", -1.0),
                                ("1.25", 1.25), ("1.25e2", 125.0), ("125e-2", 1.25),
                                ("0.000000000000000000123", 0.0),
                                ("123456789012345678901e-20", godot451_number("123456789012345678000e-20"))):
            with self.subTest(token=token):
                self.assertEqual(godot451_number(token), expected)
        self.assertEqual(math.copysign(1.0, godot451_number("-0")), -1.0)
        for token in ("NaN", "Infinity", "+1", "01", ".5", "1.", "1e", "1e+", "1e512", "1e309", "1" * 1025):
            with self.subTest(token=token), self.assertRaises(ValueError):
                godot451_number(token)

    def test_native_strict_json_refuses_duplicate_nonfinite_and_nonobject_authority(self):
        for text in ('{"x":1,"x":2}', '{"x":NaN}', '{"x":Infinity}', '{"x":1e999}', '[]', 'false'):
            for native in (False, True):
                with self.subTest(text=text, native=native), self.assertRaises(ValueError):
                    strict_json(text.encode(), godot_numbers=native)

    def test_native_save_limit_refuses_oversized_bytes_before_parser_work(self):
        raw = self.parser_raw()
        staged = self.restored_parser_snapshot(raw)
        at_limit = raw + b" " * (NATIVE_SAVE_LIMIT - len(raw))
        self.assertTrue(verify_native_save_bytes(at_limit, staged)["whole_cold_authority_exact"])
        with self.assertRaisesRegex(ValueError, "existing authority limit"):
            verify_native_save_bytes(at_limit + b" ", staged)

    def test_native_save_refuses_missing_or_malformed_authority_shapes(self):
        for field in ("missing_childhood", "childhood", "missing_game_time", "game_time", "aftermath", "escort"):
            with self.subTest(field=field):
                value = self.clock_pose_snapshot()
                if field.startswith("missing_"):
                    value.pop(field.removeprefix("missing_"))
                elif field == "escort":
                    value["aftermath"]["escort"] = []
                else:
                    value[field] = []
                raw = self.parser_raw(value)
                with self.assertRaises(ValueError):
                    verify_native_save_bytes(raw, strict_json(raw, godot_numbers=True))
        with self.assertRaisesRegex(ValueError, "Malformed recorded authority"):
            verify_native_save_bytes(self.parser_raw(), [])

    def test_git_archive_reconstructs_exact_tree_modes_and_symlink(self):
        repository = self.folder / "source"
        repository.mkdir()
        def git(*args):
            return subprocess.check_output(["git", *args], cwd=repository, stderr=subprocess.DEVNULL).strip()
        git("init", "-q")
        (repository / "a").write_bytes(b"source\n")
        (repository / "dir").mkdir()
        (repository / "dir" / "execute").write_bytes(b"#!/bin/sh\n")
        (repository / "dir" / "execute").chmod(0o755)
        (repository / "alias").symlink_to("a")
        git("add", ".")
        git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture")
        archive = self.folder / "source.tar"
        archive.write_bytes(git("archive", "--format=tar", "HEAD"))
        tree, files = archive_tree(archive)
        self.assertEqual(tree, git("rev-parse", "HEAD^{tree}").decode())
        self.assertEqual(files["alias"], b"a")


if __name__ == "__main__":
    unittest.main()
