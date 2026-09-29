"""Install checksum-pinned public Godot references for CI. No store or console SDK."""
from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import tempfile
import urllib.request
import zipfile
from pathlib import Path

BASE = "https://github.com/godotengine/godot-builds/releases/download/4.5.1-stable/"
REFERENCES = {
    "linux": ("Godot_v4.5.1-stable_linux.x86_64.zip", "02ec53d1cc7dbb9cc6355393c61b9ab43d1244751a124f10248a4802830788cd", "Godot_v4.5.1-stable_linux.x86_64"),
    "windows": ("Godot_v4.5.1-stable_win64.exe.zip", "defccc78669e644861b4247626b01ae362cd9f23975edf19c8bfd2eb1f6a1783", "Godot_v4.5.1-stable_win64_console.exe"),
    "templates": ("Godot_v4.5.1-stable_export_templates.tpz", "1998af37f1387684e2c211cdb483daf492fc64dc6b12096bddcdca25b6910c86", ""),
}


def fetch_checked(kind: str, directory: Path) -> Path:
    name, expected, _ = REFERENCES[kind]
    destination = directory / name
    request = urllib.request.Request(BASE + name, headers={"User-Agent": "1792-platform-reference"})
    with urllib.request.urlopen(request, timeout=180) as response, destination.open("wb") as target:
        shutil.copyfileobj(response, target)
    with destination.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    if digest != expected:
        destination.unlink()
        raise RuntimeError("Public engine archive digest mismatch")
    print(f"Verified {name}: sha256:{digest}", flush=True)
    return destination


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--windows", action="store_true")
    args = parser.parse_args()
    kind = "windows" if args.windows else "linux"
    directory = Path(os.environ.get("RUNNER_TEMP", tempfile.gettempdir())) / "1792-reference"
    directory.mkdir(parents=True, exist_ok=True)
    archive = fetch_checked(kind, directory)
    with zipfile.ZipFile(archive) as source:
        # Pinned archive; additionally restrict extraction to expected flat executable names.
        names = [name for name in source.namelist() if Path(name).name == name and
                 name.startswith("Godot_v4.5.1-stable_") and not name.endswith("/")]
        for name in names:
            (directory / name).write_bytes(source.read(name))
    executable = directory / REFERENCES[kind][2]
    if not executable.is_file():
        raise RuntimeError("Expected engine executable absent")
    executable.chmod(0o755)
    if args.windows:
        archive = fetch_checked("templates", directory)
        templates = Path(os.environ["APPDATA"]) / "Godot/export_templates/4.5.1.stable"
        templates.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(archive) as source:
            for name in ("version.txt", "windows_debug_x86_64.exe", "windows_release_x86_64.exe"):
                (templates / name).write_bytes(source.read("templates/" + name))
    with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as environment:
        environment.write(f"GODOT={executable}\n")


if __name__ == "__main__":
    main()
