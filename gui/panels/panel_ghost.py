import customtkinter as ctk
from gui.theme import get_colors, FONTS, SPACING, t
from gui.components.tweak_card import TweakCard
from gui.components.warning_dialog import WarningDialog
from gui.components.progress_bar import ProgressBar
from tweaks.phase5_ghost import GHOST_MODES, get_all_groups, get_all_tweaks
from core import engine


class GhostPanel(ctk.CTkScrollableFrame):
    def __init__(self, parent, log_panel=None, **kwargs):
        colors = get_colors()
        super().__init__(parent, fg_color=colors["bg_primary"], corner_radius=0, **kwargs)
        self.log_panel = log_panel
        self._current_step = 0
        self._selected_mode = "compact"

        header = ctk.CTkLabel(
            self, text=t("nav.ghost", "Ghost Migration"),
            font=FONTS["heading"], text_color=colors["text_primary"],
            anchor="w",
        )
        header.pack(fill="x", padx=SPACING["lg"], pady=(SPACING["lg"], SPACING["sm"]))

        desc = ctk.CTkLabel(
            self, text="Replika Ghost Spectre tanpa reinstall OS. Aman, reversible, dengan penjelasan per-item.",
            font=FONTS["small"], text_color=colors["text_muted"], anchor="w",
        )
        desc.pack(fill="x", padx=SPACING["lg"], pady=(0, SPACING["md"]))

        self.content_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.content_frame.pack(fill="both", expand=True, padx=SPACING["md"])

        self._show_step1()

    def _clear_content(self):
        for w in self.content_frame.winfo_children():
            w.destroy()

    def _show_step1(self):
        self._clear_content()
        self._current_step = 1
        colors = get_colors()

        step_label = ctk.CTkLabel(
            self.content_frame, text=t("ghost.step1", "Langkah 1: Pilih Mode"),
            font=FONTS["body_bold"], text_color=colors["accent"],
        )
        step_label.pack(pady=(SPACING["md"], SPACING["sm"]))

        modes = [
            ("compact", t("ghost.compact", "Compact"), "Aman untuk semua user. Hemat 200-400 MB RAM.", colors["safe"]),
            ("superlite", t("ghost.superlite", "SuperLite"), "Semua dari Compact + services berat dimatikan.", colors["warning"]),
            ("se", t("ghost.se", "SE — Special Edition"), "Kernel tweaks agresif. Hanya untuk advanced user.", colors["danger"]),
        ]

        self._mode_var = ctk.StringVar(value="compact")
        for mode_id, label, desc, color in modes:
            frame = ctk.CTkFrame(self.content_frame, fg_color=colors["bg_card"], corner_radius=10)
            frame.pack(fill="x", pady=3)

            rb = ctk.CTkRadioButton(
                frame, text=label, variable=self._mode_var, value=mode_id,
                font=FONTS["body_bold"], text_color=colors["text_primary"],
                fg_color=color, hover_color=color,
            )
            rb.pack(padx=SPACING["md"], pady=(SPACING["sm"], 2), anchor="w")

            d = ctk.CTkLabel(frame, text=desc, font=FONTS["small"], text_color=colors["text_muted"], anchor="w")
            d.pack(padx=(SPACING["xl"] + SPACING["md"], SPACING["md"]), pady=(0, SPACING["sm"]), anchor="w")

        next_btn = ctk.CTkButton(
            self.content_frame, text="Lanjut →", width=120, height=36,
            font=FONTS["body_bold"], corner_radius=8,
            fg_color=colors["accent"], hover_color=colors["accent_hover"],
            command=self._go_step2,
        )
        next_btn.pack(pady=SPACING["lg"])

    def _go_step2(self):
        self._selected_mode = self._mode_var.get()
        self._clear_content()
        self._current_step = 2
        colors = get_colors()

        step_label = ctk.CTkLabel(
            self.content_frame, text=t("ghost.step3", "Review Tweaks"),
            font=FONTS["body_bold"], text_color=colors["accent"],
        )
        step_label.pack(pady=(SPACING["md"], SPACING["sm"]))

        groups = get_all_groups(self._selected_mode)
        self._group_vars = {}
        for group in groups:
            gf = ctk.CTkFrame(self.content_frame, fg_color=colors["bg_card"], corner_radius=8)
            gf.pack(fill="x", pady=3)

            risk = group.get("risk", "safe")
            risk_color = colors.get(risk, colors["safe"])

            header = ctk.CTkLabel(
                gf, text=f"● {group['name']}",
                font=FONTS["body_bold"], text_color=risk_color, anchor="w",
            )
            header.pack(padx=SPACING["md"], pady=(SPACING["sm"], 2), anchor="w")

            for tw in group.get("tweaks", []):
                var = ctk.BooleanVar(value=True)
                self._group_vars[tw["id"]] = (var, tw)
                cb = ctk.CTkCheckBox(
                    gf, text=tw["name"], variable=var,
                    font=FONTS["small"], text_color=colors["text_secondary"],
                    fg_color=colors["accent"],
                )
                cb.pack(padx=(SPACING["xl"], SPACING["md"]), pady=1, anchor="w")

            pad = ctk.CTkFrame(gf, fg_color="transparent", height=SPACING["sm"])
            pad.pack()

        btn_frame = ctk.CTkFrame(self.content_frame, fg_color="transparent")
        btn_frame.pack(pady=SPACING["lg"])

        back_btn = ctk.CTkButton(
            btn_frame, text="← Kembali", width=100, height=36, corner_radius=8,
            font=FONTS["body"], fg_color=colors["bg_hover"], text_color=colors["text_secondary"],
            command=self._show_step1,
        )
        back_btn.pack(side="left", padx=SPACING["sm"])

        apply_btn = ctk.CTkButton(
            btn_frame, text="🚀 Apply Migration", width=160, height=36, corner_radius=8,
            font=FONTS["body_bold"], fg_color=colors["accent"], hover_color=colors["accent_hover"],
            command=self._apply_migration,
        )
        apply_btn.pack(side="left", padx=SPACING["sm"])

    def _apply_migration(self):
        selected = [(var, tw) for tid, (var, tw) in self._group_vars.items() if var.get()]

        has_danger = any(tw.get("risk") == "danger" for _, tw in selected)
        if has_danger:
            dummy = {"id": "ghost_migration", "name": "Ghost Migration", "risk": "danger",
                     "description": "Migration ini mengandung tweak berbahaya.",
                     "detail": "Beberapa tweak yang dipilih memodifikasi kernel dan keamanan sistem. Pastikan Anda memahami risikonya.", "type": "cmd", "actions": []}
            WarningDialog(self.winfo_toplevel(), dummy, on_confirm=lambda: self._do_apply(selected))
            return

        self._do_apply(selected)

    def _do_apply(self, selected):
        self._clear_content()
        colors = get_colors()

        step_label = ctk.CTkLabel(
            self.content_frame, text=t("ghost.step4", "Applying Migration..."),
            font=FONTS["body_bold"], text_color=colors["accent"],
        )
        step_label.pack(pady=SPACING["md"])

        progress = ProgressBar(self.content_frame)
        progress.pack(fill="x", padx=SPACING["md"], pady=SPACING["sm"])

        total = len(selected)
        for i, (var, tw) in enumerate(selected):
            progress.update_progress((i + 1) / total, f"Applying: {tw['name']}")
            result = engine.apply_tweak(tw)
            if self.log_panel:
                icon = "✓" if result.success else "✗"
                self.log_panel.add_entry(f"{icon} Ghost: {tw['name']}: {result.message}")

        progress.update_progress(1.0, "✓ Migration selesai!")

        done_label = ctk.CTkLabel(
            self.content_frame, text=f"✓ {total} tweak berhasil diterapkan",
            font=FONTS["body_bold"], text_color=colors["safe"],
        )
        done_label.pack(pady=SPACING["md"])

        restart_btn = ctk.CTkButton(
            self.content_frame, text="← Kembali ke awal", width=140, height=32, corner_radius=8,
            font=FONTS["body"], fg_color=colors["bg_hover"], text_color=colors["text_secondary"],
            command=self._show_step1,
        )
        restart_btn.pack(pady=SPACING["sm"])
