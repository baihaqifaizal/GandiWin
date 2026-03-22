# WAJIB ada di setiap script utama
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) {
    Write-Host "[ERROR] PowerShell 5.1+ required!" -ForegroundColor Red
    pause
    exit 1
}

$UIModule = "$PSScriptRoot\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

Set-GandiConsole -Title "GANDIWIN :: REAL-TIME LOG MONITOR"
Show-GandiBanner
Show-GandiHeader -Title "DAEMON LOGGING STATION"

$LogDir = "$PSScriptRoot\logs"
$LogFile = "$LogDir\menu.log"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
if (-not (Test-Path $LogFile)) { New-Item -ItemType File -Path $LogFile -Force | Out-Null }

Write-Host "  [+] INFO : Daemon memantau file secara langsung." -ForegroundColor Cyan
Write-Host "  [+] FILE : $LogFile" -ForegroundColor Cyan
Write-Host "  [+] INFO : Menunggu aktivitas dari semua folder fitur..." -ForegroundColor Yellow
Write-Host ("  " + ("=" * 64)) -ForegroundColor DarkGray
Write-Host ""

try {
    # Get-Content -Wait blocks the thread and outputs any appends to the file to the console
    Get-Content -Path $LogFile -Wait -Tail 30 | ForEach-Object {
        $msg = $_
        
        # Color Code mapping primarily by finding keywords
        if ($msg -match "\[ERROR\]|\bFAIL\b|\bWARN\b|Exception|Error") { 
            Write-Host "  $msg" -ForegroundColor Red
        }
        elseif ($msg -match "\[INFO\]|\bOK\b|Success") {
            Write-Host "  $msg" -ForegroundColor Green
        }
        elseif ($msg -match "\[WAIT\]|\bExecuting\b") {
            Write-Host "  $msg" -ForegroundColor Yellow
        }
        else {
            Write-Host "  $msg" -ForegroundColor White
        }
    }
}
catch {
    Write-Host "  [!] ERROR reading log daemon: $($_.Exception.Message)" -ForegroundColor Red
    Start-Sleep -Seconds 5
}
