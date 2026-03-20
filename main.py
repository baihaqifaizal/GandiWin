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

    import customtkinter as ctk
    from gui.theme import get_colors, set_theme, load_config, load_translations
    
    config = load_config()
    set_theme(config.get("theme", "dark"))
    load_translations(config.get("language", "id"))
    ctk.set_appearance_mode("dark" if config.get("theme", "dark") == "dark" else "light")

    from gui.splash import SplashScreen
    from tweaks.phase1 import PHASE1_TWEAKS
    from tweaks.win11debloat import WIN11_DEBLOAT_TWEAKS
    from core import engine

    all_tweaks = PHASE1_TWEAKS + WIN11_DEBLOAT_TWEAKS
    precheck_results = {}

    def run_check(progress_cb):
        from core import executor
        total = len(all_tweaks) + 1  # +1 for appx check
        
        # 1. Check tweaks
        for i, tweak in enumerate(all_tweaks):
            try:
                applied = engine.check_tweak_applied(tweak)
                precheck_results[tweak["id"]] = applied
            except Exception:
                precheck_results[tweak["id"]] = False
            progress_cb(i + 1, total, f"Checking: {tweak['name'][:40]}...")

        # 2. Check installed apps
        progress_cb(total, total, "Checking installed apps...")
        r = executor._run_process("Get-AppxPackage | Select-Object -ExpandProperty Name", "powershell")
        if r.success and r.message:
            # Store as set for O(1) lookup
            precheck_results["installed_apps"] = set(r.message.lower().split("\n"))
        else:
            precheck_results["installed_apps"] = set()

    def launch_app():
        from gui.app import GandiWinApp
        app = GandiWinApp(precheck_results=precheck_results)
        app.mainloop()

    splash = SplashScreen(on_complete=launch_app)
    splash.start_check(run_check)
    splash.mainloop()


if __name__ == "__main__":
    main()
