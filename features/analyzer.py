import os
import subprocess
from dataclasses import dataclass, field
from typing import Optional

try:
    import psutil
except ImportError:
    psutil = None

from core import sysinfo


@dataclass
class Recommendation:
    action: str
    tweak_id: Optional[str]
    message: str
    impact: str
    risk: str = "safe"


@dataclass
class AnalysisReport:
    bloatware: list = field(default_factory=list)
    services: list = field(default_factory=list)
    startup: list = field(default_factory=list)
    thermal: dict = field(default_factory=dict)
    disk: dict = field(default_factory=dict)
    ram: dict = field(default_factory=dict)
    tweak_status: dict = field(default_factory=dict)
    score: int = 0
    recommendations: list = field(default_factory=list)


KNOWN_BLOATWARE = [
    "Microsoft.MicrosoftSolitaireCollection", "king.com.CandyCrushSaga",
    "Microsoft.XboxGamingOverlay", "Microsoft.XboxGameOverlay",
    "Microsoft.549981C3F5F10", "Microsoft.BingNews", "Microsoft.BingWeather",
    "Microsoft.BingFinance", "Microsoft.BingSports", "Microsoft.BingTravel",
    "Microsoft.GetHelp", "Microsoft.Getstarted", "Microsoft.MixedReality.Portal",
    "Microsoft.Microsoft3DViewer", "Microsoft.People", "Microsoft.SkypeApp",
    "Microsoft.WindowsFeedbackHub", "Microsoft.WindowsMaps",
    "Microsoft.ZuneMusic", "Microsoft.ZuneVideo",
    "MicrosoftCorporationII.MicrosoftFamily", "Microsoft.Teams",
]

SAFE_TO_DISABLE_SERVICES = [
    "DiagTrack", "dmwappushservice", "SysMain", "WSearch", "Fax",
    "RetailDemo", "lfsvc", "WpcMonSvc", "XblGameSave", "XboxNetApiSvc",
    "MapsBroker", "DoSvc",
]


class SystemAnalyzer:
    def scan_bloatware(self) -> list:
        found = []
        try:
            r = subprocess.run(
                ["powershell", "-NoProfile", "-Command", "Get-AppxPackage | Select-Object -ExpandProperty Name"],
                capture_output=True, text=True, timeout=30, creationflags=subprocess.CREATE_NO_WINDOW
            )
            installed = set(r.stdout.strip().split("\n")) if r.stdout else set()
            for pkg in KNOWN_BLOATWARE:
                if any(pkg.lower() in p.lower() for p in installed):
                    found.append(pkg)
        except Exception:
            pass
        return found

    def scan_services(self) -> list:
        running = []
        for svc_name in SAFE_TO_DISABLE_SERVICES:
            if sysinfo.is_service_running(svc_name):
                running.append(svc_name)
        return running

    def scan_startup(self) -> list:
        items = []
        try:
            import winreg
            for root_key, path in [
                (winreg.HKEY_CURRENT_USER, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Run"),
                (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Run"),
            ]:
                try:
                    with winreg.OpenKey(root_key, path) as k:
                        i = 0
                        while True:
                            try:
                                name, value, _ = winreg.EnumValue(k, i)
                                items.append({"name": name, "value": value})
                                i += 1
                            except OSError:
                                break
                except (FileNotFoundError, OSError):
                    continue
        except ImportError:
            pass
        return items

    def scan_thermal(self) -> dict:
        return {
            "cpu_temp": sysinfo.get_cpu_temp(),
            "gpu_temp": sysinfo.get_gpu_temp(),
            "cpu_warning": sysinfo.get_cpu_temp() > 85,
            "gpu_warning": sysinfo.get_gpu_temp() > 85,
        }

    def scan_disk(self) -> dict:
        return {
            "partitions": sysinfo.get_disk_info(),
            "type": sysinfo.detect_ssd_or_hdd(),
            "is_ssd": sysinfo.is_ssd(),
        }

    def scan_ram(self) -> dict:
        if not psutil:
            return {}
        vm = psutil.virtual_memory()
        return {
            "total_gb": round(vm.total / 1e9, 1),
            "used_gb": round(vm.used / 1e9, 1),
            "usage_pct": vm.percent,
            "warning": vm.percent > 85,
        }

    def scan_tweak_status(self, all_tweaks: list) -> dict:
        applied = 0
        total = len(all_tweaks)
        for t in all_tweaks:
            if t["type"] == "registry" and t["actions"]:
                act = t["actions"][0]
                from core.executor import read_registry_value
                cur = read_registry_value(act["path"], act["key"])
                if cur == act["value"]:
                    applied += 1
            elif t["type"] == "service" and t["actions"]:
                act = t["actions"][0]
                if not sysinfo.is_service_running(act["service"]):
                    applied += 1
        return {"applied": applied, "total": total, "pct": round(applied / max(total, 1) * 100)}

    def calculate_score(self, report: AnalysisReport) -> int:
        score = 100
        score -= len(report.bloatware) * 2
        score -= len(report.services) * 3
        score -= min(len(report.startup), 10) * 2
        if report.thermal.get("cpu_warning"):
            score -= 15
        if report.ram.get("warning"):
            score -= 10
        tweak_pct = report.tweak_status.get("pct", 0)
        score -= max(0, (100 - tweak_pct) // 4)
        return max(0, min(100, score))

    def generate_recommendations(self, report: AnalysisReport) -> list:
        recs = []
        if report.bloatware:
            recs.append(Recommendation("APPLY", "remove_bloatware_uwp", f"Hapus {len(report.bloatware)} bloatware UWP", "high"))
        if report.services:
            recs.append(Recommendation("APPLY", "disable_telemetry_services", f"Matikan {len(report.services)} service tidak perlu", "high"))
        if len(report.startup) > 5:
            recs.append(Recommendation("REVIEW", None, f"{len(report.startup)} program startup terdeteksi", "medium"))
        if report.thermal.get("cpu_warning"):
            recs.append(Recommendation("WARNING", None, f"CPU {report.thermal['cpu_temp']}°C — bersihkan debu dulu", "critical", "danger"))
        if report.ram.get("warning"):
            recs.append(Recommendation("WARNING", None, f"RAM {report.ram.get('usage_pct', 0)}% terpakai", "medium", "warning"))
        return recs

    def run_full_scan(self, all_tweaks: list = None) -> AnalysisReport:
        if all_tweaks is None:
            all_tweaks = []
        report = AnalysisReport()
        report.bloatware = self.scan_bloatware()
        report.services = self.scan_services()
        report.startup = self.scan_startup()
        report.thermal = self.scan_thermal()
        report.disk = self.scan_disk()
        report.ram = self.scan_ram()
        report.tweak_status = self.scan_tweak_status(all_tweaks)
        report.score = self.calculate_score(report)
        report.recommendations = self.generate_recommendations(report)
        return report
