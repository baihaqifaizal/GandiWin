import json
import os
from datetime import datetime
from pathlib import Path

DATA_DIR = Path(__file__).parent.parent / "data" / "logs"


def _ensure_dir():
    DATA_DIR.mkdir(parents=True, exist_ok=True)


def _today_file() -> Path:
    return DATA_DIR / f"{datetime.now().strftime('%Y-%m-%d')}.json"


def log_action(tweak_id: str, action: str, result_obj) -> None:
    _ensure_dir()
    path = _today_file()
    entries = []
    if path.exists():
        try:
            entries = json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            entries = []
    entries.append({
        "timestamp": datetime.now().isoformat(timespec="milliseconds"),
        "action": action,
        "tweak_id": tweak_id,
        "result": "success" if result_obj.success else "fail",
        "message": result_obj.message,
        "error": result_obj.error,
    })
    path.write_text(json.dumps(entries, indent=2, ensure_ascii=False), encoding="utf-8")


def get_today_log() -> list:
    path = _today_file()
    if not path.exists():
        return []
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []


def get_log(date_str: str) -> list:
    path = DATA_DIR / f"{date_str}.json"
    if not path.exists():
        return []
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []
