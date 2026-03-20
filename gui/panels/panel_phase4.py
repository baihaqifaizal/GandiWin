import customtkinter as ctk
import threading
from gui.theme import get_colors, FONTS, SPACING, t
from gui.components.tweak_card import TweakCard, RiskFooter
from gui.components.warning_dialog import WarningDialog
from tweaks.phase4 import PHASE4_TWEAKS
from core import engine


class Phase4Panel(ctk.CTkScrollableFrame):
    def __init__(self, parent, log_panel=None, precheck_results=None, **kwargs):
        colors = get_colors()
        super().__init__(parent, fg_color=colors["bg_primary"], corner_radius=0, **kwargs)
        self.log_panel = log_panel
        self.precheck_results = precheck_results or {}

        header = ctk.CTkLabel(
            self, text=t("nav.phase4", "Fase 4 — Network & Gaming"),
            font=FONTS["heading"], text_color=colors["text_primary"],
            anchor="w",
        )
        header.pack(fill="x", padx=SPACING["lg"], pady=(SPACING["lg"], SPACING["sm"]))

        self.cards = {}
        for tweak in PHASE4_TWEAKS:
            card = TweakCard(self, tweak=tweak, on_toggle=self._on_toggle)
            card.pack(fill="x", padx=SPACING["md"], pady=2)
            self.cards[tweak["id"]] = card

        RiskFooter(self).pack(fill="x", padx=SPACING["lg"], pady=(SPACING["md"], SPACING["sm"]))

        self._apply_precheck()

    def _apply_precheck(self):
        for tweak in PHASE4_TWEAKS:
            res = self.precheck_results.get(tweak["id"], False)
            card = self.cards.get(tweak["id"])
            if card:
                if res == "missing":
                    card.set_disabled(True)
                elif res is True:
                    card.set_state(True)


    def _on_toggle(self, tweak, enabled):
        if enabled:
            risk = tweak.get("risk", "safe")
            if risk in ("warning", "danger"):
                WarningDialog(self.winfo_toplevel(), tweak, on_confirm=lambda: self._do_apply(tweak))
            else:
                self._do_apply(tweak)
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
