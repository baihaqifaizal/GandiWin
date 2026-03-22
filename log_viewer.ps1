<#
.SYNOPSIS
    GandiWin Log Viewer - Activity Monitoring Station
.DESCRIPTION
    View, export, and monitor all tweak activity logs
    Target: Windows 10/11 with PowerShell 3.0+
#>

# WAJIB ada di setiap script utama (Rule 1.4)
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) {
    Write-Host "[ERROR] PowerShell 5.1+ required!" -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    pause
    exit 1
}

# Import The UI Module
$UIModule = "$PSScriptRoot\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

Set-GandiConsole -Title "GANDIWIN :: LOG MONITOR"

# ============================================================================
# CONFIGURATION
# ============================================================================

$Script:LogsDir = "$PSScriptRoot\logs"
$Script:ActivityLog = "$Script:LogsDir\tweak_activity.log"

# Create logs directory
if (!(Test-Path $Script:LogsDir)) { New-Item -ItemType Directory -Path $Script:LogsDir -Force | Out-Null }

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Show-Header {
    param([string]$Title)
    Set-GandiConsole -Title $Title
    if ($Title -eq "GANDIWIN LOG MONITORING STATION") {
        Show-GandiBanner
    }
    else {
        Clear-Host
        Write-Host ""
    }
    Show-GandiBox -Title $Title
    Write-Host "  $([char]0x2502) TIMESTAMP: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
    Write-Host "  $([char]0x2514)$([char]0x2500)$([char]0x2500)" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "  $([char]0x250C)$([char]0x2500) $Text" -ForegroundColor Cyan
    Write-Host "  $([char]0x2502)" -ForegroundColor DarkGray
}

