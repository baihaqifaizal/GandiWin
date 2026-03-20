import json
import subprocess
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

try:
    import psutil
except ImportError:
    psutil = None

DATA_DIR = Path(__file__).parent.parent / "data"


@dataclass
class BenchmarkResult:
    boot_time_sec: float = 0.0
    ram_idle_gb: float = 0.0
    cpu_idle_pct: float = 0.0
    disk_write_mbps: float = 0.0
    disk_read_mbps: float = 0.0
    ping_google_ms: float = 0.0
    ping_cloudflare_ms: float = 0.0
    timestamp: str = ""

    def to_dict(self) -> dict:
        return {
            "boot_time_sec": self.boot_time_sec,
            "ram_idle_gb": self.ram_idle_gb,
            "cpu_idle_pct": self.cpu_idle_pct,
            "disk_write_mbps": self.disk_write_mbps,
            "disk_read_mbps": self.disk_read_mbps,
            "ping_google_ms": self.ping_google_ms,
            "ping_cloudflare_ms": self.ping_cloudflare_ms,
            "timestamp": self.timestamp,
        }


def _get_boot_time() -> float:
    try:
        r = subprocess.run(
            ["powershell", "-NoProfile", "-Command",
             "Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Diagnostics-Performance/Operational';"
             "Id=100} -MaxEvents 1 -ErrorAction SilentlyContinue | "
             "ForEach-Object { ([xml]$_.ToXml()).Event.EventData.Data | "
             "Where-Object { $_.Name -eq 'BootTime' } | Select-Object -ExpandProperty '#text' }"],
            capture_output=True, text=True, timeout=15, creationflags=subprocess.CREATE_NO_WINDOW
        )
        if r.stdout.strip():
            return round(int(r.stdout.strip()) / 1000, 1)
    except Exception:
        pass
    return 0.0


def _get_idle_metrics(duration_sec: int = 10) -> tuple:
    if not psutil:
        return 0.0, 0.0
    samples_cpu = []
    samples_ram = []
    end = time.time() + duration_sec
    while time.time() < end:
        samples_cpu.append(psutil.cpu_percent(interval=1))
        vm = psutil.virtual_memory()
        samples_ram.append(vm.used / 1e9)
    avg_cpu = round(sum(samples_cpu) / max(len(samples_cpu), 1), 1)
    avg_ram = round(sum(samples_ram) / max(len(samples_ram), 1), 1)
    return avg_cpu, avg_ram


def _disk_benchmark() -> tuple:
    import tempfile, os
    write_speed = 0.0
    read_speed = 0.0
    test_size = 100 * 1024 * 1024
    data = os.urandom(test_size)
    try:
        fd, path = tempfile.mkstemp(suffix=".benchtest")
        os.close(fd)
        start = time.perf_counter()
        with open(path, "wb") as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        elapsed = time.perf_counter() - start
        write_speed = round((test_size / 1e6) / max(elapsed, 0.001), 1)

        start = time.perf_counter()
        with open(path, "rb") as f:
            _ = f.read()
        elapsed = time.perf_counter() - start
        read_speed = round((test_size / 1e6) / max(elapsed, 0.001), 1)

        os.unlink(path)
    except Exception:
        pass
    return write_speed, read_speed


def _ping(host: str) -> float:
    try:
        r = subprocess.run(
            ["ping", "-n", "3", "-w", "2000", host],
            capture_output=True, text=True, timeout=15, creationflags=subprocess.CREATE_NO_WINDOW
        )
        for line in r.stdout.split("\n"):
            if "Average" in line or "Rata-rata" in line:
                parts = line.split("=")
                if parts:
                    ms_str = parts[-1].strip().replace("ms", "").strip()
                    return float(ms_str)
    except Exception:
        pass
    return 0.0


def run_benchmark(idle_duration: int = 10, callback=None) -> BenchmarkResult:
    result = BenchmarkResult()
    result.timestamp = datetime.now().isoformat(timespec="seconds")

    if callback:
        callback("Measuring boot time...")
    result.boot_time_sec = _get_boot_time()

    if callback:
        callback(f"Measuring idle metrics ({idle_duration}s)...")
    result.cpu_idle_pct, result.ram_idle_gb = _get_idle_metrics(idle_duration)

    if callback:
        callback("Running disk benchmark (100MB)...")
    result.disk_write_mbps, result.disk_read_mbps = _disk_benchmark()

    if callback:
        callback("Pinging Google...")
    result.ping_google_ms = _ping("8.8.8.8")

    if callback:
        callback("Pinging Cloudflare...")
    result.ping_cloudflare_ms = _ping("1.1.1.1")

    return result


def save_benchmark(label: str, result: BenchmarkResult) -> Path:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    path = DATA_DIR / "benchmark.json"
    data = {}
    if path.exists():
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            data = {}
    data[label] = result.to_dict()
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    return path


def load_benchmarks() -> dict:
    path = DATA_DIR / "benchmark.json"
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}


def compare(before: dict, after: dict) -> list:
    rows = []
    fields = [
        ("Boot Time", "boot_time_sec", "s", True),
        ("RAM idle", "ram_idle_gb", "GB", True),
        ("CPU idle", "cpu_idle_pct", "%", True),
        ("Disk Write", "disk_write_mbps", "MB/s", False),
        ("Disk Read", "disk_read_mbps", "MB/s", False),
        ("Ping Google", "ping_google_ms", "ms", True),
        ("Ping Cloudflare", "ping_cloudflare_ms", "ms", True),
    ]
    for label, key, unit, lower_is_better in fields:
        b = before.get(key, 0)
        a = after.get(key, 0)
        if b > 0:
            delta_pct = round((a - b) / b * 100, 1)
        else:
            delta_pct = 0
        better = (delta_pct < 0) if lower_is_better else (delta_pct > 0)
        rows.append({
            "label": label,
            "before": f"{b} {unit}",
            "after": f"{a} {unit}",
            "delta_pct": delta_pct,
            "better": better,
        })
    return rows
