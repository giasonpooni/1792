#!/usr/bin/env python3
"""Render/check the source inventory; does not certify gameplay execution."""
import argparse
from collections import Counter
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data/production/playable_ledger.json"
OUTPUT = ROOT / "docs/PLAYABLE_MISSION_LEDGER.md"


def cell(value):
    return str(value).replace("|", "\\|").replace("\n", " ")


def render(data):
    entries = data["entries"]
    ids = [e["id"] for e in entries] + [b["id"] for b in data["backlog"]]
    assert len(ids) == len(set(ids)), "Duplicate ledger ID"
    for entry in entries:
        assert entry["parent_id"] is None or entry["parent_id"] in ids
        assert len(entry["commit"]) == 40
        for field in ("title", "kind", "launch", "completion", "player_actions", "source_path"):
            assert entry[field], (entry["id"], field)
    for entry in data["backlog"]:
        assert all(i in ids for i in entry["related_ids"])
    counts = Counter(e["kind"] for e in entries)
    play = [e for e in entries if e["kind"] == "playable_sequence"]
    lines = ["# Playable mission and sequence ledger", "", data["title"], "",
             f"Snapshot: **{data['as_of']}**. Main: `{data['main_commit']}`.", "",
             f"**{len(play)} authored playable sequences**: "
             f"{sum(e['delivery'] == 'main' for e in play)} on the recorded main revision and "
             f"{sum(e['delivery'] == 'draft' for e in play)} on recorded draft branches. "
             "These range from short lessons to multi-stage prototype missions; this is not a count of finished campaign missions or one fully integrated build.", "",
             "| Inventory category | Entries |", "| --- | ---: |"]
    for kind, count in counts.items():
        lines.append(f"| {kind.replace('_', ' ')} | {count} |")
    lines += ["", "## Counting and maintenance", "",
              "The JSON file is authoritative; this document is generated. Stable IDs survive renaming and moving scenes. "
              "A mission owns its child beats. Alternate approaches, captain/delegated control, chapter wrappers, art passes and integration PRs do not create new missions. "
              "The thirteen TALE entries share a scene adapter but each has its own authored objective arc.", "",
              "Historical confidence and implementation are separate. Legends, allegations and conflicting accounts remain available for cinematic adaptation with their source identity retained. "
              "A related short recollection does not mark a larger planned biography mission complete.", "",
              "This pass inspected repository content and versioned documentation. It did not rerun gameplay suites or certify a release. "
              "Branch references below pin the inspected revisions; merge status can change after this snapshot.", "",
              "Edit `data/production/playable_ledger.json`, then run `python tools/playable_ledger.py --write`. "
              "Use `--check` to catch stale generated output, and `--check-source-paths` in a checkout containing the recorded commits to verify references.", "",
              "## Playable sequence index", "", "| ID | Sequence | Era | Delivery |", "| --- | --- | --- | --- |"]
    for e in play:
        delivery = "main" if e["pr"] is None else f"[PR #{e['pr']}](https://github.com/giasonpooni/1792/pull/{e['pr']}) · draft"
        lines.append(f"| {e['id']} | [{cell(e['title'])}](#{e['id'].lower()}) | {cell(e['era'])} | {delivery} |")
    lines += ["", "## Detailed register", ""]
    for e in entries:
        url = f"https://github.com/giasonpooni/1792/blob/{e['commit']}/{e['source_path']}"
        lines += [f"### {e['id']}", "", f"**{e['title']}** — {e['kind'].replace('_', ' ')}; {e['delivery']}.", "",
                  f"- **Era:** {e['era']}", f"- **Launch:** {e['launch']}",
                  f"- **Prerequisites:** {e['prerequisites']}", f"- **Play:** {e['player_actions']}",
                  f"- **Completion / consequences:** {e['completion']}",
                  f"- **Implementation:** {e['implementation']}",
                  f"- **Source treatment:** {e['historical_basis']}",
                  f"- **Revision:** `{e['branch']}` · [source guide/data]({url})."]
        if e["parent_id"]:
            lines.append(f"- **Variant of:** {e['parent_id']}; excluded from the authored-sequence total.")
        if e["beats"]:
            lines.append("- **Child beats:** " + " → ".join(e["beats"]))
        if e.get("choices"):
            lines += ["", "| Beat | Choices |", "| --- | --- |"]
            for choice in e["choices"]:
                lines.append(f"| {choice['beat_id']} | {cell(' / '.join(choice['options']))} |")
        lines.append("")
    lines += ["## Planned and contract-only register", "",
              "The 28-entry youth slate contains one implemented bazaar adaptation and 27 remaining proposals. "
              "Some overlap with recollections below; related IDs show that relationship without asserting completion. "
              "The later father campaign and Fall of Empire remain contracts. Additional brief groups preserve incoming material without manufacturing a mission count.", "",
              "| ID | Title | Status | Related playable content | Scope / source |", "| --- | --- | --- | --- | --- |"]
    for b in data["backlog"]:
        lines.append(f"| {b['id']} | {cell(b['title'])} | {b['status']} | {', '.join(b['related_ids']) or '—'} | {cell(b['note'])} `{b['source_path']}` |")
    lines += ["", "## Draft branch coverage and duplicate control", "",
              "Every open PR in the inspected 36-head snapshot is registered here. Content inherited by a branch is not counted again. "
              "The earlier west-gate smith and the current household smith are deliveries of the same commission; art and producer branches are not additional errands. "
              "PR #74 is another hawk implementation. PR #78 combines work and adds no mission merely by integration. "
              "Generic building, hiring, purchases, upkeep and witness/perception systems are activities supporting these sequences, not separately authored missions.", "",
              "| PR | Work | Inventory role | Direct entries | Pinned revision |", "| --- | --- | --- | --- | --- |"]
    for p in data["branch_coverage"]:
        lines.append(f"| [#{p['pr']}](https://github.com/giasonpooni/1792/pull/{p['pr']}) | {cell(p['title'])} | {p['role']} | {', '.join(p['entry_ids']) or '—'} | `{p['commit']}` |")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--check-source-paths", action="store_true")
    args = parser.parse_args()
    data = json.loads(DATA.read_text())
    output = render(data)
    if args.write:
        OUTPUT.write_text(output)
    if args.check:
        assert OUTPUT.read_text() == output, "Ledger Markdown is stale; run --write"
    if args.check_source_paths:
        trees = {}
        for entry in data["entries"]:
            sha = entry["commit"]
            if sha not in trees:
                trees[sha] = set(subprocess.check_output(
                    ["git", "ls-tree", "-r", "--name-only", sha], cwd=ROOT, text=True).splitlines())
            assert entry["source_path"] in trees[sha], (entry["id"], entry["source_path"])
    counts = Counter(e["kind"] for e in data["entries"])
    print(json.dumps({"entries": len(data["entries"]), "categories": counts,
                      "backlog_rows": len(data["backlog"]), "branch_heads": len(data["branch_coverage"])}, indent=2))


if __name__ == "__main__":
    main()