function Show-All-Logs {
    Show-Header "GANDIWIN LOG MONITORING STATION - ALL LOGS"
    
    $LogFiles = Get-ChildItem -Path $Script:LogsDir -Filter "*.log" -ErrorAction SilentlyContinue
    
    if (!$LogFiles) {
        Write-Host "  [INFO] No log files found." -ForegroundColor Cyan
        Write-Host "  [INFO] Run features from the Control Center to see activity." -ForegroundColor Cyan
    }
    else {
        foreach ($Log in $LogFiles) {
            Write-Host ""
            Write-Host "════════════════════════════════════════" -ForegroundColor DarkGray
            Write-Host "  FILE: $($Log.Name)" -ForegroundColor Cyan
            Write-Host "════════════════════════════════════════" -ForegroundColor DarkGray
            Get-Content $Log.FullName -Tail 20 | ForEach-Object {
                Write-Host "  $_" -ForegroundColor White
            }
        }
    }
    
    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Activity-Log {
    Show-Header "GANDIWIN LOG MONITORING STATION - ACTIVITY LOG"
    
    if (Test-Path $Script:ActivityLog) {
        Write-Host "  Showing last 15 entries:" -ForegroundColor Cyan
        Write-Host ""
        Get-Content $Script:ActivityLog -Tail 15 | ForEach-Object {
            if ($_ -like "*TWEAK*") {
                Write-Host "  $_" -ForegroundColor Green
            }
            elseif ($_ -like "*ERROR*") {
                Write-Host "  $_" -ForegroundColor Red
            }
            else {
                Write-Host "  $_" -ForegroundColor White
            }
        }
    }
    else {
        Write-Host "  [INFO] No tweak activity logged yet." -ForegroundColor Cyan
        Write-Host "  [INFO] Run features from the Control Center to see activity." -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Clear-All-Logs {
    Show-Header "GANDIWIN LOG MONITORING STATION - CLEAR LOGS"
    
    Write-Host "  [!] WARNING: This will delete ALL log files." -ForegroundColor Red
    Write-Host ""
    $Confirm = Read-Host "  Type 'DELETE' to confirm"
    
    if ($Confirm -eq "DELETE") {
        Write-Host ""
        Invoke-GandiTypewriter -Text "  [*] Clearing logs..." -DelayMs 10 -Color Cyan
        Get-ChildItem -Path $Script:LogsDir -Filter "*.log" | Remove-Item -Force
        Write-GandiStatus -Status "OK" -Message "All logs cleared."
        Start-Sleep -Seconds 1
    }
    else {
        Write-Host ""
        Write-GandiStatus -Status "WARN" -Message "CANCELLED"
        Start-Sleep -Seconds 1
    }
}

function Export-Logs {
    Show-Header "GANDIWIN LOG MONITORING STATION - EXPORT LOGS"
    
    $ExportFile = "$Script:LogsDir\export_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    Write-Host "  [*] Exporting logs to: $ExportFile" -ForegroundColor Cyan
    Write-Host ""
    
    $Content = @"
================================================================================
GANDIWIN LOG EXPORT
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================================================================

"@
    
    $LogFiles = Get-ChildItem -Path $Script:LogsDir -Filter "*.log" -ErrorAction SilentlyContinue
    foreach ($Log in $LogFiles) {
        $Content += @"

--------------------------------------------------------------------------------
[SOURCE: $($Log.Name)]
--------------------------------------------------------------------------------
$(Get-Content $Log.FullName)

"@
    }
    
    $Content += "`n================================================================================`n"
    $Content | Out-File -FilePath $ExportFile -Encoding UTF8
    
    Write-GandiStatus -Status "OK" -Message "Logs exported successfully!"
    Write-Host ""
    
    # Open in notepad
    Start-Process notepad -ArgumentList $ExportFile
    
    Write-Host "  Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Live-Monitor {
    :MonitorLoop while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "================================================================================" -ForegroundColor Yellow
        Write-Host "  GANDIWIN LIVE MONITOR MODE" -ForegroundColor Yellow
        Write-Host "================================================================================" -ForegroundColor Yellow
        Write-Host "  Press Ctrl+C to stop monitoring..." -ForegroundColor Cyan
        Write-Host "  Auto-refresh every 3 seconds..." -ForegroundColor Cyan
        Write-Host "================================================================================" -ForegroundColor Yellow
        Write-Host ""
        
        if (Test-Path $Script:ActivityLog) {
            Write-Host "  [RECENT ACTIVITY]" -ForegroundColor Cyan
            Write-Host ""
            Get-Content $Script:ActivityLog -Tail 10 | ForEach-Object {
                if ($_ -like "*TWEAK*") {
                    Write-Host "  $_" -ForegroundColor Green
                }
                elseif ($_ -like "*ERROR*") {
                    Write-Host "  $_" -ForegroundColor Red
                }
                else {
                    Write-Host "  $_" -ForegroundColor White
                }
            }
        }
        else {
            Write-Host "  [INFO] No activity logged yet..." -ForegroundColor Cyan
        }
        
        Start-Sleep -Seconds 3
    }
}

# ============================================================================
# MAIN MENU
# ============================================================================

while ($true) {

    Show-Header "GANDIWIN LOG MONITORING STATION"

    Show-Section "RECENT TWEAK ACTIVITY"

    if (Test-Path $Script:ActivityLog) {
        Get-Content $Script:ActivityLog -Tail 10 | ForEach-Object {
            if ($_ -like "*TWEAK*") {
                Write-Host "  $_" -ForegroundColor Green
            }
            elseif ($_ -like "*ERROR*") {
                Write-Host "  $_" -ForegroundColor Red
            }
            else {
                Write-Host "  $_" -ForegroundColor White
            }
        }
    }
    else {
        Write-Host "  [INFO] No tweak activity logged yet." -ForegroundColor Cyan
        Write-Host "  [INFO] Run features from the Control Center to see activity." -ForegroundColor Cyan
    }

    Show-Section "OPTIONS"
    Write-Host "  [1] View Activity Log (tweak_activity.log)" -ForegroundColor White
    Write-Host "  [2] View All Logs" -ForegroundColor White
    Write-Host "  [3] Clear All Logs" -ForegroundColor White
    Write-Host "  [4] Export Logs" -ForegroundColor White
    Write-Host "  [5] Live Monitor Mode" -ForegroundColor White
    Write-Host "  [R] REFRESH           [Q] DEACTIVATE" -ForegroundColor Yellow
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""

    $Choice = Read-Host "  AWAITING COMMAND"

    if ([string]::IsNullOrEmpty($Choice)) { continue }

    $ChoiceUpper = $Choice.ToUpper()

    switch ($ChoiceUpper) {
        "1" { Show-Activity-Log }
        "2" { Show-All-Logs }
        "3" { Clear-All-Logs }
        "4" { Export-Logs }
        "5" { Live-Monitor }
        "R" { }
        "Q" {
            Write-Host ""
            Invoke-GandiTypewriter -Text "SHUTTING DOWN TERMINAL..." -DelayMs 10 -Color Red
            pause
            exit
        }
        default {
            Write-GandiStatus -Status "FAIL" -Message "Invalid command."
            Start-Sleep -Milliseconds 500
        }
    }

}
