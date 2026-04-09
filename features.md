# GandiWin Features — 12 Metode Komprehensif

## 01 Remove Bloatware

- **Masalah:** Laptop baru penuh aplikasi UWP tidak berguna, Xbox overlay, GameDVR, shell extensions yang memperlambat context menu, dan Quick Access dengan riwayat file corrupt.
- **Solusi:** Hapus UWP apps secara massal via `Get-AppxPackage -AllUsers | Remove-AppxPackage`. Matikan GameDVR via registry. Bersihkan shell extensions pihak ketiga. Reset Explorer Quick Access history.
- **Menyerap:** 03 Bloatware Removal, 26 Shell Extensions, 27 Explorer Quick Access, 30 Game Mode Bar

## 02 Disable Background Services

- **Masalah:** Windows menjalankan puluhan service di latar belakang yang memakan RAM dan CPU — DiagTrack, DoSvc (Delivery Optimization P2P), Xbox services, Print Spooler (jika tidak ada printer), dan Hibernation yang menghabiskan space SSD.
- **Solusi:** Stop dan set `Disabled` untuk service non-esensial. Matikan hibernation via `powercfg -h off`. Matikan USB Selective Suspend via registry. Disable Fast Startup.
- **Menyerap:** 05 Background Services, 08 Delivery Optimization, 14 Hibernation Disable, 24 USB Selective Suspend

## 03 Disable Background Apps

- **Masalah:** App UWP berjalan di background menerima notifikasi. Nagle Algorithm menahan paket game sebelum dikirim (latency). Network Throttling Windows membatasi throughput.
- **Solusi:** Set `GlobalUserDisabled=1` di BackgroundAccessApplications registry. Tambahkan `TcpNoDelay=1` dan `TcpAckFrequency=1` per interface. Ubah `NetworkThrottlingIndex=FFFFFFFF`. Matikan Activity History dan Advertising ID.
- **Menyerap:** 06 Background Apps, 19 Network Throttling, 21 Nagle Algorithm

## 04 Disable Task Scheduler

- **Masalah:** Windows punya scheduled tasks yang jalan tiba-tiba saat idle — Compatibility Appraiser, CEIP Consolidator, WinSAT, Maps Update — membuat HDD/SSD tiba-tiba sibuk dan CPU naik.
- **Solusi:** Disable tasks di folder: Application Experience, Customer Experience Improvement Program, Maintenance, Xbox, Shell. Aman untuk di-disable, tidak memengaruhi fungsi utama Windows.

## 05 Disable Startup Apps

- **Masalah:** Spotify, Steam, Updater Adobe, dan sejenisnya mem-bypass startup lewat Registry Run keys dan folder Startup, "mencuri" disk I/O di detik-detik login.
- **Solusi:** Enumerasi semua startup dari Registry HKCU+HKLM Run, Startup folder User+All Users. Warnai putih (aman di-disable) vs merah (essential: antivirus, driver). User pilih via checklist.
- **Menyerap:** 04 Startup Control

## 06 Portable Antivirus

- **Masalah:** Dua antivirus aktif bersamaan (misal: Avast + Defender) menyebabkan konflik file scanning yang parah, memperlambat akses file dan launch aplikasi.
- **Solusi:** Deteksi AV via WMI `SecurityCenter2`. Tampilkan daftar AV terinstall. Disable/uninstall AV konflik. Sediakan panduan portable AV: Malwarebytes Portable, ESET Online Scanner, HitmanPro (no-install).
- **Menyerap:** 02 Antivirus Conflict

## 07 Everything Search

- **Masalah:** Windows Search (`WSearch`) terus mengindeks seluruh drive, memakan disk I/O konstan. Saat copy file besar, indexing bekerja bersamaan membuat performa turun.
- **Solusi:** Stop dan disable `WSearch` service. Batasi scope indexing ke System drive saja. Berikan panduan install Everything v1.4 (Voidtools) — pengindeks alternatif yang menggunakan NTFS journal, indexing <1 detik, RAM <5MB.
- **Menyerap:** 28 Indexing Service

## 08 Apply Visual Effects

