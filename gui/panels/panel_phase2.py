import customtkinter as ctk
import threading
from gui.theme import get_colors, FONTS, SPACING, t
from gui.components.tweak_card import TweakCard, RiskFooter
from gui.components.warning_dialog import WarningDialog
from tweaks.phase2 import PHASE2_TWEAKS
from core import engine


class Phase2Panel(ctk.CTkScrollableFrame):
    def __init__(self, parent, log_panel=None, **kwargs):
        colors = get_colors()
        super().__init__(parent, fg_color=colors["bg_primary"], corner_radius=0, **kwargs)
        self.log_panel = log_panel

        header = ctk.CTkLabel(
            self, text=t("nav.phase2", "Fase 2 — Kernel"),
            font=FONTS["heading"], text_color=colors["text_primary"],
            anchor="w",
        )
        header.pack(fill="x", padx=SPACING["lg"], pady=(SPACING["lg"], SPACING["sm"]))

        warn_bar = ctk.CTkFrame(self, fg_color=colors["danger_bg"], corner_radius=8)
        warn_bar.pack(fill="x", padx=SPACING["lg"], pady=(0, SPACING["md"]))
        ctk.CTkLabel(
            warn_bar,
            text="⚠ Fase ini memodifikasi kernel. Hover untuk penjelasan tiap tweak.",
            font=FONTS["small"], text_color=colors["danger"],
            wraplength=600,
        ).pack(padx=SPACING["md"], pady=SPACING["sm"])

        self.cards = {}
        for tweak in PHASE2_TWEAKS:
            card = TweakCard(self, tweak=tweak, on_toggle=self._on_toggle)
            card.pack(fill="x", padx=SPACING["md"], pady=2)
            self.cards[tweak["id"]] = card

        RiskFooter(self).pack(fill="x", padx=SPACING["lg"], pady=(SPACING["md"], SPACING["sm"]))

        threading.Thread(target=self._detect_states, daemon=True).start()

    def _detect_states(self):
        for tweak in PHASE2_TWEAKS:
            try:
                applied = engine.check_tweak_applied(tweak)
                card = self.cards.get(tweak["id"])
                if card and applied:
                    self.after(0, lambda c=card: c.set_state(True))
            except Exception:
                pass

    def _on_toggle(self, tweak, enabled):
        if enabled:
            WarningDialog(self.winfo_toplevel(), tweak, on_confirm=lambda: self._do_apply(tweak))
        else:
            self._do_undo(tweak)

    def _do_apply(self, tweak):
        result = engine.apply_tweak(tweak)
        if self.log_panel:
            icon = "✓" if result.success else "✗"
            self.log_panel.add_entry(f"{icon} {tweak['name']}: {result.message}")

    def _do_undo(self, tweak):
        result = engine.rollback_tweak(tweak["id"])
        if self.log_panel:
            icon = "↩" if result.success else "✗"
            self.log_panel.add_entry(f"{icon} Undo {tweak['name']}: {result.message}")
