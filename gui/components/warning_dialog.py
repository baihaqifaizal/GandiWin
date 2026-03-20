import customtkinter as ctk
from gui.theme import get_colors, FONTS, SPACING, t


class WarningDialog(ctk.CTkToplevel):
    def __init__(self, parent, tweak: dict, on_confirm=None, **kwargs):
        super().__init__(parent, **kwargs)
        self.result = False
        self.on_confirm = on_confirm
        colors = get_colors()
        risk = tweak.get("risk", "warning")
        is_danger = risk == "danger"

        self.title(t("dialog.danger_title", "Peringatan") if is_danger else t("dialog.confirm", "Konfirmasi"))
        self.geometry("520x420" if is_danger else "460x320")
        self.resizable(False, False)
        self.configure(fg_color=colors["bg_primary"])
        self.transient(parent)
        self.grab_set()

        self.grid_columnconfigure(0, weight=1)

        icon_text = "⚠" if risk == "warning" else "🔴"
        icon = ctk.CTkLabel(self, text=icon_text, font=("Segoe UI", 36), text_color=colors[risk])
        icon.grid(row=0, column=0, pady=(SPACING["xl"], SPACING["sm"]))

        title = ctk.CTkLabel(
            self, text=tweak["name"],
            font=FONTS["heading"], text_color=colors["text_primary"],
        )
        title.grid(row=1, column=0, padx=SPACING["xl"])

        detail_text = tweak.get("detail", tweak["description"])
        detail = ctk.CTkLabel(
            self, text=detail_text,
            font=FONTS["small"], text_color=colors["text_secondary"],
            wraplength=440, justify="left",
        )
        detail.grid(row=2, column=0, padx=SPACING["xl"], pady=SPACING["md"], sticky="w")

        self.checkbox_var = ctk.BooleanVar(value=False)
        if is_danger:
            checkbox = ctk.CTkCheckBox(
                self, text=t("dialog.danger_checkbox", "Saya mengerti risikonya"),
                font=FONTS["body"], text_color=colors["text_primary"],
                variable=self.checkbox_var,
                command=self._on_checkbox,
                fg_color=colors["danger"],
            )
            checkbox.grid(row=3, column=0, padx=SPACING["xl"], pady=SPACING["sm"], sticky="w")

        btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        btn_frame.grid(row=4, column=0, pady=SPACING["xl"])

        cancel_btn = ctk.CTkButton(
            btn_frame, text=t("dialog.cancel", "Batal"), width=120, height=36,
            font=FONTS["body"], corner_radius=8,
            fg_color=colors["bg_hover"], hover_color=colors["border"],
            text_color=colors["text_secondary"],
            command=self._cancel,
        )
        cancel_btn.pack(side="left", padx=SPACING["sm"])

        self.confirm_btn = ctk.CTkButton(
            btn_frame, text=t("dialog.proceed", "Lanjutkan"), width=120, height=36,
            font=FONTS["body_bold"], corner_radius=8,
            fg_color=colors["danger"] if is_danger else colors["warning"],
            hover_color=colors["danger"] if is_danger else colors["warning"],
            command=self._confirm,
        )
        self.confirm_btn.pack(side="left", padx=SPACING["sm"])

        if is_danger:
            self.confirm_btn.configure(state="disabled")
            self._cooldown_remaining = 5
            self._cooldown_label = ctk.CTkLabel(
                self, text=f"Tunggu {self._cooldown_remaining} detik...",
                font=FONTS["small"], text_color=colors["text_muted"],
            )
            self._cooldown_label.grid(row=5, column=0, pady=(0, SPACING["sm"]))
            self._tick_cooldown()

    def _tick_cooldown(self):
        if self._cooldown_remaining > 0:
            self._cooldown_remaining -= 1
            self._cooldown_label.configure(text=f"Tunggu {self._cooldown_remaining} detik...")
            self.after(1000, self._tick_cooldown)
        else:
            self._cooldown_label.configure(text="")
            if self.checkbox_var.get():
                self.confirm_btn.configure(state="normal")

    def _on_checkbox(self):
        if self.checkbox_var.get() and self._cooldown_remaining <= 0:
            self.confirm_btn.configure(state="normal")
        else:
            self.confirm_btn.configure(state="disabled")

    def _confirm(self):
        self.result = True
        if self.on_confirm:
            self.on_confirm()
        self.destroy()

    def _cancel(self):
        self.result = False
        self.destroy()
