import customtkinter as ctk
from gui.theme import get_colors, FONTS, SPACING, t, load_translations, set_theme, save_config, load_config, get_theme
from core import backup


class SettingsPanel(ctk.CTkScrollableFrame):
    def __init__(self, parent, on_theme_change=None, **kwargs):
        colors = get_colors()
        super().__init__(parent, fg_color=colors["bg_primary"], corner_radius=0, **kwargs)
        self.on_theme_change = on_theme_change
        self._config = load_config()

        header = ctk.CTkLabel(
            self, text=t("nav.settings", "Pengaturan"),
            font=FONTS["heading"], text_color=colors["text_primary"], anchor="w",
        )
        header.pack(fill="x", padx=SPACING["lg"], pady=(SPACING["lg"], SPACING["md"]))

        lang_frame = ctk.CTkFrame(self, fg_color=colors["bg_card"], corner_radius=10)
        lang_frame.pack(fill="x", padx=SPACING["lg"], pady=SPACING["sm"])

        ctk.CTkLabel(
            lang_frame, text=f"🌐 {t('settings.language', 'Bahasa')}",
            font=FONTS["body_bold"], text_color=colors["text_primary"], anchor="w",
        ).pack(padx=SPACING["md"], pady=(SPACING["md"], SPACING["sm"]), anchor="w")

        self.lang_var = ctk.StringVar(value=self._config.get("language", "id"))
        lang_radio_frame = ctk.CTkFrame(lang_frame, fg_color="transparent")
        lang_radio_frame.pack(padx=SPACING["xl"], pady=(0, SPACING["md"]))

        ctk.CTkRadioButton(
            lang_radio_frame, text="🇮🇩 Indonesia", variable=self.lang_var, value="id",
            font=FONTS["body"], text_color=colors["text_primary"], fg_color=colors["accent"],
            command=self._on_lang_change,
        ).pack(side="left", padx=(0, SPACING["lg"]))

        ctk.CTkRadioButton(
            lang_radio_frame, text="🇺🇸 English", variable=self.lang_var, value="en",
            font=FONTS["body"], text_color=colors["text_primary"], fg_color=colors["accent"],
            command=self._on_lang_change,
        ).pack(side="left")

        theme_frame = ctk.CTkFrame(self, fg_color=colors["bg_card"], corner_radius=10)
        theme_frame.pack(fill="x", padx=SPACING["lg"], pady=SPACING["sm"])

        ctk.CTkLabel(
            theme_frame, text=f"🎨 {t('settings.theme', 'Tema')}",
            font=FONTS["body_bold"], text_color=colors["text_primary"], anchor="w",
        ).pack(padx=SPACING["md"], pady=(SPACING["md"], SPACING["sm"]), anchor="w")

        self.theme_var = ctk.StringVar(value=get_theme())
        theme_radio_frame = ctk.CTkFrame(theme_frame, fg_color="transparent")
        theme_radio_frame.pack(padx=SPACING["xl"], pady=(0, SPACING["md"]))

        ctk.CTkRadioButton(
            theme_radio_frame, text=f"🌙 {t('settings.theme.dark', 'Gelap')}", variable=self.theme_var, value="dark",
            font=FONTS["body"], text_color=colors["text_primary"], fg_color=colors["accent"],
            command=self._on_theme_change,
        ).pack(side="left", padx=(0, SPACING["lg"]))

        ctk.CTkRadioButton(
            theme_radio_frame, text=f"☀ {t('settings.theme.light', 'Terang')}", variable=self.theme_var, value="light",
            font=FONTS["body"], text_color=colors["text_primary"], fg_color=colors["accent"],
            command=self._on_theme_change,
        ).pack(side="left")

        backup_frame = ctk.CTkFrame(self, fg_color=colors["bg_card"], corner_radius=10)
        backup_frame.pack(fill="x", padx=SPACING["lg"], pady=SPACING["sm"])

        ctk.CTkLabel(
            backup_frame, text=f"💾 {t('settings.backup', 'Kelola Backup')}",
            font=FONTS["body_bold"], text_color=colors["text_primary"], anchor="w",
        ).pack(padx=SPACING["md"], pady=(SPACING["md"], SPACING["sm"]), anchor="w")

        self.backup_list_frame = ctk.CTkFrame(backup_frame, fg_color="transparent")
        self.backup_list_frame.pack(fill="x", padx=SPACING["md"], pady=(0, SPACING["md"]))

        self._load_backups()

    def _load_backups(self):
        for w in self.backup_list_frame.winfo_children():
            w.destroy()

        colors = get_colors()
        sessions = backup.list_sessions()
        if not sessions:
            ctk.CTkLabel(
                self.backup_list_frame, text="Belum ada backup tersimpan.",
                font=FONTS["small"], text_color=colors["text_muted"],
            ).pack(pady=SPACING["sm"])
            return

        for s in sessions[:10]:
            row = ctk.CTkFrame(self.backup_list_frame, fg_color=colors["bg_hover"], corner_radius=6)
            row.pack(fill="x", pady=2)

            ctk.CTkLabel(
                row, text=f"📋 {s['session_id']} ({s['tweak_count']} tweaks)",
                font=FONTS["small"], text_color=colors["text_secondary"], anchor="w",
            ).pack(side="left", padx=SPACING["sm"], pady=4)

            ctk.CTkButton(
                row, text="↩ Rollback", width=80, height=24,
                font=FONTS["badge"], corner_radius=6,
                fg_color=colors["warning"], text_color="#000",
                command=lambda sid=s["session_id"]: self._rollback_session(sid),
            ).pack(side="right", padx=SPACING["sm"], pady=4)

    def _rollback_session(self, session_id: str):
        from core import engine
        engine.rollback_session(session_id)
        self._load_backups()

    def _on_lang_change(self):
        lang = self.lang_var.get()
        load_translations(lang)
        self._config["language"] = lang
        save_config(self._config)

    def _on_theme_change(self):
        theme = self.theme_var.get()
        set_theme(theme)
        self._config["theme"] = theme
        save_config(self._config)
        if self.on_theme_change:
            self.on_theme_change(theme)
