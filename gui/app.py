import customtkinter as ctk
from gui.theme import get_colors, set_theme, load_translations, load_config, FONTS
from gui.sidebar import Sidebar
from gui.components.log_panel import LogPanel
from gui.panels.panel_phase1 import Phase1Panel
from gui.panels.panel_phase2 import Phase2Panel
from gui.panels.panel_phase4 import Phase4Panel
from gui.panels.panel_ghost import GhostPanel
from gui.panels.panel_analyzer import AnalyzerPanel
from gui.panels.panel_benchmark import BenchmarkPanel
from gui.panels.panel_settings import SettingsPanel


class GandiWinApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        config = load_config()
        set_theme(config.get("theme", "dark"))
        load_translations(config.get("language", "id"))
        ctk.set_appearance_mode("dark" if config.get("theme", "dark") == "dark" else "light")

        self.title("GandiWin — Windows Optimization Toolkit")
        self.geometry("1100x700")
        self.minsize(900, 600)

        colors = get_colors()
        self.configure(fg_color=colors["bg_primary"])

        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        self.log_panel = LogPanel(self, height=120)

        self.sidebar = Sidebar(self, on_navigate=self._navigate)
        self.sidebar.grid(row=0, column=0, rowspan=2, sticky="nsw")

        self.content_frame = ctk.CTkFrame(self, fg_color=colors["bg_primary"], corner_radius=0)
        self.content_frame.grid(row=0, column=1, sticky="nsew")
        self.content_frame.grid_columnconfigure(0, weight=1)
        self.content_frame.grid_rowconfigure(0, weight=1)

        self.log_panel.grid(row=1, column=1, sticky="sew", padx=8, pady=(4, 8))

        self._panels = {}
        self._current_panel = None

        self._navigate("phase1")
        self.sidebar.set_active("phase1")

    def _navigate(self, key: str):
        if self._current_panel:
            self._current_panel.grid_forget()

        if key not in self._panels:
            self._panels[key] = self._create_panel(key)

        panel = self._panels[key]
        if panel:
            panel.grid(row=0, column=0, sticky="nsew", in_=self.content_frame)
            self._current_panel = panel

    def _create_panel(self, key: str):
        panel_map = {
            "phase1": lambda: Phase1Panel(self.content_frame, log_panel=self.log_panel),
            "phase2": lambda: Phase2Panel(self.content_frame, log_panel=self.log_panel),
            "phase4": lambda: Phase4Panel(self.content_frame, log_panel=self.log_panel),
            "ghost": lambda: GhostPanel(self.content_frame, log_panel=self.log_panel),
            "analyzer": lambda: AnalyzerPanel(self.content_frame, log_panel=self.log_panel),
            "benchmark": lambda: BenchmarkPanel(self.content_frame, log_panel=self.log_panel),
            "settings": lambda: SettingsPanel(self.content_frame, on_theme_change=self._on_theme_change),
        }
        factory = panel_map.get(key)
        return factory() if factory else None

    def _on_theme_change(self, theme: str):
        mode = "dark" if theme == "dark" else "light"
        ctk.set_appearance_mode(mode)
        self.log_panel.add_entry(f"🎨 Tema berubah ke {theme}")
