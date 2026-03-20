import json
from pathlib import Path

COLORS = {
    "dark": {
        "bg_primary": "#0f0f14",
        "bg_secondary": "#1a1a24",
        "bg_card": "#22222e",
        "bg_sidebar": "#16161e",
        "bg_hover": "#2a2a38",
        "text_primary": "#e8e8ee",
        "text_secondary": "#9898a8",
        "text_muted": "#5a5a6e",
        "accent": "#6c5ce7",
        "accent_hover": "#7e6ff0",
        "safe": "#00b894",
        "safe_bg": "#1a2e28",
        "warning": "#fdcb6e",
        "warning_bg": "#2e2a1e",
        "danger": "#e17055",
        "danger_bg": "#2e1e1a",
        "success": "#00cec9",
        "border": "#2d2d3a",
        "scrollbar": "#3a3a4a",
    },
    "light": {
        "bg_primary": "#f5f5f8",
        "bg_secondary": "#ffffff",
        "bg_card": "#ffffff",
        "bg_sidebar": "#eaeaef",
        "bg_hover": "#e0e0e8",
        "text_primary": "#1a1a2e",
        "text_secondary": "#5a5a70",
        "text_muted": "#9a9ab0",
        "accent": "#6c5ce7",
        "accent_hover": "#5a4bd6",
        "safe": "#00a884",
        "safe_bg": "#d4f0e8",
        "warning": "#e8a838",
        "warning_bg": "#f5ead4",
        "danger": "#d04838",
        "danger_bg": "#f5d8d4",
        "success": "#00b8b3",
        "border": "#d8d8e0",
        "scrollbar": "#c0c0ca",
    },
}

FONTS = {
    "title": ("Segoe UI", 26, "bold"),
    "subtitle": ("Segoe UI", 16),
    "heading": ("Segoe UI", 20, "bold"),
    "body": ("Segoe UI", 14),
    "body_bold": ("Segoe UI", 14, "bold"),
    "small": ("Segoe UI", 12),
    "mono": ("Consolas", 13),
    "badge": ("Segoe UI", 11, "bold"),
    "tweak_title": ("Segoe UI", 15, "bold"),
}

SPACING = {
    "xs": 4,
    "sm": 8,
    "md": 12,
    "lg": 16,
    "xl": 24,
    "xxl": 32,
}

RISK_DOT = {
    "safe": {"char": "●", "color_key": "safe", "label": "Aman"},
    "warning": {"char": "●", "color_key": "warning", "label": "Perhatian"},
    "danger": {"char": "●", "color_key": "danger", "label": "Berbahaya"},
}

TRANSLATIONS_DIR = Path(__file__).parent.parent / "assets" / "translations"
CONFIG_PATH = Path(__file__).parent.parent / "data" / "config.json"

_translations = {}
_current_lang = "id"
_current_theme = "dark"


def load_config() -> dict:
    if CONFIG_PATH.exists():
        try:
            return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            pass
    return {"language": "id", "theme": "dark"}


def save_config(config: dict):
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_PATH.write_text(json.dumps(config, indent=2, ensure_ascii=False), encoding="utf-8")


def load_translations(lang: str = "id"):
    global _translations, _current_lang
    _current_lang = lang
    path = TRANSLATIONS_DIR / f"{lang}.json"
    if path.exists():
        try:
            _translations = json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            _translations = {}


def t(key: str, fallback: str = "") -> str:
    return _translations.get(key, fallback or key)


def get_colors() -> dict:
    return COLORS.get(_current_theme, COLORS["dark"])


def set_theme(theme: str):
    global _current_theme
    if theme in COLORS:
        _current_theme = theme


def get_theme() -> str:
    return _current_theme


config = load_config()
_current_lang = config.get("language", "id")
_current_theme = config.get("theme", "dark")
load_translations(_current_lang)
