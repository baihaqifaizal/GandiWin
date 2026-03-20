import customtkinter as ctk
import threading
from collections import defaultdict
from gui.theme import get_colors, FONTS, SPACING, t
from gui.components.warning_dialog import WarningDialog
from tweaks.phase1 import PHASE1_TWEAKS
from tweaks.win11debloat import WIN11_DEBLOAT_TWEAKS, WIN11_DEBLOAT_DROPDOWNS
from core import engine

CATEGORY_ICONS = {
    "Fase 1 — Fondasi": "🧱",
    "Privacy & Suggested Content": "🔒",
    "AI": "✨",
    "Gaming": "🎮",
    "Start Menu & Search": "🪟",
    "Taskbar": "➖",
    "File Explorer": "📁",
    "Windows Update": "🔄",
    "Appearance": "🎨",
    "System": "💻",
    "Other": "🔧",
    "Multi-tasking": "🔀"
}

DUPLICATE_IDS = {
    "w11d_DisableLocationServices", 
    "w11d_DisableMouseAcceleration", 
    "w11d_DisableDeliveryOptimization"
}

class Phase1Panel(ctk.CTkScrollableFrame):
    def __init__(self, parent, log_panel=None, precheck_results=None, **kwargs):
        colors = get_colors()
        super().__init__(parent, fg_color=colors["bg_primary"], corner_radius=0, **kwargs)
        self.log_panel = log_panel
        self.precheck_results = precheck_results or {}
        
        self.tweak_lookup = {t["id"]: t for t in (PHASE1_TWEAKS + WIN11_DEBLOAT_TWEAKS)}

        # Header Title
        header = ctk.CTkLabel(
            self, text="System Tweaks",
            font=FONTS["title"], text_color=colors["text_primary"], anchor="w"
        )
        header.pack(fill="x", padx=SPACING["lg"], pady=(SPACING["lg"], SPACING["xs"]))
        
        desc = ctk.CTkLabel(
            self, text="Select which tweaks you want to apply to your system, hover over settings for more information",
            font=FONTS["body"], text_color=colors["text_secondary"], anchor="w", justify="left"
        )
        desc.pack(fill="x", padx=SPACING["lg"], pady=(0, SPACING["md"]))

        # Toolbar
        toolbar = ctk.CTkFrame(self, fg_color="transparent")
        toolbar.pack(fill="x", padx=SPACING["lg"], pady=(0, SPACING["md"]))
        
        btn_default = ctk.CTkButton(
            toolbar, text="Select Default Settings", 
            fg_color=colors["bg_card"], hover_color=colors["bg_hover"], 
            text_color=colors["text_primary"], width=140, border_color=colors["border"], border_width=1
        )
        btn_default.pack(side="left", padx=(0, SPACING["sm"]))
        
        btn_clear = ctk.CTkButton(
            toolbar, text="Clear Selection", 
            fg_color=colors["bg_card"], hover_color=colors["bg_hover"], 
            text_color=colors["text_primary"], width=120, border_color=colors["border"], border_width=1
        )
        btn_clear.pack(side="left")
        
        self.search_entry = ctk.CTkEntry(
            toolbar, placeholder_text="🔍 Search setting...", 
            width=250, border_color=colors["border"], fg_color=colors["bg_card"]
        )
        self.search_entry.pack(side="right")
        self.search_entry.bind("<KeyRelease>", self._on_search)

        # Masonry Grid (3 Columns)
        self.grid_container = ctk.CTkFrame(self, fg_color="transparent")
        self.grid_container.pack(fill="both", expand=True, padx=SPACING["lg"], pady=SPACING["md"])
        
        self.grid_container.grid_columnconfigure((0, 1, 2), weight=1, uniform="col")
        self.cols = []
        for i in range(3):
            col = ctk.CTkFrame(self.grid_container, fg_color="transparent")
            col.grid(row=0, column=i, sticky="nsew", padx=SPACING["sm"])
            self.cols.append(col)

        self.checkboxes = {}
        self.dropdowns = {}
        self.cards = []
        
        dropdown_feature_ids = set()
        for dd in WIN11_DEBLOAT_DROPDOWNS:
            for opt in dd["options"]:
                dropdown_feature_ids.update(opt["feature_ids"])

        # Populate Groups
        groups = defaultdict(lambda: {"tweaks": [], "dropdowns": []})
        groups["Fase 1 — Fondasi"]["tweaks"] = PHASE1_TWEAKS
        
        for tweak in WIN11_DEBLOAT_TWEAKS:
            if tweak["id"] in DUPLICATE_IDS or tweak["id"] in dropdown_feature_ids:
                continue
            groups[tweak["category"]]["tweaks"].append(tweak)
            
        for dd in WIN11_DEBLOAT_DROPDOWNS:
            groups[dd["category"]]["dropdowns"].append(dd)
            
        col_idx = 0
        for category, items in groups.items():
            if not items["tweaks"] and not items["dropdowns"]:
                continue
                
            colors = get_colors()
            card = ctk.CTkFrame(self.cols[col_idx], fg_color=colors["bg_card"], corner_radius=8, border_width=1, border_color=colors["border"])
            card.pack(fill="x", pady=(0, SPACING["md"]))
            self.cards.append({"frame": card, "category": category})
            
            icon = CATEGORY_ICONS.get(category, "🔧")
            lbl = ctk.CTkLabel(card, text=f"{icon} {category} (?)", font=FONTS["tweak_title"], text_color=colors["text_primary"])
            lbl.pack(anchor="w", padx=SPACING["md"], pady=(SPACING["md"], SPACING["sm"]))
            
            for dd in items["dropdowns"]:
                lbl_dd = ctk.CTkLabel(card, text=dd["name"], font=FONTS["body"], text_color=colors["text_secondary"])
                lbl_dd.pack(anchor="w", padx=SPACING["md"], pady=(SPACING["xs"], 0))
                
                options = ["Windows Default"] + [opt["label"] for opt in dd["options"]]
                option_menu = ctk.CTkOptionMenu(
                    card, values=options,
                    font=FONTS["body"],
                    fg_color=colors["bg_card"],
                    button_color=colors["bg_sidebar"],
                    button_hover_color=colors["bg_hover"],
                    dropdown_fg_color=colors["bg_card"],
                    dropdown_hover_color=colors["bg_hover"],
                    text_color=colors["text_primary"],
                    dropdown_text_color=colors["text_primary"],
                    command=lambda val, d=dd: self._on_dropdown_change(d, val)
                )
                option_menu.pack(anchor="w", fill="x", padx=SPACING["md"], pady=(0, SPACING["sm"]))
                self.dropdowns[dd["id"]] = {"ui": option_menu, "data": dd, "lbl": lbl_dd}
            
            for tweak in items["tweaks"]:
                cb = ctk.CTkCheckBox(
                    card, text=tweak["name"], 
                    font=FONTS["body"], 
                    text_color=colors["text_secondary"],
                    command=lambda t=tweak: self._on_toggle_tweak(t),
                    width=0, checkbox_width=18, checkbox_height=18
                )
                cb.pack(anchor="w", padx=SPACING["md"], pady=(0, SPACING["sm"]))
                self.checkboxes[tweak["id"]] = {"ui": cb, "tweak": tweak, "card": card}
                
            ctk.CTkFrame(card, height=SPACING["xs"], fg_color="transparent").pack()
            col_idx = (col_idx + 1) % 3

        self._apply_precheck()

    def _on_search(self, event=None):
        query = self.search_entry.get().lower()
        for tweak_id, item in self.checkboxes.items():
            tweak = item["tweak"]
            cb = item["ui"]
            if query in tweak["name"].lower() or query in tweak["category"].lower():
                cb.pack(anchor="w", padx=SPACING["md"], pady=(0, SPACING["sm"]))
            else:
                cb.pack_forget()
                
        for dd_id, item in self.dropdowns.items():
            dd = item["data"]
            ui = item["ui"]
            lbl = item["lbl"]
            if query in dd["name"].lower() or query in dd["category"].lower():
                lbl.pack(anchor="w", padx=SPACING["md"], pady=(SPACING["xs"], 0))
                ui.pack(anchor="w", fill="x", padx=SPACING["md"], pady=(0, SPACING["sm"]))
            else:
                lbl.pack_forget()
                ui.pack_forget()

    def _apply_precheck(self):
        colors = get_colors()
        for tweak_id, item in self.checkboxes.items():
            res = self.precheck_results.get(tweak_id, False)
            if res == "missing":
                item["ui"].select()
                item["ui"].configure(
                    state="disabled", 
                    text_color="grey",
                    fg_color=colors["text_muted"],
                    border_color=colors["text_muted"]
                )
            elif res is True:
                item["ui"].select()

        for dd in WIN11_DEBLOAT_DROPDOWNS:
            if dd["id"] not in self.dropdowns:
                continue
            selected_label = "Windows Default"
            any_missing = False
            for opt in dd["options"]:
                all_applied = True
                for fid in opt["feature_ids"]:
                    res = self.precheck_results.get(fid, False)
                    if res == "missing":
                        any_missing = True
                    if not res: # False or None
                        all_applied = False
                        break
                if all_applied and opt["feature_ids"]:
                    selected_label = opt["label"]
                    break
            
            ui = self.dropdowns[dd["id"]]["ui"]
            ui.set(selected_label)
            if any_missing:
                ui.configure(state="disabled")

    def _on_dropdown_change(self, dropdown_data, selected_value):
        if selected_value == "Windows Default":
            # Rollback all options
            for opt in dropdown_data["options"]:
                for fid in opt["feature_ids"]:
                    if fid in self.tweak_lookup:
                        self._do_undo(self.tweak_lookup[fid], None)
            return

        # Rollback others, apply selected
        for opt in dropdown_data["options"]:
            if opt["label"] == selected_value:
                for fid in opt["feature_ids"]:
                    if fid in self.tweak_lookup:
                        self._do_apply(self.tweak_lookup[fid], None)
            else:
                for fid in opt["feature_ids"]:
                    if fid in self.tweak_lookup:
                        self._do_undo(self.tweak_lookup[fid], None)

    def _on_toggle_tweak(self, tweak):
        cb = self.checkboxes[tweak["id"]]["ui"]
        is_checked = cb.get()
        if is_checked:
            risk = tweak.get("risk", "safe")
            if risk in ("warning", "danger"):
                WarningDialog(
                    self.winfo_toplevel(), tweak, 
                    on_confirm=lambda: self._do_apply(tweak, cb),
                    on_cancel=lambda: cb.deselect()
                )
            else:
                self._do_apply(tweak, cb)
        else:
            self._do_undo(tweak, cb)

    def _do_apply(self, tweak, cb=None):
        result = engine.apply_tweak(tweak)
        if hasattr(self, "log_panel") and self.log_panel:
            icon = "✓" if result.success else "✗"
            self.log_panel.add_entry(f"{icon} {tweak['name']}: {result.message}")
        if not result.success and cb:
            cb.deselect()

    def _do_undo(self, tweak, cb=None):
        result = engine.rollback_tweak(tweak["id"])
        if hasattr(self, "log_panel") and self.log_panel:
            icon = "↩" if result.success else "✗"
            self.log_panel.add_entry(f"{icon} Undo {tweak['name']}: {result.message}")
        if not result.success and cb:
            cb.select()
