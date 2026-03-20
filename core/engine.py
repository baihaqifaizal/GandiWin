from core.result import Result
from core import executor, backup, logger

HANDLERS = {
    "registry":    executor.apply_registry_tweak,
    "cmd":         executor.apply_cmd_tweak,
    "powershell":  executor.apply_ps_tweak,
    "service":     executor.apply_service_tweak,
    "task":        executor.apply_task_tweak,
    "file_delete": executor.apply_file_delete_tweak,
    "appx":        executor.apply_appx_tweak,
}

REQUIRED_KEYS = {"id", "name", "description", "risk", "type", "actions"}


def validate_tweak_schema(tweak: dict) -> None:
    missing = REQUIRED_KEYS - set(tweak.keys())
    if missing:
        raise ValueError(f"Tweak '{tweak.get('id', '?')}' missing keys: {missing}")
    if tweak["type"] not in HANDLERS:
        raise ValueError(f"Unknown tweak type: {tweak['type']}")
    if tweak["risk"] not in ("safe", "warning", "danger"):
        raise ValueError(f"Invalid risk level: {tweak['risk']}")


def apply_tweak(tweak: dict, dry_run: bool = False) -> Result:
    try:
        validate_tweak_schema(tweak)
    except ValueError as e:
        return Result.fail(str(e), "Validation error")

    if tweak.get("warn_if"):
        try:
            if tweak["warn_if"]():
                return Result.warn("Kondisi terdeteksi, konfirmasi diperlukan")
        except Exception:
            pass

    if tweak.get("rollback", True):
        try:
            backup.snapshot(tweak)
        except Exception as e:
            logger.log_action(tweak["id"], "backup_fail", Result.fail(str(e)))

    if dry_run:
        r = Result.dry_run(tweak)
        logger.log_action(tweak["id"], "dry_run", r)
        return r

    handler = HANDLERS[tweak["type"]]
    result = handler(tweak["actions"])
    logger.log_action(tweak["id"], "apply", result)
    return result


def rollback_tweak(tweak_id: str) -> Result:
    result = backup.restore(tweak_id)
    logger.log_action(tweak_id, "rollback", result)
    return result


def rollback_session(session_id: str) -> list:
    results = backup.restore_all(session_id)
    for tweak_id, result in results:
        logger.log_action(tweak_id, "rollback", result)
    return results


def check_tweak_applied(tweak: dict) -> bool | str:
    tweak_type = tweak.get("type", "")
    actions = tweak.get("actions", [])
    if not actions:
        return False

    try:
        if tweak_type == "registry":
            all_missing = True
            for act in actions:
                current = executor.read_registry_value(act["path"], act["key"])
                if current is not None:
                    all_missing = False
                    if current != act["value"]:
                        return False
            return "missing" if all_missing else True

        elif tweak_type == "service":
            # For services, we check the first action's service availability
            act = actions[0]
            start_type = executor.get_service_start_type(act["service"])
            if start_type == -1:
                return "missing"
            
            if act["state"] == "disabled" and start_type != 4:
                return False
            elif act["state"] == "manual" and start_type != 3:
                return False
            elif act["state"] == "automatic" and start_type not in (1, 2):
                return False
            return True

        elif tweak_type == "task":
            # Check first task in actions
            act = actions[0]
            r = executor._run_process(f'schtasks /Query /TN "{act["task_path"]}" /FO CSV /NH', "cmd")
            if not r.success:
                return "missing"
            
            if act["state"] == "disable" and "Disabled" not in (r.message or ""):
                return False
            return True

        elif tweak_type == "appx":
            r = executor._run_process(
                "Get-AppxPackage | Select-Object -ExpandProperty Name", "powershell"
            )
            installed = set((r.message or "").lower().split("\n"))
            all_not_found = True
            found_any = False
            for act in actions:
                pkg = act["package"].lower()
                if any(pkg in p for p in installed):
                    found_any = True
                    all_not_found = False
            
            # If any package is still installed, it's NOT applied (False)
            if found_any:
                return False
            # If no packages found at all, it's missing
            return "missing"

    except Exception:
        pass
    return False