- **Masalah:** Animasi fade/slide Windows, transparansi, bayangan window menambah overhead GPU+CPU, terasa laggy di PC tanpa dedicated GPU. Mouse Pointer Precision (accel) mengganggu akurasi gaming/desain.
- **Solusi:** Set performance mode visual effect (UserPreferencesMask). Nonaktifkan animasi DWM dan transparansi. Matikan Mouse Pointer Precision (accel curve). Enable GPU HAGS (Hardware-Accelerated GPU Scheduling) untuk GPU modern. Aktifkan MSI Mode Interrupt untuk GPU/NIC.
- **Menyerap:** 18 MSI Mode Interrupt, 20 GPU HAGS, 22 Visual Effects, 25 Mouse Precision

## 09 Apply Quick CPU

- **Masalah:** Power Plan "Balanced" membatasi CPU clock saat idle-to-load transition, menyebabkan micro-stutter. Core parking menambah wake-up delay. Spectre/Meltdown patch menurunkan IPC CPU (gaming/rendering).
- **Solusi:** Aktifkan Ultimate Performance power plan. Unpark semua core CPU. Set minimum processor state 100%. Optimasi pagefile (1.5x-2x RAM). Opsional: Timer Resolution boost, HPET disable, Spectre/Meltdown mitigations off (unsafe, explicit warning).
- **Menyerap:** 15 Virtual Memory, 16 Spectre Meltdown, 17 CPU Core Unparking, 23 Power Plan

## 10 Telemetry

- **Masalah:** `DiagTrack`, `dmwappushservice`, `PcaSvc` terus menulis log dan mengirim data ke Microsoft. Hosts file tidak memblokir endpoint telemetry MS.
- **Solusi:** Disable service telemetry. Set `AllowTelemetry=0` via Group Policy registry. Matikan CEIP, Error Reporting, App Compat Telemetry. Opsional: blokir endpoint MS telemetry via hosts file. Opsional: bersihkan registry keys MRU dan riwayat shell.
- **Menyerap:** 07 Telemetry Disabler, 29 Registry Optimization

## 11 Disk

- **Masalah:** File temporary dan cache menumpuk, file system error ($MFT corrupt), ghost drivers menyebabkan PnP service kerja ekstra saat boot, WinSAT dan disk optimizer tidak pernah dijalankan manual.
- **Solusi:** Disk Cleanup (cleanmgr). Hapus temp, AppData temp, WER reports. Jadwalkan chkdsk. Jalankan Optimize-Volume (TRIM untuk SSD, defrag untuk HDD). Deteksi dan hapus ghost drivers via `pnputil`. Opsional: sfc /scannow, DISM CheckHealth.
- **Menyerap:** 10 Disk Cleanup, 11 NTFS Repair, 12 AppData Cleanup, 13 Ghost Drivers

## 12 Memory Management

- **Masalah:** Pagefile dikelola otomatis Windows (seringkali terfragmentasi, terlalu kecil). RAM penuh membuat sistem freeze karena pagefile yang lambat. Suhu CPU/GPU tidak dipantau padahal thermal throttling sudah terjadi.
- **Solusi:** Health check: tampilkan info RAM (slot, speed, jenis DDR), suhu thermal zone, status pagefile. Tweaks: optimasi pagefile (1.5x-2x RAM), disable memory compression (opsional), disable paging executive, Large System Cache.
- **Menyerap:** 01 Thermal Check, 15 Virtual Memory

## 13 Apply Custom Presets

- **Fungsi:** Master trigger yang menjalankan kombinasi modul 1-12 berurutan.
- **Preset tersedia:**
  - **Gaming PC:** Modul 1, 2, 3, 5, 8, 9 — remove bloat + disable BG + visual FX + CPU tweak
  - **Office / Work PC:** Modul 2, 3, 4, 5, 7, 10, 11 — disable BG + tasks + search + telemetry + disk
  - **Privacy First:** Modul 4, 5, 6, 10 — disable startup + ganti AV + block telemetry
  - **Full Optimization:** Semua modul 1-12 berurutan
  - **Maintenance Rutin:** Modul 4, 11, 12 — task + disk + memory check
  - **Custom:** User pilih sendiri kombinasi modul via checklist
