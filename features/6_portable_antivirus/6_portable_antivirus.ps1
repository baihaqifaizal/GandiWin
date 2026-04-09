# encoding: UTF-8
# GandiWin :: 06 Portable Antivirus
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
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [06_AV] $Message" -ErrorAction SilentlyContinue } catch {}
}

Write-ActivityLog "Module launched"

function Get-InstalledAVList {
    $result = @()
    $OSBuild = [System.Environment]::OSVersion.Version.Build
    if ($OSBuild -ge 9200) {
        try {
            $avList = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction Stop
            foreach ($av in $avList) {
                $isWindDef = ($av.displayName -match "Windows Defender" -or $av.displayName -match "Microsoft Defender")
                $result += [PSCustomObject]@{
                    Name         = $av.displayName.Substring(0, [Math]::Min($av.displayName.Length, 30))
                    Rec          = if ($isWindDef) { "unsafe" } else { "safe" }
                    Type         = "AV"
                    FullName     = $av.displayName
                    ProductState = $av.productState
                    Checked      = -not $isWindDef
                }
            }
        }
        catch {
            Write-ActivityLog "WMI SecurityCenter2 failed: $($_.Exception.Message)" "FAIL"
        }
    }
    if ($result.Count -eq 0) {
        $result += [PSCustomObject]@{ Name = "Tidak ada AV terdeteksi"; Rec = "optional"; Type = "INFO"; FullName = ""; ProductState = 0; Checked = $false }
    }
    return $result
}

function Invoke-AVAction {
    param($Item)
    if ($Item.Type -eq "INFO") { return $false }
    try {
        # Try disable via WMI if possible, else uninstall via WMIC
        $prodName = $Item.FullName
        Write-ActivityLog "ATTEMPTING DISABLE: $prodName"

        # Try uninstall via Get-WmiObject Win32_Product (last resort, slow)
        $prod = Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$($Item.FullName.Split(' ')[0])*" }
        if ($prod) {
            $prod.Uninstall() | Out-Null
            Write-ActivityLog "UNINSTALLED: $prodName" "OK"
            return $true
        }

        # Fallback: disable service if known
        $svcMap = @{
            "Avast"       = "avast! Antivirus"
            "AVG"         = "avgwd"
            "Smadav"      = "SmadavProtectService"
            "Norton"      = "NortonLifeLock"
            "McAfee"      = "McAfeeFramework"
            "Kaspersky"   = "AVP"
            "ESET"        = "ekrn"
            "Bitdefender" = "bdredline"
        }
        foreach ($kw in $svcMap.Keys) {
            if ($prodName -match $kw) {
                $svcName = $svcMap[$kw]
                $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
                if ($svc) {
                    Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
                    Write-ActivityLog "DISABLED SVC: $svcName" "OK"
                    return $true
                }
            }
        }

        Write-Host "  [!] $prodName tidak dapat di-disable otomatis. Uninstall manual dari Control Panel." -ForegroundColor Yellow
        Write-ActivityLog "MANUAL REQUIRED: $prodName" "WARN"
        return $false
    }
    catch {
        Write-ActivityLog "FAILED: $($_.Exception.Message)" "FAIL"
        Write-Host "  [!] Melewati $($Item.Name) (Tidak didukung di sistem ini)..." -ForegroundColor Yellow
        return $false
    }
}

function Show-PortableAVGuide {
    [Console]::Clear()
    Show-GandiHeader -Title "06 PANDUAN PORTABLE ANTIVIRUS"
    Write-Host ""
    Show-GandiBox -Title "REKOMENDASI PORTABLE ANTIVIRUS"
    Write-Host ""
    Write-Host "  Portable antivirus TIDAK perlu install. Jalankan langsung dari USB." -ForegroundColor White
    Write-Host ""
    Write-Host "  [A] Malwarebytes Portable (Adware + Malware Scanner)" -ForegroundColor Cyan
    Write-Host "      URL: www.malwarebytes.com/mwb-download/thankyou" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [B] ESET Online Scanner (Full AV scan, no install)" -ForegroundColor Cyan
    Write-Host "      URL: www.eset.com/int/home/online-scanner" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [C] HitmanPro (Cloud-based, 30-day free)" -ForegroundColor Cyan
    Write-Host "      URL: www.hitmanpro.com/en-us/hmp.aspx" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [D] ClamWin Portable (Open source, ClamAV)" -ForegroundColor Cyan
    Write-Host "      URL: portableapps.com/apps/security/clamwin_portable" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [E] Kaspersky Virus Removal Tool (KVRT)" -ForegroundColor Cyan
    Write-Host "      URL: support.kaspersky.com/kvrt" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Setelah AV lama dihapus, gunakan salah satu di atas untuk scan." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [ESC] Kembali" -ForegroundColor DarkGray
    while ($true) {
        $k = [Console]::ReadKey($true)
        if ($k.Key -eq 'Escape') { return }
    }
}

