import customtkinter as ctk
from gui.theme import get_colors, FONTS, SPACING, RISK_DOT


class TweakCard(ctk.CTkFrame):
    def __init__(self, parent, tweak: dict, on_toggle=None, **kwargs):
        colors = get_colors()
        super().__init__(parent, fg_color=colors["bg_card"], corner_radius=10, **kwargs)
        self.tweak = tweak
        self.on_toggle = on_toggle
        self._enabled = False
        self._tooltip_win = None
        self._tooltip_after_id = None

        self.grid_columnconfigure(1, weight=1)

        risk = tweak.get("risk", "safe")
        dot_cfg = RISK_DOT.get(risk, RISK_DOT["safe"])

        dot = ctk.CTkLabel(
            self, text=dot_cfg["char"], font=("Segoe UI", 14),
            text_color=colors[dot_cfg["color_key"]],
            width=20,
        )
        dot.grid(row=0, column=0, padx=(SPACING["md"], 4), pady=SPACING["sm"])

        self._name_label = ctk.CTkLabel(
            self, text=tweak["name"],
            font=FONTS["tweak_title"], text_color=colors["text_primary"],
            anchor="w",
        )
        self._name_label.grid(row=0, column=1, padx=0, pady=SPACING["sm"], sticky="w")

        self.toggle = ctk.CTkSwitch(
            self, text="", width=44, height=22,
            fg_color=colors["bg_hover"],
            progress_color=colors["accent"],
            button_color=colors["text_secondary"],
            button_hover_color=colors["text_primary"],
            command=self._on_switch,
        )
        self.toggle.grid(row=0, column=2, padx=SPACING["md"], pady=SPACING["sm"])

        meta_parts = []
        if tweak.get("needs_restart"):
            meta_parts.append("⟳ restart")
        if not tweak.get("rollback", True):
            meta_parts.append("⚠ irreversible")
        if meta_parts:
            meta = ctk.CTkLabel(
                self, text="  ".join(meta_parts),
                font=("Segoe UI", 10), text_color=colors["text_muted"],
                anchor="w",
            )
            meta.grid(row=0, column=3, padx=(0, SPACING["md"]), pady=SPACING["sm"])

        for widget in (self, dot, self._name_label):
            widget.bind("<Enter>", self._on_enter)
            widget.bind("<Leave>", self._on_leave)

    def _on_enter(self, event=None):
        colors = get_colors()
        self.configure(fg_color=colors["bg_hover"])
        if self._tooltip_after_id is None and self._tooltip_win is None:
            self._tooltip_after_id = self.after(400, self._create_tooltip)

    def _on_leave(self, event=None):
        colors = get_colors()
        self.configure(fg_color=colors["bg_card"])

        rx, ry = self.winfo_rootx(), self.winfo_rooty()
        rw, rh = self.winfo_width(), self.winfo_height()
        if event and rx <= event.x_root <= rx + rw and ry <= event.y_root <= ry + rh:
            return

        self._kill_tooltip()

    def _create_tooltip(self):
        self._tooltip_after_id = None
        if self._tooltip_win is not None:
            return

        desc = self.tweak.get("description", "")
        detail = self.tweak.get("detail", "")
        text = desc
        if detail:
            text += f"\n\n{detail}"
        if not text:
            return

        colors = get_colors()
        self._tooltip_win = tw = ctk.CTkToplevel(self)
        tw.wm_overrideredirect(True)
        tw.configure(fg_color=colors["bg_secondary"])
        tw.attributes("-topmost", True)

        border = ctk.CTkFrame(tw, fg_color=colors["border"], corner_radius=10)
        border.pack(fill="both", expand=True, padx=1, pady=1)

        lbl = ctk.CTkLabel(
            border, text=text,
            font=FONTS["small"], text_color=colors["text_secondary"],
            wraplength=360, justify="left",
            fg_color=colors["bg_secondary"],
            corner_radius=8,
        )
        lbl.pack(padx=SPACING["sm"], pady=SPACING["sm"])

        x = self.winfo_rootx() + self.winfo_width() + 8
        y = self.winfo_rooty()

        tw.geometry(f"+{x}+{y}")
        tw.update_idletasks()

        screen_w = self.winfo_screenwidth()
        if x + tw.winfo_width() > screen_w:
            x = self.winfo_rootx() - tw.winfo_width() - 8
            tw.geometry(f"+{x}+{y}")

    def _kill_tooltip(self):
        if self._tooltip_after_id is not None:
            self.after_cancel(self._tooltip_after_id)
            self._tooltip_after_id = None
        if self._tooltip_win is not None:
            try:
                self._tooltip_win.destroy()
            except Exception:
                pass
            self._tooltip_win = None

    def destroy(self):
        self._kill_tooltip()
        super().destroy()

    def _on_switch(self):
        self._enabled = self.toggle.get() == 1
        if self.on_toggle:
            self.on_toggle(self.tweak, self._enabled)

    def set_state(self, enabled: bool):
        self._enabled = enabled
        if enabled:
            self.toggle.select()
        else:
            self.toggle.deselect()


class RiskFooter(ctk.CTkFrame):
    def __init__(self, parent, **kwargs):
        colors = get_colors()
        super().__init__(parent, fg_color="transparent", height=28, **kwargs)
        for risk, cfg in RISK_DOT.items():
            dot = ctk.CTkLabel(
                self, text=f"{cfg['char']} {cfg['label']}",
                font=FONTS["small"],
                text_color=colors[cfg["color_key"]],
            )
            dot.pack(side="left", padx=(0, SPACING["lg"]))

