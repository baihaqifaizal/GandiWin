import customtkinter as ctk
import threading
from gui.theme import get_colors, FONTS, SPACING, t
from data.uwp_apps import UWP_APPS
from core import engine

class AppRemovalPanel(ctk.CTkFrame):
    def __init__(self, parent, log_panel=None, precheck_results=None, **kwargs):
        self.colors = get_colors()
        super().__init__(parent, fg_color=self.colors["bg_primary"], corner_radius=0, **kwargs)
        self.log_panel = log_panel
        self.precheck_results = precheck_results or {}
        self.apps = sorted(UWP_APPS, key=lambda x: x["name"].lower())

        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(3, weight=1) # Scrollable list gets the weight

        self.installed_apps_cache = self.precheck_results.get("installed_apps", set())
        self.is_fetched = True # Always True since we pre-check now

        # -- ROW 0: Header Titles --
        header_frame = ctk.CTkFrame(self, fg_color="transparent")
        header_frame.grid(row=0, column=0, sticky="ew", padx=SPACING["xl"], pady=(SPACING["lg"], 0))
        
        ctk.CTkLabel(
            header_frame, text="Hapus Aplikasi",
            font=FONTS["title"], text_color=self.colors["text_primary"],
            anchor="w",
        ).pack(side="top", fill="x")
        
        ctk.CTkLabel(
            header_frame, text="Pilih aplikasi yang ingin Anda hapus dari sistem",
            font=FONTS["body"], text_color=self.colors["text_secondary"],
            anchor="w",
        ).pack(side="top", fill="x", pady=(2, 0))

        # -- ROW 1: Toolbar --
        toolbar = ctk.CTkFrame(self, fg_color="transparent")
        toolbar.grid(row=1, column=0, sticky="ew", padx=SPACING["xl"], pady=(SPACING["lg"], SPACING["md"]))
        
        self.btn_select_all = ctk.CTkButton(
            toolbar, text="Pilih Semua", 
            font=FONTS["body"], fg_color=self.colors["bg_hover"], hover_color=self.colors["border"],
            text_color=self.colors["text_primary"], width=120, height=32, command=self._on_select_all
        )
        self.btn_select_all.pack(side="left", padx=(0, SPACING["sm"]))

        self.btn_clear = ctk.CTkButton(
            toolbar, text="Batalkan Pilihan", 
            font=FONTS["body"], fg_color=self.colors["bg_hover"], hover_color=self.colors["border"],
            text_color=self.colors["text_primary"], width=120, height=32, command=self._on_clear
        )
        self.btn_clear.pack(side="left")

        self.search_var = ctk.StringVar()
        self.search_var.trace_add("write", self._on_search)
        self.search_entry = ctk.CTkEntry(
            toolbar, placeholder_text="🔍 Cari aplikasi...", font=FONTS["body"],
            width=250, height=32, border_width=1, border_color=self.colors["border"],
            fg_color=self.colors["bg_secondary"], textvariable=self.search_var
        )
        self.search_entry.pack(side="right")

        # Column weights defining the alignment
        self.col_weights = {"chk": 0, "name": 3, "desc": 5, "id": 4}

        # -- ROW 2: Table Header --
        tbl_header = ctk.CTkFrame(self, fg_color="transparent")
        tbl_header.grid(row=2, column=0, sticky="ew", padx=SPACING["xl"] + 4, pady=(0, 4)) # +4 to align with scrollbar padding
        
        # Keep same layout structure as rows
        tbl_header.grid_columnconfigure(0, weight=0, minsize=40)
        tbl_header.grid_columnconfigure(1, weight=self.col_weights["name"], uniform="col")
        tbl_header.grid_columnconfigure(2, weight=self.col_weights["desc"], uniform="col")
        tbl_header.grid_columnconfigure(3, weight=self.col_weights["id"], uniform="col")

        ctk.CTkLabel(tbl_header, text="", width=30).grid(row=0, column=0, padx=SPACING["sm"]) # Space for checkbox
        ctk.CTkLabel(tbl_header, text="Nama", font=FONTS["body_bold"], text_color=self.colors["text_primary"], anchor="w").grid(row=0, column=1, sticky="w", padx=SPACING["sm"])
        ctk.CTkLabel(tbl_header, text="Deskripsi", font=FONTS["body_bold"], text_color=self.colors["text_primary"], anchor="w").grid(row=0, column=2, sticky="w", padx=SPACING["sm"])
        ctk.CTkLabel(tbl_header, text="App ID", font=FONTS["body_bold"], text_color=self.colors["text_primary"], anchor="w").grid(row=0, column=3, sticky="w", padx=SPACING["sm"])

        # -- ROW 3: Scrollable List --
        self.scroll_frame = ctk.CTkScrollableFrame(
            self, fg_color="transparent", corner_radius=0, 
            scrollbar_button_color=self.colors["scrollbar"],
            scrollbar_button_hover_color=self.colors["text_secondary"]
        )
        self.scroll_frame.grid(row=3, column=0, sticky="nsew", padx=SPACING["xl"], pady=(0, 0))
        self.scroll_frame.grid_columnconfigure(0, weight=1)

        self.app_vars = {}
        self.app_widgets = {} # Track widgets for disabling
        self.row_frames = []
        self._populate_list()

        # -- ROW 4: Bottom Bar --
        bottom_bar = ctk.CTkFrame(self, fg_color=self.colors["bg_secondary"], height=60, corner_radius=0)
        bottom_bar.grid(row=4, column=0, sticky="ew")
        bottom_bar.pack_propagate(False)

        self.lbl_selected_count = ctk.CTkLabel(
            bottom_bar, text="0 app(s) selected for removal", 
            font=FONTS["body"], text_color=self.colors["text_primary"]
        )
        self.lbl_selected_count.pack(side="left", padx=SPACING["xl"])

        self.btn_execute = ctk.CTkButton(
            bottom_bar, text="Memuat Data...",
            font=FONTS["body_bold"], fg_color=self.colors["danger"], hover_color="#c83232",
            height=36, width=150, command=self._on_execute, state="normal"
        )
        self.btn_execute.pack(side="right", padx=SPACING["xl"])
        self.btn_execute.configure(text="Terapkan Perubahan")

        # Update initial count
        self._update_count()
        self._apply_installed_state()

    def _apply_installed_state(self):
        for app in self.apps:
            is_installed = False
            app_id_lower = app["id"].lower()
            if any(app_id_lower in p for p in self.installed_apps_cache):
                is_installed = True
                
            # Checked (1) = To be Removed, Unchecked (0) = Keep
            # If NOT installed (missing), it is effectively REMOVED, so it should be CHECKED (1) and DISABLED.
            target_val = 0 if is_installed else 1
            if app["id"] in self.app_vars:
                var = self.app_vars[app["id"]]
                var.set(target_val)
                
                # Update UI state if widgets exist
                if app["id"] in self.app_widgets:
                    widgets = self.app_widgets[app["id"]]
                    state = "normal" if is_installed else "disabled"
                    text_color = self.colors["text_primary"] if is_installed else "grey"
                    
                    widgets["chk"].configure(
                        state=state,
                        fg_color=self.colors["accent"] if is_installed else self.colors["text_muted"],
                        border_color=self.colors["accent"] if is_installed else self.colors["text_muted"]
                    )
                    widgets["name"].configure(text_color=text_color)
                    widgets["desc"].configure(text_color=text_color)

    def _populate_list(self, filter_text=""):
        # Clear existing
        for frame in self.row_frames:
            frame.destroy()
        self.row_frames.clear()
        self.app_widgets.clear()

        filter_lower = filter_text.lower()
        
        row_idx = 0
        for app in self.apps:
            app_desc = app.get("desc", app.get("description", ""))
            if filter_lower and filter_lower not in app["name"].lower() and filter_lower not in app_desc.lower() and filter_lower not in app["id"].lower():
                continue

            # Check if var exists, else create
            if app["id"] not in self.app_vars:
                var = ctk.IntVar(value=0)
                var.trace_add("write", self._update_count)
                self.app_vars[app["id"]] = var
            else:
                var = self.app_vars[app["id"]]

            row = ctk.CTkFrame(self.scroll_frame, fg_color="transparent", corner_radius=4)
            row.grid(row=row_idx, column=0, sticky="ew", pady=1)
            row_idx += 1
            
            row.grid_columnconfigure(0, weight=0, minsize=40)
            row.grid_columnconfigure(1, weight=self.col_weights["name"], uniform="col")
            row.grid_columnconfigure(2, weight=self.col_weights["desc"], uniform="col")
            row.grid_columnconfigure(3, weight=self.col_weights["id"], uniform="col")
            
            self.row_frames.append(row)

            # Hover effect binding
            def on_enter(e, r=row, a_id=app["id"]): 
                # Only hover if not disabled (missing)
                if any(a_id.lower() in p for p in self.installed_apps_cache):
                    r.configure(fg_color=self.colors["bg_hover"])
            def on_leave(e, r=row): r.configure(fg_color="transparent")
            row.bind("<Enter>", on_enter)
            row.bind("<Leave>", on_leave)

            chk = ctk.CTkCheckBox(row, text="", variable=var, width=30, border_width=1, corner_radius=4)
            chk.grid(row=0, column=0, padx=SPACING["sm"], pady=4)

            lbl_name = ctk.CTkLabel(row, text=app["name"], font=FONTS["body"], text_color=self.colors["text_primary"], anchor="w")
            lbl_name.grid(row=0, column=1, sticky="w", padx=SPACING["sm"])
            
            lbl_desc = ctk.CTkLabel(row, text=app_desc, font=FONTS["body"], text_color=self.colors["text_primary"], anchor="w")
            lbl_desc.grid(row=0, column=2, sticky="w", padx=SPACING["sm"])
            
            lbl_id = ctk.CTkLabel(row, text=app["id"], font=FONTS["body"], text_color=self.colors["text_secondary"], anchor="w")
            lbl_id.grid(row=0, column=3, sticky="w", padx=SPACING["sm"])

            self.app_widgets[app["id"]] = {
                "chk": chk,
                "name": lbl_name,
                "desc": lbl_desc,
                "id": lbl_id
            }

            # Clicking the row toggles the checkbox (only if installed)
            def toggle_row(e, v=var, a_id=app["id"]):
                if any(a_id.lower() in p for p in self.installed_apps_cache):
                    v.set(0 if v.get() else 1)

            for w in [row, lbl_name, lbl_desc, lbl_id]:
                w.bind("<Button-1>", toggle_row)

    def _update_count(self, *args):
        count = sum(var.get() for var in self.app_vars.values())
        self.lbl_selected_count.configure(text=f"{count} aplikasi ditandai sebagai dihapus")

    def _on_select_all(self):
        # Only select visible ones based on search? Or all? Usually select all means select visible.
        filter_text = self.search_var.get().lower()
        for app in self.apps:
            app_desc = app.get("desc", app.get("description", ""))
            if filter_text and filter_text not in app["name"].lower() and filter_text not in app_desc.lower() and filter_text not in app["id"].lower():
                continue
            self.app_vars[app["id"]].set(1)

    def _on_clear(self):
        for var in self.app_vars.values():
            var.set(0)

    def _on_search(self, *args):
        # Debounce/throttle would be better, but local filter is fast enough.
        self._populate_list(self.search_var.get())

    def _on_execute(self):
        if not self.is_fetched:
            return

        apps_to_remove = []
        apps_to_install = []

        for app_id, var in self.app_vars.items():
            wanted_removed = (var.get() == 1)
            app_id_lower = app_id.lower()
            is_installed = any(app_id_lower in p for p in self.installed_apps_cache)
            
            if wanted_removed and is_installed:
                apps_to_remove.append(app_id)
            elif not wanted_removed and not is_installed:
                apps_to_install.append(app_id)

        if not apps_to_remove and not apps_to_install:
            if self.log_panel:
                self.log_panel.add_entry("⚠ Tidak ada perubahan status aplikasi yang terdeteksi.")
            return

        self.btn_execute.configure(state="disabled", text="Memproses...")
        threading.Thread(target=self._run_changes, args=(apps_to_remove, apps_to_install), daemon=True).start()

    def _run_changes(self, apps_to_remove: list, apps_to_install: list):
        if apps_to_remove:
            tweak_rm = {
                "id": "remove_selected_uwp",
                "name": f"Hapus {len(apps_to_remove)} Aplikasi",
                "type": "appx",
                "actions": [{"package": pkg_id} for pkg_id in apps_to_remove],
                "rollback": False,
                "risk": "safe",
                "description": ""
            }
            res_rm = engine.apply_tweak(tweak_rm)
            if self.log_panel:
                icon = "✓" if res_rm.success else "✗"
                self.log_panel.add_entry(f"{icon} Hapus Appx: {res_rm.message}")

        if apps_to_install:
            tweak_in = {
                "id": "install_selected_uwp",
                "name": f"Install {len(apps_to_install)} Aplikasi",
                "type": "appx",
                "actions": [{"package": pkg_id, "install": True} for pkg_id in apps_to_install],
                "rollback": False,
                "risk": "safe",
                "description": ""
            }
            res_in = engine.apply_tweak(tweak_in)
            if self.log_panel:
                icon = "✓" if res_in.success else "✗"
                self.log_panel.add_entry(f"{icon} Install Appx: {res_in.message}")
            
        # Refetch state
        from core import executor
        r = executor._run_process("Get-AppxPackage | Select-Object -ExpandProperty Name", "powershell")
        if r.success and r.message:
            self.installed_apps_cache = set(r.message.lower().split("\n"))
            self.after(0, self._apply_installed_state)
        
        self.after(0, lambda: self.btn_execute.configure(state="normal", text="Terapkan Perubahan"))
