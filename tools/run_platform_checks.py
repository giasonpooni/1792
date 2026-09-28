"""Extend, rather than replace, the inherited verification runner."""
from __future__ import annotations
import argparse
import sys
from run_checks import run


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    args = parser.parse_args()
    # Each process retains its own completion marker and unchanged 120-second limit.
    import run_checks
    old_argv = sys.argv
    try:
        sys.argv = [old_argv[0], "--godot", args.godot]
        if run_checks.main() != 0:
            raise RuntimeError("Inherited checks did not pass")
    finally:
        sys.argv = old_argv
    for script, name in (("check_oral_memory.py", "oral-content"), ("check_platform.py", "platform-contracts"),
                          ("check_package_verification.py", "package-conformance")):
        run([sys.executable, "tools/" + script], name)
    for script, name, marker in (("test_oral_memory.gd", "oral-memory", "ORAL_MEMORY_TESTS:"),
                                  ("test_platform.gd", "platform", "PLATFORM_TESTS:"),
                                  ("test_controller_remapping.gd", "controller-remapping", "CONTROLLER_REMAPPING_TESTS:"),
                                  ("test_save_recovery.gd", "save-recovery", "SAVE_RECOVERY_TESTS:")):
        run([args.godot, "--headless", "--fixed-fps", "60", "--path", "game", "--script", "res://tests/" + script], name, marker)


if __name__ == "__main__":
    main()
