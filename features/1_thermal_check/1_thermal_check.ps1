# WAJIB ada di setiap script utama
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) {
    Write-Host "[ERROR] PowerShell 5.1+ required!" -ForegroundColor Red
    pause
    exit 1
}

$UIModule = "$PSScriptRoot\..\..\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

Set-GandiConsole -Title "GANDIWIN :: THERMAL CHECK"
Show-GandiHeader -Title "THERMAL CHECK MODULE"
Write-GandiStatus -Status "INFO" -Message "Mempersiapkan modul diagnostik thermal..."
Invoke-GandiTypewriter -Text "Scanning sensors..." -DelayMs 20 -Color Cyan
Start-Sleep -Seconds 1
Write-Host ""
Write-GandiStatus -Status "WAIT" -Message "Process sedang dalam pengembangan."

Write-Host ""
pause
exit