function Invoke-AVChecklistUI {
    param([string]$Title, [array]$Items)
    $Checked = @{}
    for ($i = 0; $i -lt $Items.Count; $i++) { $Checked[$i] = $Items[$i].Checked }
    $Cursor = 0
    [Console]::Clear()
    while ($true) {
        [Console]::SetCursorPosition(0, 0)
        Show-GandiHeader -Title $Title
        Write-Host "  Antivirus terdeteksi di sistem:" -ForegroundColor White
        Write-Host "  WHITE=bisa dinonaktifkan | RED=Windows Defender (jangan hapus)" -ForegroundColor DarkGray
        Write-Host ""
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $it = $Items[$i]
            $lc = if ($Checked[$i]) { "[X]" } else { "[ ]" }
            $ln = $it.Name
            $lf = switch ($it.Rec) { 'safe' { 'White' } 'unsafe' { 'Red' } default { 'Yellow' } }
            $lb = if ($i -eq $Cursor) { 'DarkCyan' } else { 'Black' }
            Write-Host ("  {0} {1,-40}" -f $lc, $ln) -ForegroundColor $lf -BackgroundColor $lb
        }
        Write-Host "`n  TOGGLE: SPACE | EXEC: ENTER | ESC: BACK" -ForegroundColor DarkGray
        $k = [Console]::ReadKey($true)
        switch ($k.Key) {
            'UpArrow' { if ($Cursor -gt 0) { $Cursor-- } }
            'DownArrow' { if ($Cursor -lt ($Items.Count - 1)) { $Cursor++ } }
            'Spacebar' { $Checked[$Cursor] = -not $Checked[$Cursor] }
            'Escape' { return }
            'Enter' {
                $exec = 0..($Items.Count - 1) | Where-Object { $Checked[$_] } | ForEach-Object { $Items[$_] }
                if ($exec.Count -eq 0) { continue }
                [Console]::Clear(); Show-GandiHeader -Title "KONFIRMASI"
                Write-Host "  Nonaktifkan/uninstall $($exec.Count) AV? (YES/NO)"
                if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                Write-ActivityLog "TWEAK INITIATED: #6 - Portable AV"
                foreach ($item in $exec) {
                    Write-GandiStatus -Status "WAIT" -Message "Proses: $($item.Name)"
                    Invoke-AVAction -Item $item | Out-Null
                }
                Write-GandiStatus -Status "OK" -Message "Selesai. Restart lalu scan dengan Portable AV."; Start-Sleep 3; return
            }
        }
    }
}

while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: 06 PORTABLE ANTIVIRUS"
    Show-GandiHeader -Title "06 PORTABLE ANTIVIRUS"
    Write-Host ""
    Write-Host "  [1] Deteksi dan Nonaktifkan AV Konflik" -ForegroundColor White
    Write-Host "  [2] Panduan Portable Antivirus" -ForegroundColor Cyan
    Write-Host "  [Q] Keluar" -ForegroundColor Yellow

    $c = (Read-Host "`n  PILIH").ToUpper()
    if ($c -eq '1') {
        Write-GandiStatus -Status "WAIT" -Message "Mendeteksi antivirus..."
        $list = Get-InstalledAVList
        Invoke-AVChecklistUI "06 DETEKSI ANTIVIRUS" $list
    }
    elseif ($c -eq '2') { Show-PortableAVGuide }
    elseif ($c -eq 'Q') { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
}
