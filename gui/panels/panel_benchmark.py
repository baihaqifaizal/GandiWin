import customtkinter as ctk
import threading
from gui.theme import get_colors, FONTS, SPACING, t
from features import benchmark as bm


class BenchmarkPanel(ctk.CTkScrollableFrame):
    def __init__(self, parent, log_panel=None, **kwargs):
        colors = get_colors()
        super().__init__(parent, fg_color=colors["bg_primary"], corner_radius=0, **kwargs)
        self.log_panel = log_panel

        header = ctk.CTkLabel(
            self, text=t("nav.benchmark", "Benchmark Mode"),
            font=FONTS["heading"], text_color=colors["text_primary"], anchor="w",
        )
        header.pack(fill="x", padx=SPACING["lg"], pady=(SPACING["lg"], SPACING["sm"]))

        desc = ctk.CTkLabel(
            self, text="Ukur performa sebelum dan sesudah tweak. Tutup aplikasi lain dahulu untuk hasil akurat.",
            font=FONTS["small"], text_color=colors["text_muted"], anchor="w",
        )
        desc.pack(fill="x", padx=SPACING["lg"], pady=(0, SPACING["md"]))

        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.pack(fill="x", padx=SPACING["lg"], pady=SPACING["sm"])

        self.before_btn = ctk.CTkButton(
            btn_frame, text="📊 Benchmark SEBELUM", width=180, height=36,
            font=FONTS["body_bold"], corner_radius=8,
            fg_color=colors["accent"], hover_color=colors["accent_hover"],
            command=lambda: self._run("before"),
        )
        self.before_btn.pack(side="left", padx=(0, SPACING["sm"]))

        self.after_btn = ctk.CTkButton(
            btn_frame, text="📊 Benchmark SESUDAH", width=180, height=36,
            font=FONTS["body_bold"], corner_radius=8,
            fg_color=colors["safe"], hover_color=colors["safe"],
            command=lambda: self._run("after"),
        )
        self.after_btn.pack(side="left")

        self.status_label = ctk.CTkLabel(
            self, text="", font=FONTS["small"], text_color=colors["text_muted"],
        )
        self.status_label.pack(pady=SPACING["sm"])

        self.result_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.result_frame.pack(fill="both", expand=True, padx=SPACING["md"])

        self._show_existing()

    def _show_existing(self):
        data = bm.load_benchmarks()
        if "before" in data and "after" in data:
            self._show_comparison(data["before"], data["after"])

    def _run(self, label: str):
        self.before_btn.configure(state="disabled")
        self.after_btn.configure(state="disabled")
        self.status_label.configure(text=f"Running {label} benchmark...")

        def _worker():
            result = bm.run_benchmark(idle_duration=5, callback=lambda msg: self.after(0, lambda m=msg: self.status_label.configure(text=m)))
            bm.save_benchmark(label, result)
            self.after(0, lambda: self._on_complete(label))

        threading.Thread(target=_worker, daemon=True).start()

    def _on_complete(self, label: str):
        colors = get_colors()
        self.before_btn.configure(state="normal")
        self.after_btn.configure(state="normal")
        self.status_label.configure(text=f"✓ {label.title()} benchmark selesai!")

        if self.log_panel:
            self.log_panel.add_entry(f"📊 Benchmark '{label}' selesai")

        data = bm.load_benchmarks()
        if "before" in data and "after" in data:
            self._show_comparison(data["before"], data["after"])

    def _show_comparison(self, before: dict, after: dict):
        for w in self.result_frame.winfo_children():
            w.destroy()

        colors = get_colors()
        rows = bm.compare(before, after)

        table_header = ctk.CTkFrame(self.result_frame, fg_color=colors["bg_card"], corner_radius=8)
        table_header.pack(fill="x", pady=(SPACING["sm"], 2))
        table_header.grid_columnconfigure((0, 1, 2, 3), weight=1)

        for col, text in enumerate(["Metrik", t("benchmark.before"), t("benchmark.after"), t("benchmark.delta")]):
            ctk.CTkLabel(
                table_header, text=text, font=FONTS["body_bold"],
                text_color=colors["text_primary"],
            ).grid(row=0, column=col, padx=SPACING["sm"], pady=SPACING["sm"])

        for row in rows:
            rf = ctk.CTkFrame(self.result_frame, fg_color=colors["bg_card"], corner_radius=6)
            rf.pack(fill="x", pady=1)
            rf.grid_columnconfigure((0, 1, 2, 3), weight=1)

            ctk.CTkLabel(rf, text=row["label"], font=FONTS["body"], text_color=colors["text_primary"]).grid(row=0, column=0, padx=SPACING["sm"], pady=4)
            ctk.CTkLabel(rf, text=row["before"], font=FONTS["small"], text_color=colors["text_secondary"]).grid(row=0, column=1, padx=SPACING["sm"], pady=4)
            ctk.CTkLabel(rf, text=row["after"], font=FONTS["small"], text_color=colors["text_secondary"]).grid(row=0, column=2, padx=SPACING["sm"], pady=4)

            arrow = "↓" if row["better"] and row["delta_pct"] < 0 else ("↑" if row["better"] else "")
            delta_color = colors["safe"] if row["better"] else colors["danger"]
            ctk.CTkLabel(
                rf, text=f"{row['delta_pct']:+.1f}% {arrow}",
                font=FONTS["body_bold"], text_color=delta_color,
            ).grid(row=0, column=3, padx=SPACING["sm"], pady=4)
