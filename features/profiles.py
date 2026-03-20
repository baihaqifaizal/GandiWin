import json
from pathlib import Path
from core import sysinfo

DATA_DIR = Path(__file__).parent.parent / "data"

GAMING_TWEAKS = [
    "ultimate_performance", "disable_nagle", "disable_fullscreen_optimization",
    "remove_game_bar_dvr", "change_dns_cloudflare", "disable_usb_selective_suspend",
    "disable_mouse_acceleration", "network_throttling_index", "enable_hags",
    "cpu_core_unparking", "disable_geolocation", "disable_superfetch",
    "disable_telemetry", "disable_telemetry_services", "disable_scheduled_tasks",
    "disable_background_apps",
]

OFFICE_TWEAKS = [
    "disable_telemetry", "disable_telemetry_services", "remove_bloatware_uwp",
    "reduce_visual_effects", "disable_scheduled_tasks", "disable_delivery_optimization",
    "fix_quick_access", "change_dns_cloudflare", "disable_background_apps",
    "cleanup_temp_files",
]

DEVELOPER_TWEAKS = [
    "ultimate_performance", "disable_telemetry", "disable_telemetry_services",
    "remove_bloatware_uwp", "disable_windows_search", "reduce_visual_effects",
    "disable_scheduled_tasks", "disable_background_apps", "disable_delivery_optimization",
    "fix_quick_access", "cleanup_temp_files",
]

BATTERY_TWEAKS = [
    "disable_telemetry", "disable_telemetry_services", "remove_bloatware_uwp",
    "disable_background_apps", "disable_delivery_optimization", "disable_scheduled_tasks",
    "cleanup_temp_files", "fix_quick_access",
]


class Profile:
    def __init__(self, id: str, name: str, description: str, tweak_ids: list):
        self.id = id
        self.name = name
        self.description = description
        self.tweak_ids = tweak_ids

    def get_tweak_ids(self, sys_info: dict = None) -> list:
        return list(self.tweak_ids)

    def get_warnings(self, sys_info: dict = None) -> list:
        warnings = []
        if sys_info and self.id == "gaming" and sysinfo.is_laptop():
            warnings.append("Profil Gaming mengaktifkan Ultimate Performance — konsumsi baterai naik.")
        if sys_info and self.id == "developer":
            warnings.append("Profil Developer mematikan Windows Search — gunakan tool search alternatif.")
        return warnings


PROFILES = {
    "gaming": Profile(
        "gaming", "Gaming",
        "Maksimalkan FPS dan minimalisasi input lag.",
        GAMING_TWEAKS,
    ),
    "office": Profile(
        "office", "Office / Daily Use",
        "Stabilitas maksimal, konsumsi daya efisien.",
        OFFICE_TWEAKS,
    ),
    "developer": Profile(
        "developer", "Developer",
        "Maksimalkan resource untuk coding, build, dan virtualization.",
        DEVELOPER_TWEAKS,
    ),
    "battery": Profile(
        "battery", "Laptop Battery Saver",
        "Maksimalkan daya tahan baterai.",
        BATTERY_TWEAKS,
    ),
}


def save_custom_profile(name: str, tweak_ids: list) -> Path:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    path = DATA_DIR / "custom_profiles.json"
    data = {}
    if path.exists():
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            data = {}
    data[name] = tweak_ids
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    return path


def load_custom_profiles() -> dict:
    path = DATA_DIR / "custom_profiles.json"
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}
