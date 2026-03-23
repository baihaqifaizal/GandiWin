# WAJIB ada di setiap script utama
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) {
    Write-Host "[ERROR] PowerShell 5.1+ required!" -ForegroundColor Red
    pause
    exit 1
}

$UIModule = "$PSScriptRoot\..\..\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

# Init log (ATURAN Layer 1 - ScriptDir fallback)
if ($PSScriptRoot -ne '') { $ScriptDir = $PSScriptRoot }
else { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
$LogFile = "$ScriptDir\..\..\logs\menu.log"
if (!(Test-Path (Split-Path $LogFile))) { New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null }
function Write-ActivityLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [1_THERMAL_CHECK] $Message" -ErrorAction SilentlyContinue } catch {}
}
Write-ActivityLog "Module launched"

function Get-TempBar {
    param([int]$Temp)
    if ($null -eq $Temp -or $Temp -le 0) { return "...................." }
    $MaxTemp = 100
    $Blocks = [Math]::Round(($Temp / $MaxTemp) * 20)
    if ($Blocks -gt 20) { $Blocks = 20 }
    if ($Blocks -lt 0) { $Blocks = 0 }
    return ("#" * $Blocks) + ("." * (20 - $Blocks))
}

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: THERMAL CHECK (TTA INTEGRATION)"
    Show-GandiHeader -Title "01 THERMAL CHECK"
    
    Write-GandiStatus -Status "INFO" -Message "Initiating Hardware Thermal Probes..."
    Start-Sleep -Milliseconds 200
    Write-Host ""

    $MaxDetectedTemp = 0

    # ========================================================================
    # CPU THERMAL SCAN
    # ========================================================================
    Write-GandiStatus -Status "WAIT" -Message "Querying ACPI Thermal Zones (CPU/Motherboard)..."
    $cpuTempRaw = Get-CimInstance -Namespace "root/wmi" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
    
    $validCpuSensors = 0
    if ($cpuTempRaw) {
        foreach ($probe in $cpuTempRaw) {
            $rawTemp = $probe.CurrentTemperature
            if ($null -eq $rawTemp -or $rawTemp -le 2732) { continue }
            
            $validCpuSensors++
            $tempC = [Math]::Round(($rawTemp / 10) - 273.15, 1)
            if ($tempC -gt $MaxDetectedTemp -and $tempC -lt 150) { $MaxDetectedTemp = $tempC }
            $statusColor = if ($tempC -lt 55) { "Green" } elseif ($tempC -lt 85) { "Yellow" } else { "Red" }
            
            $barStr = Get-TempBar -Temp $tempC
            $Name = $probe.InstanceName
            if ($Name.Length -gt 20) { $Name = $Name.Substring(0, 17) + "..." }
            Show-GandiKeyValue -Key "ZONE: $Name" -Value "$tempC C  [$barStr]" -ValueColor $statusColor
        }
    }
    if ($validCpuSensors -eq 0) {
        Write-GandiStatus -Status "WARN" -Message "Sensors blocked by BIOS (Use TTA 'status' manually)"
    }
    Write-Host ""
    
    # ========================================================================
    # STORAGE THERMAL SCAN
    # ========================================================================
    Write-GandiStatus -Status "WAIT" -Message "Querying Storage Subsystem (NVMe/SSD/HDD)..."
    try {
        $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
        $validDiskSensors = 0
        foreach ($disk in $disks) {
            $counters = $disk | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
            if ($counters -and $null -ne $counters.Temperature -and $counters.Temperature -gt 0) {
                $validDiskSensors++
                $tempC = $counters.Temperature
                if ($tempC -gt $MaxDetectedTemp -and $tempC -lt 150) { $MaxDetectedTemp = $tempC }
                $statusColor = if ($tempC -lt 45) { "Green" } elseif ($tempC -lt 65) { "Yellow" } else { "Red" }
                
                $barStr = Get-TempBar -Temp $tempC
                $Name = $disk.FriendlyName
                if ($Name.Length -gt 20) { $Name = $Name.Substring(0, 17) + "..." }
                Show-GandiKeyValue -Key "DRIVE: $Name" -Value "$tempC C  [$barStr]" -ValueColor $statusColor
            }
        }
        if ($validDiskSensors -eq 0) {
            Write-GandiStatus -Status "WARN" -Message "S.M.A.R.T Probes: NO VALID DATA RECEIVED"
        }
    }
    catch {
        Write-GandiStatus -Status "FAIL" -Message "Storage Controller I/O EXCEPTION"
    }
    
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    
    # ========================================================================
    # DYNAMIC RECOMMENDATIONS BASED ON LIMITS
    # ========================================================================
    if ($MaxDetectedTemp -ge 85) {
        Write-Host "  [ KESIMPULAN & REKOMENDASI ]" -ForegroundColor Red
        Write-Host "  Masalah: CPU/GPU terlalu panas ($MaxDetectedTemp C+)." -ForegroundColor White
        Write-Host "  Detil  : Sistem akan memotong kecepatan (Throttle) secara paksa untuk" -ForegroundColor White
        Write-Host "           mencegah kerusakan. Ini penyebab pasti 'Windows lemot'." -ForegroundColor White
        Write-Host "  Solusi : Jalankan TTA [4] Doctor. Bersihkan debu/ganti thermal paste." -ForegroundColor Cyan
    }
    elseif ($MaxDetectedTemp -ge 65) {
        Write-Host "  [ KESIMPULAN & REKOMENDASI ]" -ForegroundColor Yellow
        Write-Host "  Masalah: Suhu sistem cukup hangat ($MaxDetectedTemp C)." -ForegroundColor White
        Write-Host "  Solusi : Pantau dengan TTA [1] Watch / [3] Analyze jika terasa lag." -ForegroundColor Cyan
    }
    elseif ($MaxDetectedTemp -gt 0) {
        Write-Host "  [ KESIMPULAN & REKOMENDASI ]" -ForegroundColor Green
        Write-Host "  Status : Suhu normal dan aman ($MaxDetectedTemp C)." -ForegroundColor White
        Write-Host "  Solusi : Kinerja sistem optimal. Tidak ada gejala Thermal Throttling." -ForegroundColor Cyan
    }
    else {
        Write-Host "  [ KESIMPULAN & REKOMENDASI ]" -ForegroundColor DarkGray
        Write-Host "  Data WMI kosong. Silakan gunakan modul TTA secara langsung." -ForegroundColor White
    }

    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  [ THERMAL THROTTLING ANALYZER (TTA) ]" -ForegroundColor Cyan
    Write-Host "  [1] Watch Thermal State (Real-time monitor)" -ForegroundColor White
    Write-Host "  [2] View Current Status Snapshot" -ForegroundColor White
    Write-Host "  [3] Analyze Past Thermal Events" -ForegroundColor White
    Write-Host "  [4] Run Thermal Doctor Advice" -ForegroundColor White
    Write-Host "  [5] View Raw Thermal Logs" -ForegroundColor White
    Write-Host "  [6] RESCAN SENSORS (Refresh Data)" -ForegroundColor Yellow
    Write-Host "  [7] KEMBALI KE MENU" -ForegroundColor Yellow
    Write-Host ""
    
    $Choice = Read-Host "  AWAITING COMMAND (1-7)"
    if ($Choice -eq '7') {
        Invoke-GandiTypewriter -Text "CLOSING THERMAL ANALYZER..." -DelayMs 10 -Color Red
        Start-Sleep -Seconds 1
        exit
    }
    if ($Choice -eq '6') {
        continue
    }
    
    $ttaExe = "$PSScriptRoot\tta.exe"
    if (-not (Test-Path $ttaExe)) {
        Write-Host ""
        Write-GandiStatus -Status "FAIL" -Message "tta.exe tidak ditemukan di folder modul!"
        Start-Sleep -Seconds 2
        continue
    }

    Write-Host ""
    switch ($Choice) {
        '1' { 
            Write-GandiStatus -Status "INFO" -Message "Launching Watch Mode. Press Ctrl+C to stop."
            Write-Host ""
            & $ttaExe watch 
        }
        '2' { 
            Write-GandiStatus -Status "INFO" -Message "Executing Status Check..."
            Write-Host ""
            & $ttaExe status 
        }
        '3' { 
            Write-GandiStatus -Status "INFO" -Message "Analyzing Events (Last 2h)..."
            Write-Host ""
            & $ttaExe analyze 
        }
        '4' { 
            Write-GandiStatus -Status "INFO" -Message "Running Doctor Diagnostics..."
            Write-Host ""
            & $ttaExe doctor 
        }
        '5' { 
            Write-GandiStatus -Status "INFO" -Message "Dumping Raw Logs..."
            Write-Host ""
            & $ttaExe log 
        }
        default {
            Write-GandiStatus -Status "FAIL" -Message "Command tidak valid."
            Start-Sleep -Seconds 1
            continue
        }
    }
    
    Write-Host ""
    Write-Host ("=" * 66) -ForegroundColor DarkGray
    Write-Host "  [ INFO ] Eksekusi modul TTA selesai." -ForegroundColor Cyan
    Read-Host "  [ ? ] Tekan ENTER untuk kembali ke menu fitur " | Out-Null
}
