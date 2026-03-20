import customtkinter as ctk
import threading
from gui.theme import get_colors, FONTS, SPACING, t
from features.analyzer import SystemAnalyzer
from tweaks.phase1 import PHASE1_TWEAKS
from tweaks.phase2 import PHASE2_TWEAKS
from tweaks.phase4 import PHASE4_TWEAKS


class AnalyzerPanel(ctk.CTkScrollableFrame):
    def __init__(self, parent, log_panel=None, **kwargs):
        colors = get_colors()
        super().__init__(parent, fg_color=colors["bg_primary"], corner_radius=0, **kwargs)
        self.log_panel = log_panel
        self._analyzer = SystemAnalyzer()

        header = ctk.CTkLabel(
            self, text=t("nav.analyzer", "System Analyzer"),
            font=FONTS["heading"], text_color=colors["text_primary"], anchor="w",
        )
        header.pack(fill="x", padx=SPACING["lg"], pady=(SPACING["lg"], SPACING["sm"]))

        desc = ctk.CTkLabel(
            self, text="Scan kondisi PC dan lihat rekomendasi tweak yang paling berdampak.",
            font=FONTS["small"], text_color=colors["text_muted"], anchor="w",
        )
        desc.pack(fill="x", padx=SPACING["lg"], pady=(0, SPACING["md"]))

        self.scan_btn = ctk.CTkButton(
            self, text=t("btn.scan", "🔍 Scan Sekarang"), width=160, height=40,
            font=FONTS["body_bold"], corner_radius=8,
            fg_color=colors["accent"], hover_color=colors["accent_hover"],
            command=self._start_scan,
        )
        self.scan_btn.pack(pady=SPACING["md"])

        self.result_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.result_frame.pack(fill="both", expand=True, padx=SPACING["md"])

    def _start_scan(self):
        self.scan_btn.configure(state="disabled", text="Scanning...")
        for w in self.result_frame.winfo_children():
            w.destroy()
        threading.Thread(target=self._run_scan, daemon=True).start()

    def _run_scan(self):
        all_tweaks = PHASE1_TWEAKS + PHASE2_TWEAKS + PHASE4_TWEAKS
        report = self._analyzer.run_full_scan(all_tweaks)
        self.after(0, lambda: self._display_results(report))

    def _display_results(self, report):
        colors = get_colors()
        self.scan_btn.configure(state="normal", text=t("btn.scan", "🔍 Scan Sekarang"))

        score_frame = ctk.CTkFrame(self.result_frame, fg_color=colors["bg_card"], corner_radius=12)
        score_frame.pack(fill="x", pady=SPACING["sm"])

        score_color = colors["safe"] if report.score >= 70 else (colors["warning"] if report.score >= 40 else colors["danger"])
        score_label = ctk.CTkLabel(
            score_frame, text=f"{report.score}", font=("Segoe UI", 48, "bold"),
            text_color=score_color,
        )
        score_label.pack(pady=(SPACING["md"], 0))

        score_sub = ctk.CTkLabel(
            score_frame, text=f"/ 100 — {t('analyzer.score', 'Optimization Score')}",
            font=FONTS["body"], text_color=colors["text_secondary"],
        )
        score_sub.pack(pady=(0, SPACING["md"]))

        categories = [
            ("Bloatware", len(report.bloatware), f"{len(report.bloatware)} app terdeteksi"),
            ("Services", len(report.services), f"{len(report.services)} layanan tidak perlu aktif"),
            ("Startup", len(report.startup), f"{len(report.startup)} program startup"),
            ("Tweak Status", 0, f"{report.tweak_status.get('applied', 0)}/{report.tweak_status.get('total', 0)} tweak sudah optimal"),
        ]

        for name, count, detail in categories:
            cf = ctk.CTkFrame(self.result_frame, fg_color=colors["bg_card"], corner_radius=8)
            cf.pack(fill="x", pady=2)
            row = ctk.CTkFrame(cf, fg_color="transparent")
            row.pack(fill="x", padx=SPACING["md"], pady=SPACING["sm"])
            ctk.CTkLabel(row, text=name, font=FONTS["body_bold"], text_color=colors["text_primary"], anchor="w").pack(side="left")
            ctk.CTkLabel(row, text=detail, font=FONTS["small"], text_color=colors["text_muted"]).pack(side="right")

        if report.recommendations:
            rec_header = ctk.CTkLabel(
                self.result_frame, text=t("analyzer.recommendations", "Rekomendasi"),
                font=FONTS["body_bold"], text_color=colors["text_primary"], anchor="w",
            )
            rec_header.pack(fill="x", pady=(SPACING["md"], SPACING["sm"]))

            for rec in report.recommendations:
                rf = ctk.CTkFrame(self.result_frame, fg_color=colors["bg_card"], corner_radius=8)
                rf.pack(fill="x", pady=2)
                risk_key = getattr(rec, "risk", "safe")
                icon = {"safe": "✅", "warning": "⚠", "danger": "🔴"}.get(risk_key, "•")
                ctk.CTkLabel(
                    rf, text=f"{icon} [{rec.action}] {rec.message}",
                    font=FONTS["small"], text_color=colors["text_secondary"],
                    anchor="w", wraplength=500,
                ).pack(padx=SPACING["md"], pady=SPACING["sm"], anchor="w")

        if self.log_panel:
            self.log_panel.add_entry(f"🔍 Scan selesai — Score: {report.score}/100")
