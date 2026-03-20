import customtkinter as ctk
from gui.theme import get_colors, FONTS, SPACING, t


class Sidebar(ctk.CTkFrame):
    ITEMS = [
        ("phase1", "nav.phase1", "🔧"),
        ("phase2", "nav.phase2", "⚙"),
        ("phase4", "nav.phase4", "🌐"),
        ("ghost", "nav.ghost", "👻"),
        ("analyzer", "nav.analyzer", "🔍"),
        ("benchmark", "nav.benchmark", "📊"),
        ("settings", "nav.settings", "⚙"),
    ]

    def __init__(self, parent, on_navigate=None, **kwargs):
        colors = get_colors()
        super().__init__(parent, fg_color=colors["bg_sidebar"], corner_radius=0, width=220, **kwargs)
        self.grid_propagate(False)
        self.on_navigate = on_navigate
        self._buttons = {}
        self._active = None

        self.grid_columnconfigure(0, weight=1)

        logo_frame = ctk.CTkFrame(self, fg_color="transparent", height=70)
        logo_frame.grid(row=0, column=0, sticky="ew", padx=SPACING["md"], pady=(SPACING["xl"], SPACING["md"]))
        logo_frame.grid_propagate(False)
        logo_frame.grid_columnconfigure(0, weight=1)

        title = ctk.CTkLabel(
            logo_frame, text=t("app.title", "GandiWin"),
            font=FONTS["title"], text_color=colors["accent"],
            anchor="w",
        )
        title.grid(row=0, column=0, sticky="w")

        subtitle = ctk.CTkLabel(
            logo_frame, text=t("app.subtitle", "Toolkit Optimasi Windows"),
            font=FONTS["small"], text_color=colors["text_muted"],
            anchor="w",
        )
        subtitle.grid(row=1, column=0, sticky="w")

        sep = ctk.CTkFrame(self, fg_color=colors["border"], height=1)
        sep.grid(row=1, column=0, sticky="ew", padx=SPACING["md"], pady=SPACING["sm"])

        for i, (key, label_key, icon) in enumerate(self.ITEMS):
            btn = ctk.CTkButton(
                self, text=f"  {icon}  {t(label_key, key)}",
                font=FONTS["body"], height=40, corner_radius=8,
                fg_color="transparent", hover_color=colors["bg_hover"],
                text_color=colors["text_secondary"],
                anchor="w",
                command=lambda k=key: self._navigate(k),
            )
            btn.grid(row=i + 2, column=0, padx=SPACING["sm"], pady=2, sticky="ew")
            self._buttons[key] = btn

        spacer = ctk.CTkFrame(self, fg_color="transparent")
        spacer.grid(row=len(self.ITEMS) + 2, column=0, sticky="nsew")
        self.grid_rowconfigure(len(self.ITEMS) + 2, weight=1)

        version = ctk.CTkLabel(
            self, text="v1.0.0-dev",
            font=FONTS["small"], text_color=colors["text_muted"],
        )
        version.grid(row=len(self.ITEMS) + 3, column=0, pady=SPACING["md"])

    def _navigate(self, key: str):
        self.set_active(key)
        if self.on_navigate:
            self.on_navigate(key)

    def set_active(self, key: str):
        colors = get_colors()
        if self._active and self._active in self._buttons:
            self._buttons[self._active].configure(
                fg_color="transparent", text_color=colors["text_secondary"]
            )
        self._active = key
        if key in self._buttons:
            self._buttons[key].configure(
                fg_color=colors["bg_hover"], text_color=colors["accent"]
            )
