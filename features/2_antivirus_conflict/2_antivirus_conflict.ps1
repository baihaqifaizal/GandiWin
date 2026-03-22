# WAJIB ada di setiap script utama
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) {
    Write-Host "[ERROR] PowerShell 5.1+ required!" -ForegroundColor Red
    pause; exit 1
}

# Resolve script directory robustly (works even when called via Start-Process)
if ($PSScriptRoot -ne '') {
    $ScriptDir = $PSScriptRoot
}
else {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
}

$UIModule = "$ScriptDir\..\..\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

$LogFile = "$ScriptDir\..\..\logs\menu.log"
$WDRDir = "$ScriptDir\windows-defender-remover"
$PowerRun = "$WDRDir\PowerRun.exe"
$ScriptBat = "$WDRDir\Script_Run.bat"
$FilesBat = "$WDRDir\files_removal.bat"
$SecApp = "$WDRDir\RemoveSecHealthApp.ps1"
$DefReg = "$WDRDir\Remove_Defender"
$SecReg = "$WDRDir\Remove_SecurityComp"

function Write-ActivityLog {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMsg = "[$Timestamp] [$Level] [2_AV_CONFLICT] $Message"
    try { Add-Content -Path $LogFile -Value $LogMsg -ErrorAction SilentlyContinue } catch {}
}

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-DefenderAction {
    param([string]$Label, [string]$Arg, [bool]$WithReboot = $false)

    if (-not (Test-Path $PowerRun)) {
        Write-GandiStatus -Status "FAIL" -Message "PowerRun.exe tidak ditemukan di: $WDRDir"
        Read-Host "  Tekan ENTER" | Out-Null
        return
    }

    Write-Host ""
    if ($WithReboot) {
        Write-Host "  !! PERINGATAN KRITIS: Sistem akan REBOOT OTOMATIS 10 detik setelah selesai !!" -ForegroundColor Red
    }
    Write-Host "  !! TINDAKAN INI TIDAK DAPAT DIBATALKAN (backup/restore point dianjurkan) !!" -ForegroundColor Red
    Write-Host ""
    $Confirm = Read-Host "  Ketik YES untuk lanjutkan, atau tekan ENTER untuk batal"
    if ($Confirm -ne 'YES') {
        Write-GandiStatus -Status "INFO" -Message "Dibatalkan oleh user."
        Start-Sleep -Seconds 1
        return
    }

    Write-ActivityLog "EXECUTING: $Label (arg=$Arg)" "WARN"
    Write-GandiStatus -Status "WAIT" -Message "Menjalankan: $Label ..."

    # Call Script_Run.bat with argument - needs cmd /c to pass arg correctly
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd.exe"
    $psi.Arguments = "/c `"$ScriptBat`" $Arg"
    $psi.WorkingDirectory = $WDRDir
    $psi.Verb = "runas"
    $psi.UseShellExecute = $true

    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        if (-not $WithReboot) { $p.WaitForExit() }
        Write-ActivityLog "COMPLETED: $Label" "OK"
    }
    catch {
        Write-GandiStatus -Status "FAIL" -Message "Gagal menjalankan proses: $($_.Exception.Message)"
        Write-ActivityLog "FAILED: $Label - $($_.Exception.Message)" "FAIL"
    }
}

function Invoke-RemoveFiles {
    if (-not (Test-Path $PowerRun) -or -not (Test-Path $FilesBat)) {
        Write-GandiStatus -Status "FAIL" -Message "PowerRun.exe atau files_removal.bat tidak ditemukan!"
        Read-Host "  Tekan ENTER" | Out-Null
        return
    }
    Write-Host ""
    Write-Host "  !! Ini akan menghapus folder Windows Defender dari disk secara permanen !!" -ForegroundColor Red
    Write-Host ""
    $Confirm = Read-Host "  Ketik YES untuk lanjutkan, atau tekan ENTER untuk batal"
    if ($Confirm -ne 'YES') {
        Write-GandiStatus -Status "INFO" -Message "Dibatalkan oleh user."
        Start-Sleep -Seconds 1
        return
    }
    Write-ActivityLog "EXECUTING: Remove Defender leftover files" "WARN"
    Write-GandiStatus -Status "WAIT" -Message "Menghapus sisa file Defender via PowerRun..."
    # PowerRun elevates to SYSTEM, required by files_removal.bat for takeown
    Start-Process -FilePath $PowerRun -ArgumentList "cmd.exe /k `"$FilesBat`"" -WorkingDirectory $WDRDir -Wait -ErrorAction SilentlyContinue
    Write-ActivityLog "COMPLETED: Defender file removal" "OK"
    Read-Host "  [ ? ] Tekan ENTER untuk melanjutkan" | Out-Null
}

