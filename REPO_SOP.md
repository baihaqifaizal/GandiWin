Saya sedang mengembangkan fitur [SEBUTKAN NAMA FITUR, misal: 07_telemetry_disabler] untuk framework GandiWin saya.

Saya punya dokumen aturan ketat bernama ATURAN.md. Kamu WAJIB mematuhinya (PS 5.1 Strict Mode, tanpa teks merah, dll).

Berikut adalah source code mentahan dari GitHub yang saya temukan untuk fitur ini:

[PASTE KODE CORE LOGIC DARI GITHUB DI SINI, MISAL: KODE C# ATAU BATCH SCRIPTNYA]

Arsitektur GandiWin punya 5 Layer.
Layer 1, Layer 4 (UI TUI), dan Layer 5 (Main Loop) itu sifatnya STATIS (Tinggal Anda copy-paste sendiri ke setiap folder).

Jadi, Anda HANYA memikirkan Layer 2 (Data Loader) dan Layer 3 (Execution Logic) berdasarkan kode dari GitHub.

Buatkan fungsi Get-TelemetryDataList (Layer 2) yang memuat daftar item yang akan dieksekusi berdasarkan referensi GitHub tersebut. Formatnya harus array of PSCustomObject dengan properti: Name, Checked, Rec ('safe'/'unsafe'/'optional'), dan properti tambahan (misal: RegistryPath, Value).

Buatkan fungsi Invoke-TelemetryAction (Layer 3) yang menerima objek tersebut dan mengeksekusinya (misal mengubah registry/services) menggunakan blok try...catch dan -ErrorAction Stop secara senyap (SilentlyContinue). Kembalikan $true jika sukses, $false jika gagal.

Pastikan scripting aman untuk mesin lawas dan mematuhi aturan WMI/Registry di ATURAN.md
