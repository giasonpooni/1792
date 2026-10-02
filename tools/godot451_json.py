#!/usr/bin/env python3
"""Bind a native save to its cold load by the pinned Godot 4.5.1 JSON parser.

This does not change any source checkout or evidence bytes. It is restricted to
finite, strict JSON emitted by the existing native save authority. Numeric
lexemes are independently parsed with the pinned Godot 4.5.1 decimal algorithm;
the complete reconstructed authority must match the recorded cold snapshot.
Only the previously declared physical escort position/velocity/yaw receive the
existing binary32 representation reconciliation. Player/hero values match their
parser results exactly. The validated saved clock is then reconstructed from the
integer tick, exactly as childhood_state.restore does, without tolerances.

Primary source, tag 4.5.1-stable:
  core/io/json.cpp, blob 34f001a228237a8fc9c0d10f1908ba0034d11de8:
  https://github.com/godotengine/godot/blob/4.5.1-stable/core/io/json.cpp
  JSON::_get_token calls String::to_float for ALL number tokens.
  core/string/ustring.cpp, blob 45d8497af81a905599bd7790c777c27d256da6c3:
  https://github.com/godotengine/godot/blob/4.5.1-stable/core/string/ustring.cpp
  built_in_strtod and String::to_float, lines 2384-2616.

Decimal algorithm adapted from Godot, under the MIT license:
Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""
from __future__ import annotations

import copy
import hashlib
import json
import math
import re
import struct

NATIVE_SAVE_LIMIT = 131072  # Existing childhood_state.gd LIMIT.
NUMBER_LIMIT = 1024  # More than native stringify emits; prevents adversarial work.
TOKEN = re.compile(r"(-?)(0|[1-9][0-9]*)(?:\.([0-9]+))?(?:[eE]([+-]?[0-9]+))?\Z", re.ASCII)
POWERS_OF_TEN = (10.0, 100.0, 1.0e4, 1.0e8, 1.0e16, 1.0e32, 1.0e64, 1.0e128, 1.0e256)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def godot451_number(token: str) -> float:
    """Pinned built_in_strtod for a bounded, complete strict-JSON number token.

    Python's binary64 operations preserve the original operation sequence:
    multiply/add the two integer mantissa halves, then multiply selected table
    entries in increasing order, and finally divide or multiply once. No use of
    Decimal, Python float(token), exponentiation, FMA, epsilon, or ULP intervals.
    JSON's lexer guarantees a present mantissa and complete exponent, so the
    source's whitespace/missing-number/incomplete-exponent branches do not apply.
    Huge explicit exponents, whose C++ signed-int accumulation would overflow,
    are refused rather than assigned invented semantics. Combined exponent
    clamp at 511 is faithfully retained; nonfinite results are refused.
    """
    require(isinstance(token, str) and len(token) <= NUMBER_LIMIT, "Oversized JSON number")
    match = TOKEN.fullmatch(token)
    require(match is not None, "Incomplete or noncanonical JSON number")
    sign, integer, fractional, exponent = match.groups()
    explicit_exponent = int(exponent or "0")
    require(abs(explicit_exponent) <= 511, "Number exponent outside bounded native JSON domain")
    digits = integer + (fractional or "")
    retained = digits[:18]
    frac_exp = len(integer) - len(retained) + explicit_exponent
    first = retained[:-9]
    last = retained[-9:]
    # Each integer half contains at most nine digits and fits the source's int.
    fraction = (1.0e9 * int(first or "0")) + int(last or "0")
    magnitude = min(abs(frac_exp), 511)
    scale = 1.0
    for power in POWERS_OF_TEN:
        if magnitude & 1:
            scale *= power
        magnitude >>= 1
        if magnitude == 0:
            break
    require(magnitude == 0, "Internal exponent table overflow")
    fraction = fraction / scale if frac_exp < 0 else fraction * scale
    if sign:
        fraction = -fraction
    require(math.isfinite(fraction), "Nonfinite native JSON number")
    return fraction


def strict_json(raw: bytes, *, godot_numbers: bool = False) -> dict:
    def invalid(value):
        raise ValueError("Nonfinite JSON constant: " + value)

    def unique(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, "Duplicate JSON field: " + key)
            result[key] = value
        return result

    def finite_float(token):
        value = float(token)
        require(math.isfinite(value), "Nonfinite JSON number")
        return value

    result = json.loads(raw.decode("utf-8"), parse_int=godot451_number if godot_numbers else int,
                        parse_float=godot451_number if godot_numbers else finite_float,
                        parse_constant=invalid, object_pairs_hook=unique)
    require(isinstance(result, dict), "Expected JSON object")
    return result


def exact_raw_clock(state: dict) -> None:
    childhood = state.get("childhood")
    require(isinstance(childhood, dict), "Missing or malformed raw childhood authority")
    tick = childhood.get("tick")
    require(type(tick) in (int, float) and math.isfinite(tick)
            and tick == int(tick) and 0 <= tick <= 10000000, "Invalid raw childhood tick")
    hours = 7.0 + tick / 216000.0
    clock = state.get("game_time", {})
    require(isinstance(clock, dict), "Malformed raw clock authority")
    expected = {"year": 1792, "day": 1 + int(hours / 24.0), "hour": math.fmod(hours, 24.0)}
    require(set(clock) == set(expected), "Unexpected raw clock shape")
    for field, value in expected.items():
        actual = clock.get(field)
        require(type(actual) in (int, float) and math.isfinite(actual) and actual == value,
                "Raw clock is not the exact integer-tick derivation: " + field)


def guard_only_projection(state: dict) -> dict:
    """Keep the original, narrowly declared escort native binary32 projection."""
    require(isinstance(state, dict), "Malformed recorded authority")
    value = copy.deepcopy(state)
    aftermath = value.get("aftermath", {})
    require(isinstance(aftermath, dict), "Malformed escort authority")
    guard = aftermath.get("escort", {})
    require(isinstance(guard, dict), "Malformed physical escort")

    def native_float(number):
        require(type(number) in (int, float) and math.isfinite(number)
                and abs(number) <= 3.4028234663852886e38, "Invalid escort physical float")
        return struct.unpack(">f", struct.pack(">f", number))[0]

    for field in ("position", "velocity"):
        if field in guard:
            vector = guard[field]
            require(isinstance(vector, list) and len(vector) == 3, "Invalid escort vector")
            guard[field] = [native_float(item) for item in vector]
    if "yaw" in guard:
        guard["yaw"] = native_float(guard["yaw"])
    return value


def differences(left, right, path="") -> list[dict]:
    """Exact semantic JSON equality; boolean/integer aliasing is forbidden.

    Godot restore casts selected whole-number counters to int, so equal finite
    integer/float pairs are the sole intentional semantic type equivalence.
    """
    if isinstance(left, dict) and isinstance(right, dict):
        result = []
        for key in sorted(left.keys() | right.keys()):
            child = path + "." + key if path else key
            if key not in left or key not in right:
                result.append({"path": child, "expected": left.get(key), "recorded": right.get(key),
                               "reason": "missing field"})
            else:
                result.extend(differences(left[key], right[key], child))
        return result
    if isinstance(left, list) and isinstance(right, list):
        if len(left) != len(right):
            return [{"path": path, "reason": "array size", "expected": len(left), "recorded": len(right)}]
        return [difference for index, pair in enumerate(zip(left, right))
                for difference in differences(*pair, path + "[" + str(index) + "]")]
    numeric = type(left) in (int, float) and type(right) in (int, float)
    if numeric and math.isfinite(left) and math.isfinite(right) and left == right:
        return []
    if not numeric and type(left) is type(right) and left == right:
        return []
    return [{"path": path, "expected": left, "recorded": right}]


def verify_native_save_bytes(raw: bytes, recorded_cold_snapshot: dict) -> dict:
    """Require exact raw clock, reconstruct native parser and restore, compare.

    Check digests against the declared manifest at the caller before this helper.
    This returns diagnostic binding information and never substitutes artifacts.
    """
    require(len(raw) <= NATIVE_SAVE_LIMIT, "Native save exceeds existing authority limit")
    original = strict_json(raw)
    exact_raw_clock(original)
    predicted = strict_json(raw, godot_numbers=True)
    drift = differences(original, predicted)
    parsed_hour = predicted["game_time"]["hour"]
    # The production restore validates the parsed save, then derives this cache
    # from the authoritative integer tick. Preserve all other parser results.
    parsed_tick = predicted["childhood"]["tick"]
    require(type(parsed_tick) in (int, float) and parsed_tick == original["childhood"]["tick"],
            "Native parser changed the authoritative integer tick")
    hours = 7.0 + parsed_tick / 216000.0
    predicted["game_time"]["day"] = 1 + int(hours / 24.0)
    predicted["game_time"]["hour"] = math.fmod(hours, 24.0)
    mismatches = differences(guard_only_projection(predicted), guard_only_projection(recorded_cold_snapshot))
    require(not mismatches, "Native cold authority mismatch: " + json.dumps(mismatches[:12], sort_keys=True))
    return {"save_sha256": hashlib.sha256(raw).hexdigest(), "saved_tick": original["childhood"]["tick"],
            "raw_hour": original["game_time"]["hour"], "reconstructed_cold_hour": predicted["game_time"]["hour"],
            "original_parsed_hour": parsed_hour,
            "all_numeric_parser_changes": drift, "whole_cold_authority_exact": True,
            "physical_projection": "aftermath.escort.position/velocity/yaw only; binary32",
            "parser": "Godot4.5.1-stable built_in_strtod; exact original numeric lexemes",
            "raw_clock": "exact integer-tick derivation; no tolerance",
            "cold_clock": "validated save then exact childhood_state.restore integer-tick derivation; no tolerance"}