function Invoke-RemoveSecHealthApp {
    if (-not (Test-Path $SecApp)) {
        Write-GandiStatus -Status "FAIL" -Message "RemoveSecHealthApp.ps1 tidak ditemukan!"
        Read-Host "  Tekan ENTER" | Out-Null
        return
    }
    Write-Host ""
    Write-Host "  !! Ini akan menghapus Windows Security UWP App (SecHealthUI) !!" -ForegroundColor Yellow
    $Confirm = Read-Host "  Ketik YES untuk lanjutkan, atau tekan ENTER untuk batal"
    if ($Confirm -ne 'YES') {
        Write-GandiStatus -Status "INFO" -Message "Dibatalkan oleh user."
        Start-Sleep -Seconds 1
        return
    }
    Write-ActivityLog "EXECUTING: RemoveSecHealthApp.ps1" "WARN"
    Write-GandiStatus -Status "WAIT" -Message "Menghapus SecHealthUI UWP App..."
    Start-Process -FilePath $PowerRun -ArgumentList "powershell.exe -noprofile -executionpolicy bypass -file `"$SecApp`"" -WorkingDirectory $WDRDir -Wait -ErrorAction SilentlyContinue
    Write-ActivityLog "COMPLETED: SecHealthUI removed" "OK"
    Read-Host "  [ ? ] Tekan ENTER untuk melanjutkan" | Out-Null
}

# =============================================================================
# MAIN LOOP
# =============================================================================
while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: ANTIVIRUS CONFLICT DETECTOR"
    Show-GandiHeader -Title "02 ANTIVIRUS CONFLICT DETECTOR"

    Write-ActivityLog "Launched AV Conflict Scan"

    # Admin check
    $isAdmin = Test-IsAdmin
    $adminStr = if ($isAdmin) { "YES (OK)" } else { "NO - beberapa fitur butuh Run As Admin" }
    $adminCol = if ($isAdmin) { "Green" } else { "Red" }
    Show-GandiKeyValue -Key "Administrator Privileges" -Value $adminStr -ValueColor $adminCol
    Write-Host ""

    # -------------------------------------------------------------------------
    # Check AntiVirusProduct WMI
    # -------------------------------------------------------------------------
    Write-GandiStatus -Status "WAIT" -Message "Querying Windows Security Center (SecurityCenter2)..."
    $avList = @()
    try {
        $avs = Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntiVirusProduct -ErrorAction Stop
        if ($avs) {
            foreach ($av in $avs) {
                $isEnabled = if ([int]$av.productState -band 0x1000) { "Yes" } else { "No" }
                $avList += [PSCustomObject]@{ Name = $av.displayName; Enabled = $isEnabled }
            }
        }
    }
    catch {
        Write-GandiStatus -Status "WARN" -Message "SecurityCenter2 unavailable or access denied."
    }

    # -------------------------------------------------------------------------
    # Check Defender status
    # -------------------------------------------------------------------------
    Write-GandiStatus -Status "WAIT" -Message "Querying Windows Defender Real-Time Protection..."
    $defStatus = $null
    try { $defStatus = Get-MpComputerStatus -ErrorAction Stop } catch {}

    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host "  [ DIAGNOSTIC RESULTS ]" -ForegroundColor Yellow

    $avCount = $avList.Count
    $enabledAVs = $avList | Where-Object { $_.Enabled -eq "Yes" }
    $enabledCount = @($enabledAVs).Count

    Show-GandiKeyValue -Key "Registered Antivirus" -Value $avCount -ValueColor "White"
    foreach ($a in $avList) {
        $c = if ($a.Enabled -eq "Yes") { "Green" } else { "DarkGray" }
        Write-Host "    $([char]0x2514)$([char]0x2500) $($a.Name) [Enabled: $($a.Enabled)]" -ForegroundColor $c
    }

    Write-Host ""
    $defRealtime = if ($null -ne $defStatus) { $defStatus.RealTimeProtectionEnabled } else { $false }
    $defStr = if ($defRealtime) { "Active" } else { "Disabled" }
    $defCol = if ($defRealtime) { "Green" } else { "DarkGray" }
    Show-GandiKeyValue -Key "Defender RealTime Protection" -Value $defStr -ValueColor $defCol

    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan

    # -------------------------------------------------------------------------
    # Dynamic Recommendations
    # -------------------------------------------------------------------------
    if ($enabledCount -gt 1) {
        Write-Host "  [ KESIMPULAN ] KONFLIK AKTIF TERDETEKSI" -ForegroundColor Red
        Write-Host "  Masalah: >1 Antivirus real-time aktif - saling sabet-sabetan file." -ForegroundColor White
        Write-Host "  Solusi : Uninstall salah satu AV, atau gunakan [5] / [6] di bawah." -ForegroundColor Cyan
        Write-ActivityLog "DETECTED FATAL CONFLICT: Multiple Active AVs ($enabledCount)" "FAIL"
    }
    elseif ($avCount -gt 1 -and $defRealtime) {
        Write-Host "  [ KESIMPULAN ] POTENSI KONFLIK" -ForegroundColor Yellow
        Write-Host "  Masalah: Jejak AV lama masih tercatat, Defender tetap aktif." -ForegroundColor White
        Write-Host "  Solusi : Gunakan removal tool resmi AV lama, atau [5] untuk hapus Defender." -ForegroundColor Cyan
        Write-ActivityLog "DETECTED POTENTIAL CONFLICT: Ghost AVs + Defender active" "WARN"
    }
    elseif ($avCount -eq 0) {
        Write-Host "  [ KESIMPULAN ] TIDAK ADA AV TERDAFTAR" -ForegroundColor Yellow
        Write-Host "  Masalah: Tidak ada satupun AV terdaftar di Security Center." -ForegroundColor White
        Write-Host "  Solusi : Aktifkan Defender atau install third-party AV." -ForegroundColor Cyan
        Write-ActivityLog "No AV registered on system." "WARN"
    }
    else {
        Write-Host "  [ KESIMPULAN ] SISTEM AMAN" -ForegroundColor Green
        Write-Host "  Status : $avCount AV terdaftar, $enabledCount aktif. Tidak ada konflik." -ForegroundColor White
        Write-ActivityLog "No AV Conflict detected." "OK"
    }

    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  [ STANDARD ACTIONS ]" -ForegroundColor DarkGray
    Write-Host "  [1] Tampilkan Status Lengkap Defender (MpComputerStatus)" -ForegroundColor White
    Write-Host "  [2] Buka Windows Security Dashboard" -ForegroundColor White
    Write-Host "  [3] RESCAN" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [ WINDOWS DEFENDER REMOVER - TIDAK REVERSIBEL ]" -ForegroundColor Red
    Write-Host "  [5] Hapus Defender ANTIVIRUS saja  (Security App tetap, no reboot)" -ForegroundColor DarkRed
    Write-Host "  [6] Hapus Defender PENUH + Security App  (reboot otomatis 10 detik)" -ForegroundColor DarkRed
    Write-Host "  [7] Hapus sisa FILE Defender dari disk  (jalankan setelah [5] atau [6])" -ForegroundColor DarkRed
    Write-Host "  [8] Hapus Windows Security UWP App (SecHealthUI) saja" -ForegroundColor DarkRed
    Write-Host ""
    Write-Host "  [9] KEMBALI KE MENU" -ForegroundColor Yellow
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""

    $Choice = Read-Host "  AWAITING COMMAND"
    $DoRescan = $false

    Write-Host ""
    switch ($Choice) {
        '1' {
            Write-ActivityLog "User dumped MpComputerStatus."
            Write-GandiStatus -Status "INFO" -Message "Dumping Get-MpComputerStatus..."
            if ($defStatus) {
                $defStatus | Select-Object AMProductVersion, AMEngineVersion, AntivirusEnabled, AntispywareEnabled, BehaviorMonitorEnabled, IoavProtectionEnabled, NISEnabled, RealTimeProtectionEnabled | Format-List | Out-String | ForEach-Object {
                    if ($_ -ne '') { Write-Host "  $_" -ForegroundColor DarkGray }
                }
            }
            else {
                Write-Host "  [ERROR] Tidak dapat menarik data MpComputerStatus." -ForegroundColor Red
            }
            Read-Host "  [ ? ] Tekan ENTER untuk melanjutkan" | Out-Null
        }
        '2' {
            Write-ActivityLog "User opened Windows Security Dashboard."
            Write-GandiStatus -Status "INFO" -Message "Membuka Windows Security Center..."
            Start-Process "windowsdefender:" -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        }
        '3' {
            Write-ActivityLog "User rescanned."
            $DoRescan = $true
        }
        '5' {
            Invoke-DefenderAction -Label "Remove Defender Antivirus Only" -Arg "A" -WithReboot $false
        }
        '6' {
            Invoke-DefenderAction -Label "Remove Defender FULL + Security App" -Arg "Y" -WithReboot $true
        }
        '7' {
            Invoke-RemoveFiles
        }
        '8' {
            Invoke-RemoveSecHealthApp
        }
        '9' {
            Write-ActivityLog "User exited AV Conflict module."
            Invoke-GandiTypewriter -Text "CLOSING AV DETECTOR..." -DelayMs 10 -Color Red
            Start-Sleep -Seconds 1
            exit
        }
        default {
            Write-GandiStatus -Status "FAIL" -Message "Command tidak valid."
            Start-Sleep -Seconds 1
        }
    }

    if ($DoRescan) { continue }
}
