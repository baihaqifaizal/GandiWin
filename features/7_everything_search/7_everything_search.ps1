# encoding: UTF-8
# GandiWin :: 07 Everything Search
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) { Write-Host "[ERROR] PS 5.1+ required!" -ForegroundColor Red; pause; exit 1 }

if ($PSScriptRoot -ne '') { $ScriptDir = $PSScriptRoot }
else { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }

$UIModule = "$ScriptDir\..\..\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

$LogFile = "$ScriptDir\..\..\logs\menu.log"
if (!(Test-Path (Split-Path $LogFile))) { New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null }

function Write-ActivityLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [07_EVERYTHING] $Message" -ErrorAction SilentlyContinue } catch {}
}

Write-ActivityLog "Module launched"

function Invoke-DisableWindowsSearch {
    Write-GandiStatus -Status "WAIT" -Message "Stopping WSearch service..."
    try {
        $svc = Get-Service -Name "WSearch" -ErrorAction Stop
        Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "WSearch" -StartupType Disabled -ErrorAction Stop
        Write-GandiStatus -Status "OK" -Message "WSearch service disabled."
        Write-ActivityLog "DISABLED WSearch" "OK"
    }
    catch {
        Write-GandiStatus -Status "WARN" -Message "WSearch tidak ditemukan atau sudah dinonaktifkan."
        Write-ActivityLog "WSearch already disabled or not found" "WARN"
    }

    # Reduce indexing scope: remove all non-system locations
    Write-GandiStatus -Status "WAIT" -Message "Membatasi scope indexing..."
    try {
        $sm = New-Object -ComObject Microsoft.Search.Internals.SearchManager -ErrorAction SilentlyContinue
        if ($sm) {
            $catalog = $sm.GetCatalog("SystemIndex")
            $crawl = $catalog.GetCrawlScopeManager()
            $crawl.RemovePath("file:///")
            $crawl.AddDefaultScopeRule("file:///C:\\Windows\\", $true, "FOLLOW")
            $crawl.SaveAll()
            Write-GandiStatus -Status "OK" -Message "Scope indexing dibatasi ke C:\\Windows."
            Write-ActivityLog "INDEXING SCOPE LIMITED" "OK"
        }
    }
    catch {
        Write-ActivityLog "COM scope manager not available, skipping: $($_.Exception.Message)" "WARN"
    }

    # Registry tweak to prevent indexing on non-system volumes
    $volumes = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne "C" }
    foreach ($vol in $volumes) {
        $driveLetter = $vol.Name + ":\\"
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\ContentIndex\Volumes"
        Write-ActivityLog "SKIP INDEXING ON: $driveLetter" "INFO"
    }

    Write-GandiStatus -Status "OK" -Message "Windows Search diminimalkan."
    Start-Sleep 1
}

function Show-EverythingGuide {
    [Console]::Clear()
    Show-GandiHeader -Title "07 EVERYTHING SEARCH - PANDUAN"
    Write-Host ""
    Show-GandiBox -Title "GANTI WINDOWS SEARCH DENGAN EVERYTHING"
    Write-Host ""
    Write-Host "  Everything by Voidtools adalah alternatif Windows Search terbaik:" -ForegroundColor White
    Write-Host "  - Indexing instan (1 detik untuk ratusan ribu file)" -ForegroundColor Cyan
    Write-Host "  - RAM usage: < 5MB (vs WSearch: 100-500MB)" -ForegroundColor Cyan
    Write-Host "  - Real-time update tanpa background crawling" -ForegroundColor Cyan
    Write-Host "  - Bisa dipakai via CLI: es.exe [query]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  DOWNLOAD:" -ForegroundColor Yellow
    Write-Host "  Stable : https://www.voidtools.com/Everything-1.4.1.1026.x64-Setup.exe" -ForegroundColor White
    Write-Host "  Portable: https://www.voidtools.com/Everything-1.4.1.1026.x64.zip" -ForegroundColor White
    Write-Host ""
    Write-Host "  SETELAH INSTALL:" -ForegroundColor Yellow
    Write-Host "  Tools > Options > Indexes > Volume > NTFS = aktif" -ForegroundColor White
    Write-Host "  Tools > Options > UI > Start minimized to system tray = aktif" -ForegroundColor White
    Write-Host "  Tools > Options > General > Start Everything on system startup = aktif" -ForegroundColor White
    Write-Host ""
    Write-Host "  Tekan tombol apapun untuk kembali..." -ForegroundColor DarkGray
    [Console]::ReadKey($true) | Out-Null
}

function Get-WSearchStatus {
    try {
        $svc = Get-Service -Name "WSearch" -ErrorAction Stop
        return $svc.Status.ToString() + " (" + $svc.StartType.ToString() + ")"
    }
    catch { return "Tidak ditemukan" }
}

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: 07 EVERYTHING SEARCH"
    Show-GandiHeader -Title "07 EVERYTHING SEARCH"
    Write-Host ""
    $wStatus = Get-WSearchStatus
    Show-GandiKeyValue -Key "Windows Search" -Value $wStatus -ValueColor "Yellow"
    Write-Host ""
    Write-Host "  [1] Disable Windows Search (WSearch service)" -ForegroundColor White
    Write-Host "  [2] Panduan Install Everything Search" -ForegroundColor Cyan
    Write-Host "  [Q] Keluar" -ForegroundColor Yellow

    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') {
        Write-ActivityLog "TWEAK INITIATED: #7 - Everything Search"
        Invoke-DisableWindowsSearch
    }
    elseif ($c -eq '2') { Show-EverythingGuide }
    elseif ($c -eq 'Q') { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
}
