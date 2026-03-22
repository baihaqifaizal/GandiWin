# GANDIWIN - ABOUT & PROJECT INTENT

## 1. Target OS & Minimal Requirement

- **Target utama:** Win10 32/64-bit, Win11 64-bit
- **Minimum requirement:**
  - PowerShell ≥3 (ideal ≥5)
  - ExecutionPolicy bisa bypass (`-ExecutionPolicy Bypass`)
  - Win10 versi awal → semua tweak jalan stabil
- **Tidak lagi mendukung:**
  - Win7 → terlalu terbatas, PS lawas, fitur modern tidak ada
  - Win8 → fragmented, maintenance ribet

## 2. Aplikasi Versi

- **Full PowerShell version** → semua fitur 30 tweak via `.ps1`
- **Modular:** tiap fitur ada script sendiri (`modules/feature.ps1`)
- **Logging rapi** → `logs/`
- **Multi-terminal ala hacker-style:**
  - `system_check` → hardware/software overview
  - `universal_menu` → menu interaktif 1–30 fitur
  - `log_viewer` → baca log semua fitur
  - feature execution → tiap fitur dijalankan di terminal baru

## 3. Struktur Folder

```text
WinTweak_PS/
│
├─ launcher.bat                  ← buka 4 terminal, deteksi OS + versi PS
├─ universal_menu.ps1            ← menu interaktif 1–30 fitur
├─ modules/                      ← semua fitur .ps1
│    ├─ thermal_check.ps1
│    ├─ antivirus_conflict.ps1
│    └─ ... sampai 30 fitur
└─ logs/                         ← semua log fitur & error
```

## 4. Terminal & Workflow

- **Terminal 1 → system_check**
  - Informasi hardware/software lengkap
  - Thermal, CPU, RAM, GPU, Storage, OS info
- **Terminal 2 → universal_menu**
  - Menu interaktif 1–30 fitur
  - Hacker-style terminal: warna, borders, ASCII art, loading effect
- **Terminal 3 → log_viewer**
  - Baca log sukses / error fitur
  - Refresh + scroll
- **Terminal 4 → feature execution**
  - Jalankan tiap fitur di terminal baru (`Start-Process -NoExit`)
  - Logging otomatis → `logs/feature_name.log`

## 5. 30 Fitur Full PowerShell

1. Thermal Check
2. Antivirus Conflict
3. Bloatware Removal
4. Startup Control
5. Background Services
6. Background Apps
7. Telemetry Disabler
8. Delivery Optimization
9. Scheduled Tasks
10. Disk Clean up
11. NTFS Repair
12. AppData Cleanup
13. Ghost Drivers
14. Hibernation Disable
15. Virtual Memory
16. Disable Spectre & Meltdown Mitigations
17. CPU Core Unparking
18. MSI Mode Interrupt
19. Network Throttling
20. GPU HAGS
21. Nagle Algorithm
22. Visual Effects
23. Power Plan
24. USB Selective Suspend
25. Mouse Precision
26. Shell Extensions
27. Explorer Quick Access
28. Indexing Service
29. Registry Optimization
30. Game Mode Bar

## 6. Aturan Strict / Safety

- **Eksekusi PowerShell selalu:** `Start-Process powershell -NoExit -ExecutionPolicy Bypass -File "feature.ps1"`
- **Modular tiap fitur** → mudah update / debug
- **Logging wajib** → sukses + error → `logs/*.log`
- **Menu input hanya 1–30** → invalid → warning + pause
- **Cek versi PS** sebelum pakai cmdlet modern → fallback aman
- **Terminal tetap terbuka** (`-NoExit`)
- **Hacker-style terminal** → warna, borders, ASCII, animasi scroll

## 7. Branding & UX

- **Nama GandiWin** → tech/hacker vibe
- **Menu interaktif** → numbered list 1–30 fitur
- **Tampilan ala hacker** → warna, borders, animasi loading
- **Modular** → user bisa pilih tweak, lihat log, monitoring sistem realtime
