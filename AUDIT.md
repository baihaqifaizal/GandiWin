# 🛡️ GANDIWIN v3.0 — POWERSHELL 5.1 AUDIT CHECKLIST

> **Status:** Production-Ready
> **Fungsi:** Daftar periksa (checklist) wajib untuk memvalidasi setiap skrip fitur (01-30) sebelum di-deploy ke flashdisk lapangan. Jika ada SATU saja item yang tidak dicentang, skrip DITOLAK.

---

## 1. 🔍 AUDIT SINTAKS & OPERATOR (ANTI-PS7)

_Pastikan tidak ada sintaks PowerShell Core (PS 6/7) yang menyusup ke dalam kode._

- [ ] **TIDAK ADA Ternary Operator:** Tidak ada penggunaan `$x ? 'a' : 'b'`. Harus menggunakan `if ($x) { 'a' } else { 'b' }`.
- [ ] **TIDAK ADA Pipeline Chain:** Tidak ada penggunaan `&&` atau `||` antar perintah. Harus ditangkap dengan variabel hasil atau blok `try...catch`.
- [ ] **TIDAK ADA Null-Coalescing:** Tidak ada penggunaan `??` atau `??=`. Pengecekan null harus eksplisit: `if ($null -ne $var)` atau `if ($var)`.
- [ ] **TIDAK ADA Parallel Processing Asli:** Tidak menggunakan `ForEach-Object -Parallel`. Semua loop menggunakan `foreach ($item in $collection)` atau `ForEach-Object` standar.
- [ ] **TIDAK ADA `$_ -strip`:** Pengecekan string kosong/spasi murni menggunakan `if ([string]::IsNullOrWhiteSpace($_))` atau `if ($_ -match '\S')`.

## 2. ⚙️ AUDIT INTERAKSI SISTEM & OFFLINE MODE

_PowerShell 5.1 punya cara khusus berinteraksi dengan OS secara native._

- [ ] **Path Absolut Dinamis:** Tidak ada _hardcoded path_ seperti `C:\GandiWin`. Direktori aktif HANYA di-resolve menggunakan `$PSScriptRoot` (atau fallback `$MyInvocation.MyCommand.Definition`).
- [ ] **Manipulasi Registry Aman:** Pembuatan/perubahan _key_ menggunakan `Get-ItemProperty`, `New-Item`, `Set-ItemProperty`, atau `Remove-ItemProperty`. (Jangan gunakan alias `md` atau `rm` untuk registry).
- [ ] **CIM vs WMI:** Di PS 5.1, `Get-CimInstance` sudah didukung, namun jika menyasar mesin yang _environment_ WMF 5.1-nya mungkin korup, menggunakan `Get-WmiObject` jauh lebih _bulletproof_. Pastikan seragam.
- [ ] **Eksekusi Aplikasi Eksternal:** Memanggil .exe selalu menggunakan `Start-Process -FilePath "..." -ArgumentList "..." -Wait -PassThru` agar _ExitCode_ bisa ditangkap.
- [ ] **Tanpa Koneksi Internet:** Dilarang keras menggunakan `Invoke-WebRequest`, `Install-Module`, atau `Find-Package`.

## 3. 🛡️ AUDIT ERROR HANDLING (DEFENSIVE SCRIPTING)

_Skrip tidak boleh memunculkan error merah di depan klien atau berhenti mendadak._

- [ ] **Per-Command Error Action:** Setiap operasi sistem (_Registry, WMI, Services, Files_) **WAJIB** diakhiri dengan parameter `-ErrorAction Stop` (atau `SilentlyContinue` jika di dalam fungsi UI).
- [ ] **Dilarang Global Error Preference:** TIDAK ADA deklarasi `$ErrorActionPreference = "Stop"` di awal skrip (bisa merusak _flow_ keseluruhan jika ada error minor).
- [ ] **Wajib Try-Catch:** Operasi berisiko selalu berada di dalam `try { ... } catch { ... }`.
- [ ] **No Red Text:** Di dalam `catch`, DILARANG menggunakan `Write-Error`. Tangkap dengan `$_.Exception.Message`, log secara senyap, dan gunakan `Write-Host "..." -ForegroundColor Yellow`.
- [ ] **Graceful Degradation:** Terdapat instruksi `continue` atau `return $false` di dalam blok `catch` agar perulangan tidak mati.

## 4. 🏗️ AUDIT ARSITEKTUR GANDIWIN (5 LAYER)

_Struktur wajib sesuai dokumen `ATURAN.md`._

- [ ] **Layer 1 (Init):** Terdapat pengecekan `$MinPSVersion = [Version]"5.1"`, import modul UI `GandiWinUI.psm1`, dan deklarasi `$LogFile`.
- [ ] **Layer 2 (Data):** Terdapat fungsi `Get-<Nama>List` yang me-return `PSCustomObject` berisi properti baku: `Name`, `Checked`, `Rec`.
- [ ] **Layer 3 (Logic):** Terdapat fungsi eksekusi (misal: `Invoke-Tweak`) yang mengembalikan `$true` atau `$false` dan tidak mencampur _logic_ dengan UI.
- [ ] **Layer 4 (UI TUI):** Menggunakan fungsi `Invoke-ChecklistUI` persis seperti template tanpa ada modifikasi pada mekanisme _SetCursorPosition_ atau pembacaan tombol panah.
- [ ] **Layer 5 (Main Loop):** Menggunakan perulangan `while ($true)` dengan _header_ `Show-GandiHeader`. Penutupan menggunakan `exit` setelah `Start-Sleep`, DILARANG menggunakan `Close-Host`.
- [ ] **Central Logging:** Menggunakan `Write-ActivityLog` di setiap titik mulai, sukses, dan gagal. Tidak menggunakan nama fungsi terlarang seperti `Log-Activity`.

## 5. 🛠️ C# P/INVOKE AUDIT (KHUSUS WIN API)

_Jika menggunakan Add-Type untuk mengakses user32.dll / kernel32.dll._

- [ ] Sintaks C# yang di-embed kompatibel dengan **.NET 4.5.2**. (Jangan panggil method dari .NET Core/5+).
- [ ] Dideklarasikan di awal skrip (di luar perulangan/loop) agar kompilasi `csc.exe` di memori hanya terjadi satu kali.
