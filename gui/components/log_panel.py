import customtkinter as ctk
from gui.theme import get_colors, FONTS, SPACING, t


class LogPanel(ctk.CTkFrame):
    def __init__(self, parent, **kwargs):
        colors = get_colors()
        super().__init__(parent, fg_color=colors["bg_secondary"], corner_radius=8, **kwargs)
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(1, weight=1)

        header = ctk.CTkLabel(
            self, text=t("log.title", "Log Aktifitas"),
            font=FONTS["body_bold"], text_color=colors["text_primary"],
            anchor="w",
        )
        header.grid(row=0, column=0, padx=SPACING["md"], pady=(SPACING["sm"], 2), sticky="w")

        clear_btn = ctk.CTkButton(
            self, text="🗑", width=28, height=28,
            font=FONTS["small"], fg_color="transparent",
            hover_color=colors["bg_hover"],
            text_color=colors["text_muted"],
            command=self.clear,
        )
        clear_btn.grid(row=0, column=1, padx=SPACING["sm"], sticky="e")

        self.textbox = ctk.CTkTextbox(
            self, font=FONTS["mono"], height=120,
            fg_color=colors["bg_primary"],
            text_color=colors["text_secondary"],
            corner_radius=6, wrap="word",
            state="disabled",
        )
        self.textbox.grid(row=1, column=0, columnspan=2, padx=SPACING["sm"], pady=(0, SPACING["sm"]), sticky="nsew")

    def add_entry(self, text: str, level: str = "info"):
        colors = get_colors()
        color_map = {"success": colors["safe"], "error": colors["danger"], "warn": colors["warning"]}
        self.textbox.configure(state="normal")
        self.textbox.insert("end", text + "\n")
        self.textbox.configure(state="disabled")
        self.textbox.see("end")

    def clear(self):
        self.textbox.configure(state="normal")
        self.textbox.delete("1.0", "end")
        self.textbox.configure(state="disabled")
