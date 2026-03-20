import platform
import subprocess

try:
    import psutil
except ImportError:
    psutil = None

try:
    import wmi as wmi_module
    WMI_CONN = wmi_module.WMI()
except Exception:
    wmi_module = None
    WMI_CONN = None


def get_cpu_name() -> str:
    if WMI_CONN:
        try:
            for proc in WMI_CONN.Win32_Processor():
                return proc.Name.strip()
        except Exception:
            pass
    return platform.processor() or "Unknown"


def get_cpu_temp() -> float:
    if WMI_CONN:
        try:
            ns = wmi_module.WMI(namespace="root\\OpenHardwareMonitor")
            for sensor in ns.Sensor():
                if sensor.SensorType == "Temperature" and "CPU" in sensor.Name:
                    return float(sensor.Value)
        except Exception:
            pass
    return 0.0


def get_cpu_clock() -> float:
    if WMI_CONN:
        try:
            for proc in WMI_CONN.Win32_Processor():
                return float(proc.CurrentClockSpeed)
        except Exception:
            pass
    return 0.0


def get_gpu_name() -> str:
    if WMI_CONN:
        try:
            for gpu in WMI_CONN.Win32_VideoController():
                return gpu.Name.strip()
        except Exception:
            pass
    return "Unknown"


def get_gpu_vram() -> float:
    if WMI_CONN:
        try:
            for gpu in WMI_CONN.Win32_VideoController():
                ram = gpu.AdapterRAM
                if ram and ram > 0:
                    return round(ram / (1024 ** 3), 1)
        except Exception:
            pass
    return 0.0


def get_gpu_temp() -> float:
    if WMI_CONN:
        try:
            ns = wmi_module.WMI(namespace="root\\OpenHardwareMonitor")
            for sensor in ns.Sensor():
                if sensor.SensorType == "Temperature" and "GPU" in sensor.Name:
                    return float(sensor.Value)
        except Exception:
            pass
    return 0.0


def get_gpu_driver_version() -> str:
    if WMI_CONN:
        try:
            for gpu in WMI_CONN.Win32_VideoController():
                return gpu.DriverVersion or "Unknown"
        except Exception:
            pass
    return "Unknown"


def get_disk_info() -> list:
    if not psutil:
        return []
    disks = []
    for part in psutil.disk_partitions(all=False):
        try:
            usage = psutil.disk_usage(part.mountpoint)
            disks.append({
                "device": part.device,
                "mountpoint": part.mountpoint,
                "fstype": part.fstype,
                "total_gb": round(usage.total / (1024 ** 3), 1),
                "used_gb": round(usage.used / (1024 ** 3), 1),
                "free_gb": round(usage.free / (1024 ** 3), 1),
                "usage_pct": usage.percent,
            })
        except (PermissionError, OSError):
            continue
    return disks


def detect_ssd_or_hdd() -> str:
    try:
        r = subprocess.run(
            ["powershell", "-NoProfile", "-Command",
             "Get-PhysicalDisk | Select-Object MediaType -First 1 | ForEach-Object { $_.MediaType }"],
            capture_output=True, text=True, timeout=10, creationflags=subprocess.CREATE_NO_WINDOW
        )
        out = r.stdout.strip()
        if "SSD" in out:
            return "SSD"
        if "HDD" in out:
            return "HDD"
        if "NVMe" in out or "Unspecified" in out:
            return "NVMe"
    except Exception:
        pass
    return "Unknown"


def get_windows_version() -> str:
    ver = platform.version()
    release = platform.release()
    return f"Windows {release} (Build {ver})"


def get_windows_build() -> str:
    return platform.version()


def get_windows_edition() -> str:
    if WMI_CONN:
        try:
            for os_info in WMI_CONN.Win32_OperatingSystem():
                caption = os_info.Caption
                for ed in ("Enterprise", "Pro", "Home", "Education"):
                    if ed in caption:
                        return ed
                return caption
        except Exception:
            pass
    return "Unknown"


def is_ssd() -> bool:
    return detect_ssd_or_hdd() in ("SSD", "NVMe")


def is_laptop() -> bool:
    if not psutil:
        return False
    battery = psutil.sensors_battery()
    return battery is not None


def get_system_info() -> dict:
    cpu_count_phys = psutil.cpu_count(logical=False) if psutil else 0
    cpu_count_log = psutil.cpu_count(logical=True) if psutil else 0
    cpu_pct = psutil.cpu_percent(interval=0.5) if psutil else 0
    vm = psutil.virtual_memory() if psutil else None

    return {
        "cpu": {
            "name": get_cpu_name(),
            "cores": cpu_count_phys,
            "threads": cpu_count_log,
            "usage_pct": cpu_pct,
            "temp_celsius": get_cpu_temp(),
            "clock_mhz": get_cpu_clock(),
        },
        "ram": {
            "total_gb": round(vm.total / 1e9, 1) if vm else 0,
            "used_gb": round(vm.used / 1e9, 1) if vm else 0,
            "free_gb": round(vm.free / 1e9, 1) if vm else 0,
            "usage_pct": vm.percent if vm else 0,
        },
        "disk": {
            "partitions": get_disk_info(),
            "type": detect_ssd_or_hdd(),
        },
        "gpu": {
            "name": get_gpu_name(),
            "vram_gb": get_gpu_vram(),
            "temp_celsius": get_gpu_temp(),
            "driver_ver": get_gpu_driver_version(),
        },
        "os": {
            "version": get_windows_version(),
            "build": get_windows_build(),
            "edition": get_windows_edition(),
        },
    }
