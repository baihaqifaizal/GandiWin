"""
GandiWin — Windows Optimization Toolkit
Entry point. Requires admin privileges.
NOTE: Jangan compile file ini dulu selama development.
"""
import sys
import os
import ctypes


def is_admin() -> bool:
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False


def elevate():
    if not is_admin():
        ctypes.windll.shell32.ShellExecuteW(
            None, "runas", sys.executable, " ".join(sys.argv), None, 1
        )
        sys.exit(0)


def main():
    elevate()

    base_dir = os.path.dirname(os.path.abspath(__file__))
    if base_dir not in sys.path:
        sys.path.insert(0, base_dir)

    dry_run = "--dry-run" in sys.argv
    verbose = "--verbose" in sys.argv
    headless = "--headless" in sys.argv

    if dry_run:
        os.environ["GANDIWIN_DRY_RUN"] = "1"
    if verbose:
        os.environ["GANDIWIN_VERBOSE"] = "1"

    if headless:
        from core import engine
        from tweaks.phase1 import PHASE1_TWEAKS
        print("[GandiWin] Headless mode — applying Phase 1 tweaks...")
        for tweak in PHASE1_TWEAKS:
            if tweak.get("risk") != "danger":
                r = engine.apply_tweak(tweak)
                print(f"  {'✓' if r.success else '✗'} {tweak['name']}: {r.message}")
        print("[GandiWin] Done.")
        return

    from gui.app import GandiWinApp
    app = GandiWinApp()
    app.mainloop()


if __name__ == "__main__":
    main()
