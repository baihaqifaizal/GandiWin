import customtkinter as ctk
from gui.theme import get_colors, FONTS, SPACING


class ProgressBar(ctk.CTkFrame):
    def __init__(self, parent, **kwargs):
        colors = get_colors()
        super().__init__(parent, fg_color=colors["bg_secondary"], corner_radius=8, **kwargs)
        self.grid_columnconfigure(0, weight=1)

        self.label = ctk.CTkLabel(
            self, text="", font=FONTS["small"],
            text_color=colors["text_secondary"], anchor="w",
        )
        self.label.grid(row=0, column=0, padx=SPACING["md"], pady=(SPACING["sm"], 2), sticky="w")

        self.progress = ctk.CTkProgressBar(
            self, width=400, height=8, corner_radius=4,
            fg_color=colors["bg_hover"],
            progress_color=colors["accent"],
        )
        self.progress.grid(row=1, column=0, padx=SPACING["md"], pady=(0, SPACING["sm"]), sticky="ew")
        self.progress.set(0)

        self.pct_label = ctk.CTkLabel(
            self, text="0%", font=FONTS["small"],
            text_color=colors["text_muted"],
        )
        self.pct_label.grid(row=1, column=1, padx=(0, SPACING["md"]), pady=(0, SPACING["sm"]))

    def update_progress(self, value: float, text: str = ""):
        self.progress.set(value)
        self.pct_label.configure(text=f"{int(value * 100)}%")
        if text:
            self.label.configure(text=text)
        self.update_idletasks()

    def reset(self):
        self.progress.set(0)
        self.pct_label.configure(text="0%")
        self.label.configure(text="")
