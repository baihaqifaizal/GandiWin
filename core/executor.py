import subprocess
import sys
import os
import json
from typing import Any
from core.result import Result

try:
    import winreg
except ImportError:
    winreg = None


def _run_process(cmd: str, shell: str = "cmd") -> Result:
    try:
        if shell == "powershell":
            args = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", cmd]
        else:
            args = ["cmd", "/c", cmd]
        proc = subprocess.run(
            args, capture_output=True, text=True, timeout=120, creationflags=subprocess.CREATE_NO_WINDOW
        )
        if proc.returncode == 0:
            return Result.ok(proc.stdout.strip() if proc.stdout else "Command executed")
        return Result.fail(proc.stderr.strip() or f"Exit code {proc.returncode}", "Command failed")
    except subprocess.TimeoutExpired:
        return Result.fail("Timeout setelah 120 detik", "Command timeout")
    except Exception as e:
        return Result.fail(str(e), "Execution error")


REG_TYPE_MAP = {
    "DWORD":     winreg.REG_DWORD if winreg else 4,
    "QWORD":     winreg.REG_QWORD if winreg else 11,
    "SZ":        winreg.REG_SZ if winreg else 1,
    "EXPAND_SZ": winreg.REG_EXPAND_SZ if winreg else 2,
    "BINARY":    winreg.REG_BINARY if winreg else 3,
}

HIVE_MAP = {
    "HKLM": winreg.HKEY_LOCAL_MACHINE if winreg else None,
    "HKCU": winreg.HKEY_CURRENT_USER if winreg else None,
    "HKCR": winreg.HKEY_CLASSES_ROOT if winreg else None,
}


def _parse_reg_path(path: str):
    parts = path.split("\\", 1)
    hive = HIVE_MAP.get(parts[0])
    subkey = parts[1] if len(parts) > 1 else ""
    return hive, subkey


def read_registry_value(path: str, key: str) -> Any:
    if not winreg:
        return None
    hive, subkey = _parse_reg_path(path)
    try:
        with winreg.OpenKey(hive, subkey, 0, winreg.KEY_READ | winreg.KEY_WOW64_64KEY) as k:
            value, _ = winreg.QueryValueEx(k, key)
            return value
    except (FileNotFoundError, OSError):
        return None


def apply_registry_tweak(actions: list) -> Result:
    if not winreg:
        return Result.fail("winreg not available", "Platform not supported")
    errors = []
    for act in actions:
        path, key, value = act["path"], act["key"], act["value"]
        reg_type = REG_TYPE_MAP.get(act.get("reg_type", "DWORD"), winreg.REG_DWORD)
        hive, subkey = _parse_reg_path(path)
        try:
            with winreg.CreateKeyEx(hive, subkey, 0, winreg.KEY_WRITE | winreg.KEY_WOW64_64KEY) as k:
                winreg.SetValueEx(k, key, 0, reg_type, value)
        except Exception as e:
            errors.append(f"{path}\\{key}: {e}")
    if errors:
        return Result.fail("; ".join(errors), f"Registry: {len(errors)} error(s)")
    return Result.ok(f"Registry: {len(actions)} value(s) set")


def apply_cmd_tweak(actions: list) -> Result:
    errors = []
    for act in actions:
        r = _run_process(act["command"], "cmd")
        if not r.success:
            errors.append(r.error or r.message)
    if errors:
        return Result.fail("; ".join(errors), f"CMD: {len(errors)} error(s)")
    return Result.ok(f"CMD: {len(actions)} command(s) executed")


def apply_ps_tweak(actions: list) -> Result:
    errors = []
    for act in actions:
        r = _run_process(act["command"], "powershell")
        if not r.success:
            errors.append(r.error or r.message)
    if errors:
        return Result.fail("; ".join(errors), f"PowerShell: {len(errors)} error(s)")
    return Result.ok(f"PowerShell: {len(actions)} command(s) executed")


def apply_service_tweak(actions: list) -> Result:
    errors = []
    for act in actions:
        svc = act["service"]
        state = act["state"]
        if state == "disabled":
            r = _run_process(f'sc.exe config "{svc}" start= disabled & sc.exe stop "{svc}"', "cmd")
        elif state == "manual":
            r = _run_process(f'sc.exe config "{svc}" start= demand', "cmd")
        elif state == "automatic":
            r = _run_process(f'sc.exe config "{svc}" start= auto & sc.exe start "{svc}"', "cmd")
        else:
            r = Result.fail(f"Unknown state: {state}")
        if not r.success:
            errors.append(f"{svc}: {r.error or r.message}")
    if errors:
        return Result.fail("; ".join(errors), f"Service: {len(errors)} error(s)")
    return Result.ok(f"Service: {len(actions)} service(s) configured")


def apply_task_tweak(actions: list) -> Result:
    errors = []
    for act in actions:
        task_path = act["task_path"]
        state = act["state"]
        verb = "/Disable" if state == "disable" else "/Enable"
        r = _run_process(f'schtasks /Change /TN "{task_path}" {verb}', "cmd")
        if not r.success:
            errors.append(f"{task_path}: {r.error or r.message}")
    if errors:
        return Result.fail("; ".join(errors), f"Task: {len(errors)} error(s)")
    return Result.ok(f"Task: {len(actions)} task(s) configured")


def apply_file_delete_tweak(actions: list) -> Result:
    import shutil
    errors = []
    for act in actions:
        target = os.path.expandvars(act.get("path", act.get("command", "")))
        try:
            if os.path.isdir(target):
                shutil.rmtree(target, ignore_errors=True)
            elif os.path.isfile(target):
                os.remove(target)
            elif "command" in act:
                r = _run_process(act["command"], "cmd")
                if not r.success:
                    errors.append(r.error or r.message)
        except Exception as e:
            errors.append(str(e))
    if errors:
        return Result.fail("; ".join(errors), f"Delete: {len(errors)} error(s)")
    return Result.ok(f"Delete: {len(actions)} item(s) processed")


def apply_appx_tweak(actions: list) -> Result:
    errors = []
    for act in actions:
        pkg = act["package"]
        cmd = f"Get-AppxPackage '*{pkg}*' | Remove-AppxPackage -ErrorAction SilentlyContinue"
        r = _run_process(cmd, "powershell")
        if not r.success:
            errors.append(f"{pkg}: {r.error or r.message}")
    if errors:
        return Result.fail("; ".join(errors), f"Appx: {len(errors)} error(s)")
    return Result.ok(f"Appx: {len(actions)} package(s) removed")


def get_service_start_type(service_name: str) -> int:
    if not winreg:
        return -1
    try:
        path = f"SYSTEM\\CurrentControlSet\\Services\\{service_name}"
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, path, 0, winreg.KEY_READ) as k:
            val, _ = winreg.QueryValueEx(k, "Start")
            return val
    except (FileNotFoundError, OSError):
        return -1


def is_service_running(service_name: str) -> bool:
    r = _run_process(f'sc.exe query "{service_name}"', "cmd")
    return "RUNNING" in (r.message or "")
