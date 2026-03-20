import customtkinter as ctk
import threading
from gui.theme import get_colors, FONTS


class SplashScreen(ctk.CTk):
    def __init__(self, on_complete):
        super().__init__()
        self.on_complete = on_complete
        self.overrideredirect(True)
        
        w, h = 420, 220
        sx = (self.winfo_screenwidth() - w) // 2
        sy = (self.winfo_screenheight() - h) // 2
        self.geometry(f"{w}x{h}+{sx}+{sy}")

        colors = get_colors()
        self.configure(fg_color=colors["bg_secondary"])

        title = ctk.CTkLabel(
            self, text="⚡ GandiWin", 
            font=("Segoe UI", 28, "bold"),
            text_color=colors["accent"]
        )
        title.pack(pady=(30, 4))

        sub = ctk.CTkLabel(
            self, text="Windows Optimization Toolkit",
            font=("Segoe UI", 13),
            text_color=colors["text_secondary"]
        )
        sub.pack()

        self.status_label = ctk.CTkLabel(
            self, text="Checking system...",
            font=("Segoe UI", 12),
            text_color=colors["text_muted"]
        )
        self.status_label.pack(pady=(20, 6))

        self.progress = ctk.CTkProgressBar(
            self, width=300, height=6,
            fg_color=colors["bg_card"],
            progress_color=colors["accent"]
        )
        self.progress.pack()
        self.progress.set(0)

        self._step = 0
        self._total = 0

    def start_check(self, check_fn):
        threading.Thread(target=self._run_check, args=(check_fn,), daemon=True).start()

    def _run_check(self, check_fn):
        check_fn(self._update_progress)
        self.after(0, self._finish)

    def _update_progress(self, current, total, label=""):
        self._step = current
        self._total = total
        self.after(0, self._sync_ui, label)

    def _sync_ui(self, label):
        if self._total > 0:
            self.progress.set(self._step / self._total)
        if label:
            self.status_label.configure(text=label)

    def _finish(self):
        self.progress.set(1)
        self.status_label.configure(text="Ready!")
        self.after(300, self._launch)

    def _launch(self):
        self.destroy()
        self.on_complete()
