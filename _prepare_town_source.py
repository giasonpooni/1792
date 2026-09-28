"""Temporary exact-source preparation. Creates Git objects only; never changes refs."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import urllib.request

REPO = "giasonpooni/1792"
BASE = "1e1447617ddcb2ab989b26856df5f9d0838f81dd"
EXPECTED_TREE = "9ddf0d759ad5859d61151acb81c96a9a46373418"
EXPECTED = {
    ".github/workflows/town-qualification.yml": "916714e72c043fad0f798fa7d7063450a804f0ac",
    "README.md": "3a14e61e5fbf6a462cf1b726f2c4047b3ab5a461",
    "data/history/gujranwala_town_sources.v1.json": "90c8d34248249410f265074e01a16149b17a8634",
    "docs/GUJRANWALA_TOWN.md": "e06724a02077c6c0c3bac6e10d78b019feaad739",
    "game/childhood/childhood_state.gd": "707fe24e2a498d8a0ce90a3aecd83cf82936bd78",
    "game/childhood/home_chapter.gd": "0444b4b2e7df931db4b32ff23d4854f84676013c",
    "game/childhood/home_launch.gd": "50689657829817748a17b442059ae05da1364fe4",
    "game/settlement/town_chapter.gd": "c37c2df26fb0bfba6da3988cdd90709c74e61d94",
    "game/settlement/town_layout.gd": "ca67818bd78263287ee56f1637f7ee18374bd345",
    "game/settlement/town_state.gd": "67c9f4365142f1d3b94aa628531f894078a7c581",
    "game/settlement/town_world.gd": "1cd43dee41d460b3826a298b2ff1f8ef02773cc2",
    "game/tests/render_town.gd": "85d10985e01189cd2280cc0acbe466f13f6f9c80",
    "game/tests/test_town.gd": "c848607e6891086f2d863176fb77db586a959571",
    "tools/run_checks.py": "10ad7d7192ea71d175218c2c493f349a15465b70",
}


def replace(path, old, new, count=1):
    p = Path(path)
    text = p.read_text(encoding="utf-8")
    if text.count(old) != count:
        raise ValueError("Unexpected replacement count: " + path + " " + repr(old))
    p.write_bytes(text.replace(old, new).encode("utf-8"))


def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()


def prepare():
    state = "game/childhood/childhood_state.gd"
    replace(state, "\tif not valid_point(coords(p))", "\tif not valid_player_point(coords(p))", 2)
    for expression in ("candidate.riding.horse.position", "value.player.position", "value.riding.horse.position"):
        replace(state, "not valid_point(" + expression + ")", "not valid_player_point(" + expression + ")")
    replace(state, "func _shape(", "## Trusted subclass hook for a declared player/horse map, not an input-selected validator.\n## Encounter, caravan and escort domains keep the original static valid_point contract.\nfunc valid_player_point(p: Variant) -> bool:\n\treturn valid_point(p)\n\nfunc _shape(")
    chapter = "game/childhood/home_chapter.gd"
    walls = '\tfor x in [-29,29]: _box(Vector3(0.4,3,58),Vector3(x,1.5,0),Color("506248"),true)\n\tfor z in [-29,29]: _box(Vector3(58,3,0.4),Vector3(0,1.5,z),Color("506248"),true)\n'
    replace(chapter, walls, "\t_build_boundaries()\n")
    replace(chapter, "func _build_ui()", "func _build_boundaries() -> void:\n" + walls + "\nfunc _build_ui()")
    replace("game/childhood/home_launch.gd", "res://remounts/remount_chapter.gd", "res://settlement/town_chapter.gd")
    replace("tools/run_checks.py", "    return 0\n", '    run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/test_town.gd"],\n        "town", "TOWN_TESTS:")\n    return 0\n')
    addition = """## Gujranwala now extends beyond the home yard

Complete the household inquiry, then walk or ride through the **north or west
town gate**. Connected lanes lead to seven courtyard compounds, a bazaar, well
square, pottery and cloth workshops, a grain yard and the cultivated edge.
**E** examines nearby places; **M** recalls only places you have examined;
**J** keeps those observations with the rest of the chapter. Saving works in the
new districts, including while mounted on the existing horse.

This is an **86 × 108 metre compressed neighbourhood**, including the original
56 × 56 metre mission core—not the whole historical city. Existing tutorials,
supply contracts and the missing-remounts investigation remain in the same entry.
New stalls and sacks are environmental detail, not a second trading economy.
[Town walkthrough, research and implementation](docs/GUJRANWALA_TOWN.md).

"""
    replace("README.md", "## Start playing\n", addition + "## Start playing\n")
    replace("README.md", "then Gujranwala supplies/production and a missing-remounts investigation.", "then supplies/production, a missing-remounts investigation and connected town exploration.")
    replace("README.md", "The home landscape is a seeded **56 × 56 metre compressed test container**:", "The retained home mission core is a seeded **56 × 56 metre test container**, now\ninside the larger [town neighbourhood](docs/GUJRANWALA_TOWN.md):")
    for path, expected in EXPECTED.items():
        raw = Path(path).read_bytes()
        actual = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
        if actual != expected:
            raise ValueError(f"File differs from locally tested bytes: {path} {actual} expected {expected}")
    git("add", "--", *EXPECTED)
    git("update-index", "--force-remove", "--", "_prepare_town_source.py", ".github/workflows/prepare-town-source.yml")
    actual = git("write-tree")
    if actual != EXPECTED_TREE:
        raise ValueError(f"Tree differs from local qualification: {actual}")
    print("EXACT_CANDIDATE_TREE: " + actual, flush=True)


def api(endpoint, payload):
    # No arbitrary endpoint, ref mutation, push, merge, deployment or token output.
    if endpoint not in ("git/trees", "git/commits"):
        raise ValueError("Only unreferenced Git object creation is allowed")
    request = urllib.request.Request(
        "https://api.github.com/repos/" + REPO + "/" + endpoint,
        data=json.dumps(payload).encode(), method="POST",
        headers={"Authorization": "Bearer " + os.environ["GH_TOKEN"],
                 "Accept": "application/vnd.github+json", "Content-Type": "application/json",
                 "X-GitHub-Api-Version": "2022-11-28"})
    with urllib.request.urlopen(request, timeout=45) as response:
        return json.load(response)


def main():
    parent = git("rev-parse", "HEAD")
    prepare()
    if os.environ.get("LOCAL_ONLY") == "1":
        return
    if os.environ.get("GITHUB_REPOSITORY") != REPO or os.environ.get("EXPECTED_PARENT") != parent:
        raise ValueError("Wrong repository or staging occurrence")
    tree = api("git/trees", {"base_tree": BASE, "tree": [
        {"path": p, "mode": "100644", "type": "blob", "content": Path(p).read_text(encoding="utf-8")}
        for p in EXPECTED]})
    if tree["sha"] != EXPECTED_TREE:
        raise ValueError("Remote candidate tree differs")
    commit = api("git/commits", {"message": "feat: compose tested Gujranwala neighbourhood with inherited chapter", "tree": EXPECTED_TREE, "parents": [parent]})
    result = {"prepared_commit": commit["sha"], "tree": EXPECTED_TREE, "parent": parent,
              "refs_changed": False, "local_qualification": "1757 engine assertions; 8 structural checks; 8 rendered fixtures", "files": EXPECTED}
    Path("town-prepared.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2), flush=True)


if __name__ == "__main__":
    main()
