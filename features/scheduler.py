import json
import subprocess
from pathlib import Path
from core.result import Result
from core import sysinfo

DATA_DIR = Path(__file__).parent.parent / "data"

MAINTENANCE_TASKS = [
    {
        "id": "weekly_cleanup",
        "name": "Disk Cleanup (Temp Files)",
        "description": "Hapus file temporary mingguan",
        "interval": "WEEKLY",
        "day": "MON",
        "time": "03:00",
        "commands": [
            r"del /q /f /s %TEMP%\* 2>nul",
            r"del /q /f /s C:\Windows\Temp\* 2>nul",
        ],
    },
    {
        "id": "browser_cache_cleanup",
        "name": "Clear Browser Cache",
        "description": "Hapus cache browser mingguan",
        "interval": "WEEKLY",
        "day": "MON",
        "time": "03:30",
        "commands": [
            r'powershell -Command "Remove-Item -Path \"$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*\" -Force -Recurse -ErrorAction SilentlyContinue"',
        ],
    },
    {
        "id": "dns_flush",
        "name": "DNS Cache Flush",
        "description": "Flush DNS cache saat startup",
        "interval": "ONLOGON",
        "day": None,
        "time": None,
        "commands": ["ipconfig /flushdns"],
    },
    {
        "id": "ssd_trim",
        "name": "SSD TRIM",
        "description": "Jalankan TRIM pada SSD mingguan",
        "interval": "WEEKLY",
        "day": "SUN",
        "time": "04:00",
        "commands": ['powershell -Command "Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue"'],
    },
    {
        "id": "prefetch_cleanup",
        "name": "Prefetch Cleanup",
        "description": "Hapus cache prefetch bulanan",
        "interval": "MONTHLY",
        "day": "1",
        "time": "04:00",
        "commands": [r"del /q /f /s C:\Windows\Prefetch\* 2>nul"],
    },
    {
        "id": "event_log_clear",
        "name": "Clear Event Log",
        "description": "Bersihkan Windows Event Log bulanan",
        "interval": "MONTHLY",
        "day": "1",
        "time": "04:30",
        "commands": ['powershell -Command "wevtutil el | ForEach-Object { wevtutil cl $_ 2>$null }"'],
    },
]


def register_task(task: dict, exe_path: str = None) -> Result:
    task_name = f"GandiWin\\{task['id']}"
    interval = task["interval"]

    if exe_path:
        tr = f'"{exe_path}" --headless --run-task {task["id"]}'
    else:
        tr = " & ".join(task["commands"])

    cmd_parts = [
        "schtasks", "/Create", "/F",
        "/TN", f'"{task_name}"',
        "/TR", f'"{tr}"',
        "/RU", "SYSTEM",
    ]

    if interval == "WEEKLY":
        cmd_parts.extend(["/SC", "WEEKLY", "/D", task.get("day", "MON"), "/ST", task.get("time", "03:00")])
    elif interval == "MONTHLY":
        cmd_parts.extend(["/SC", "MONTHLY", "/D", task.get("day", "1"), "/ST", task.get("time", "04:00")])
    elif interval == "ONLOGON":
        cmd_parts.extend(["/SC", "ONLOGON"])

    cmd = " ".join(cmd_parts)
    try:
        proc = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=30,
            creationflags=subprocess.CREATE_NO_WINDOW
        )
        if proc.returncode == 0:
            return Result.ok(f"Task '{task['id']}' registered")
        return Result.fail(proc.stderr.strip(), f"Failed to register '{task['id']}'")
    except Exception as e:
        return Result.fail(str(e))


def unregister_task(task_id: str) -> Result:
    cmd = f'schtasks /Delete /TN "GandiWin\\{task_id}" /F'
    try:
        proc = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=15,
            creationflags=subprocess.CREATE_NO_WINDOW
        )
        if proc.returncode == 0:
            return Result.ok(f"Task '{task_id}' removed")
        return Result.fail(proc.stderr.strip())
    except Exception as e:
        return Result.fail(str(e))


def list_registered() -> list:
    registered = []
    try:
        proc = subprocess.run(
            'schtasks /Query /TN "GandiWin\\" /FO CSV /NH',
            shell=True, capture_output=True, text=True, timeout=15,
            creationflags=subprocess.CREATE_NO_WINDOW
        )
        if proc.returncode == 0 and proc.stdout:
            for line in proc.stdout.strip().split("\n"):
                parts = line.strip('"').split('","')
                if parts:
                    registered.append(parts[0].replace("GandiWin\\", ""))
    except Exception:
        pass
    return registered


def save_schedule_config(config: dict):
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    path = DATA_DIR / "scheduler.json"
    path.write_text(json.dumps(config, indent=2, ensure_ascii=False), encoding="utf-8")


def load_schedule_config() -> dict:
    path = DATA_DIR / "scheduler.json"
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}
