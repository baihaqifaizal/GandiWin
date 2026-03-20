import json
import os
from datetime import datetime
from pathlib import Path
from typing import Optional
from core.result import Result
from core import executor

DATA_DIR = Path(__file__).parent.parent / "data" / "backups"


def _ensure_dir():
    DATA_DIR.mkdir(parents=True, exist_ok=True)


def _session_id() -> str:
    return datetime.now().strftime("%Y-%m-%d_%H-%M-%S")


def _current_session_file() -> Path:
    files = sorted(DATA_DIR.glob("*.json"), reverse=True)
    if files:
        return files[0]
    return DATA_DIR / f"{_session_id()}.json"


def _load_session(path: Path) -> dict:
    if path.exists():
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            pass
    return {"session_id": path.stem, "tweaks": {}}


def _save_session(path: Path, data: dict):
    _ensure_dir()
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False, default=str), encoding="utf-8")


def snapshot(tweak: dict) -> bool:
    _ensure_dir()
    session_path = _current_session_file()
    session = _load_session(session_path)
    tweak_id = tweak["id"]
    tweak_type = tweak["type"]
    original = {}

    if tweak_type == "registry":
        originals = []
        for act in tweak["actions"]:
            val = executor.read_registry_value(act["path"], act["key"])
            originals.append({
                "path": act["path"],
                "key": act["key"],
                "value": val,
                "reg_type": act.get("reg_type", "DWORD"),
            })
        original = {"type": "registry", "original_values": originals}

    elif tweak_type == "service":
        svc_states = []
        for act in tweak["actions"]:
            start_type = executor.get_service_start_type(act["service"])
            running = executor.is_service_running(act["service"])
            svc_states.append({
                "service": act["service"],
                "start_type": start_type,
                "status": "running" if running else "stopped",
            })
        original = {"type": "service", "original_states": svc_states}

    elif tweak_type == "task":
        original = {"type": "task", "actions": tweak["actions"]}

    elif tweak_type in ("cmd", "powershell"):
        rollback_cmd = tweak.get("rollback_cmd")
        original = {"type": tweak_type, "rollback_cmd": rollback_cmd}

    elif tweak_type == "appx":
        original = {"type": "appx", "packages": [a["package"] for a in tweak["actions"]]}

    else:
        original = {"type": tweak_type, "rollback_cmd": tweak.get("rollback_cmd")}

    original["timestamp"] = datetime.now().isoformat(timespec="milliseconds")
    session["tweaks"][tweak_id] = original
    _save_session(session_path, session)
    return True


def load_snapshot(tweak_id: str) -> Optional[dict]:
    for f in sorted(DATA_DIR.glob("*.json"), reverse=True):
        session = _load_session(f)
        if tweak_id in session.get("tweaks", {}):
            return session["tweaks"][tweak_id]
    return None


def restore(tweak_id: str) -> Result:
    snap = load_snapshot(tweak_id)
    if not snap:
        return Result.fail("Backup not found", f"No backup for {tweak_id}")

    snap_type = snap.get("type")

    if snap_type == "registry" and snap.get("original_values"):
        actions = []
        for ov in snap["original_values"]:
            if ov["value"] is not None:
                actions.append(ov)
        if actions:
            return executor.apply_registry_tweak(actions)
        return Result.ok("Registry values were default (None), nothing to restore")

    elif snap_type == "service" and snap.get("original_states"):
        actions = []
        for s in snap["original_states"]:
            state_map = {2: "automatic", 3: "manual", 4: "disabled"}
            state = state_map.get(s["start_type"], "manual")
            actions.append({"service": s["service"], "state": state})
        return executor.apply_service_tweak(actions)

    elif snap_type == "task" and snap.get("actions"):
        restore_actions = []
        for a in snap["actions"]:
            new_state = "enable" if a["state"] == "disable" else "disable"
            restore_actions.append({"task_path": a["task_path"], "state": new_state})
        return executor.apply_task_tweak(restore_actions)

    elif snap.get("rollback_cmd"):
        cmd = snap["rollback_cmd"]
        shell = "powershell" if snap_type == "powershell" else "cmd"
        if shell == "powershell":
            return executor.apply_ps_tweak([{"command": cmd}])
        return executor.apply_cmd_tweak([{"command": cmd}])

    return Result.fail("No rollback strategy", f"Cannot rollback {tweak_id}")


def restore_all(session_id: str) -> list:
    path = DATA_DIR / f"{session_id}.json"
    session = _load_session(path)
    results = []
    for tweak_id in session.get("tweaks", {}):
        results.append((tweak_id, restore(tweak_id)))
    return results


def list_sessions() -> list:
    _ensure_dir()
    sessions = []
    for f in sorted(DATA_DIR.glob("*.json"), reverse=True):
        session = _load_session(f)
        sessions.append({
            "session_id": session.get("session_id", f.stem),
            "file": str(f),
            "tweak_count": len(session.get("tweaks", {})),
        })
    return sessions
