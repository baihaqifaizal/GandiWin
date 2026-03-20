from tweaks.phase1 import PHASE1_TWEAKS
from tweaks.phase2 import PHASE2_TWEAKS

_TWEAK_MAP = {t["id"]: t for t in PHASE1_TWEAKS + PHASE2_TWEAKS}


def _t(tid: str) -> dict:
    return _TWEAK_MAP.get(tid, {"id": tid, "name": tid, "description": "", "risk": "safe", "type": "cmd", "actions": []})


GHOST_COMPACT = {
    "id": "ghost_compact",
    "name": "Ghost Migration — Compact",
    "description": "Mode aman untuk semua user. Hapus bloatware, matikan telemetry, pangkas scheduled tasks.",
    "groups": [
        {
            "id": "uwp_removal",
            "name": "Hapus UWP Bloatware",
            "risk": "safe",
            "tweaks": [_t("remove_bloatware_uwp")],
        },
        {
            "id": "telemetry_services",
            "name": "Matikan Telemetry Services",
            "risk": "safe",
            "tweaks": [_t("disable_telemetry"), _t("disable_telemetry_services")],
        },
        {
            "id": "scheduled_tasks",
            "name": "Pangkas Scheduled Tasks",
            "risk": "safe",
            "tweaks": [_t("disable_scheduled_tasks")],
        },
        {
            "id": "background_apps",
            "name": "Matikan Background Apps & Delivery Optimization",
            "risk": "safe",
            "tweaks": [_t("disable_background_apps"), _t("disable_delivery_optimization")],
        },
    ],
}

GHOST_SUPERLITE = {
    "id": "ghost_superlite",
    "name": "Ghost Migration — SuperLite",
    "description": "Mode serius. Semua dari Compact + matikan services berat, hapus OneDrive, apply registry tweaks.",
    "inherits": "ghost_compact",
    "groups": [
        {
            "id": "heavy_services",
            "name": "Matikan Services Berat",
            "risk": "warning",
            "tweaks": [
                _t("disable_print_spooler"),
                _t("disable_geolocation"),
                _t("disable_parental_controls"),
                _t("disable_retail_demo"),
                _t("disable_xbox_services"),
                _t("disable_windows_search"),
            ],
        },
        {
            "id": "onedrive_strip",
            "name": "Hapus OneDrive",
            "risk": "warning",
            "tweaks": [
                {
                    "id": "remove_onedrive",
                    "name": "Hapus OneDrive",
                    "description": "Uninstall OneDrive dan hapus registry entry serta folder AppData.",
                    "risk": "warning",
                    "type": "powershell",
                    "actions": [
                        {"command": "Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue"},
                        {"command": r"Start-Process \"$env:SystemRoot\SysWOW64\OneDriveSetup.exe\" -ArgumentList '/uninstall' -Wait -ErrorAction SilentlyContinue"},
                    ],
                    "rollback": False,
                }
            ],
        },
        {
            "id": "registry_bundle",
            "name": "Apply Registry Tweaks Performa",
            "risk": "warning",
            "tweaks": [
                _t("reduce_visual_effects"),
                _t("disable_usb_selective_suspend"),
                _t("disable_mouse_acceleration"),
                _t("ultimate_performance"),
            ],
        },
    ],
}

GHOST_SE = {
    "id": "ghost_se",
    "name": "Ghost Migration — SE (Special Edition)",
    "description": "Mode agresif. Semua dari SuperLite + kernel tweaks, hapus WinRE. Hanya untuk advanced user.",
    "inherits": "ghost_superlite",
    "groups": [
        {
            "id": "kernel_tweaks",
            "name": "Kernel & Security Tweaks",
            "risk": "danger",
            "require_double_confirm": True,
            "tweaks": [
                _t("disable_spectre_meltdown"),
                _t("cpu_core_unparking"),
                _t("network_throttling_index"),
                _t("enable_hags"),
            ],
        },
        {
            "id": "winre_removal",
            "name": "Hapus Windows Recovery Environment",
            "risk": "danger",
            "require_double_confirm": True,
            "tweaks": [
                {
                    "id": "remove_winre",
                    "name": "Hapus WinRE",
                    "description": "Hapus Windows Recovery Environment untuk menghemat 500MB+. Recovery menjadi terbatas.",
                    "detail": "PERINGATAN: Setelah ini, fitur Reset PC dan opsi recovery Windows hilang. Backup manual wajib dilakukan sebelum apply.",
                    "risk": "danger",
                    "type": "cmd",
                    "actions": [{"command": "reagentc /disable"}],
                    "needs_restart": False,
                    "rollback": True,
                    "rollback_cmd": "reagentc /enable",
                }
            ],
        },
        {
            "id": "virtualization_disable",
            "name": "Matikan Hyper-V & WSL",
            "risk": "danger",
            "require_double_confirm": True,
            "tweaks": [
                {
                    "id": "disable_hyperv_wsl",
                    "name": "Matikan Hyper-V, WSL, Sandbox",
                    "description": "Nonaktifkan virtualization layer untuk mengurangi overhead kernel.",
                    "risk": "danger",
                    "type": "powershell",
                    "actions": [
                        {"command": "Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -ErrorAction SilentlyContinue"},
                        {"command": "Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -ErrorAction SilentlyContinue"},
                        {"command": "Disable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -NoRestart -ErrorAction SilentlyContinue"},
                    ],
                    "needs_restart": True,
                    "rollback": True,
                    "rollback_cmd": "Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart",
                }
            ],
        },
    ],
}

GHOST_MODES = {
    "compact": GHOST_COMPACT,
    "superlite": GHOST_SUPERLITE,
    "se": GHOST_SE,
}


def get_all_groups(mode_id: str) -> list:
    mode = GHOST_MODES.get(mode_id)
    if not mode:
        return []
    groups = []
    if "inherits" in mode:
        groups.extend(get_all_groups(mode["inherits"].replace("ghost_", "")))
    groups.extend(mode.get("groups", []))
    return groups


def get_all_tweaks(mode_id: str) -> list:
    tweaks = []
    for group in get_all_groups(mode_id):
        tweaks.extend(group.get("tweaks", []))
    return tweaks
