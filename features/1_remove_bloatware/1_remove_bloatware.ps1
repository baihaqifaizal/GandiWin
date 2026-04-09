# encoding: UTF-8
# GandiWin :: 01 Remove Bloatware
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) { Write-Host "[ERROR] PS 5.1+ required!" -ForegroundColor Red; pause; exit 1 }

if ($PSScriptRoot -ne '') { $ScriptDir = $PSScriptRoot }
else { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }

$UIModule = "$ScriptDir\..\..\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

$LogFile = "$ScriptDir\..\..\logs\menu.log"
if (!(Test-Path (Split-Path $LogFile))) { New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null }

# PowerRun path (TrustedInstaller/SYSTEM elevation)
$Arch = if ([System.Environment]::Is64BitOperatingSystem) { "PowerRun_x64.exe" } else { "PowerRun.exe" }
$PowerRun = "$ScriptDir\..\..\modules\PowerRun\$Arch"

function Write-ActivityLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    try { Add-Content -Path $LogFile -Value "[$ts] [$Level] [01_BLOATWARE] $Message" -ErrorAction SilentlyContinue } catch {}
}

function Invoke-PowerRun {
    param([string]$Command)
    if (Test-Path $PowerRun) {
        $proc = Start-Process -FilePath $PowerRun -ArgumentList "/SW", "0", "/CMD", $Command -Wait -PassThru -WindowStyle Hidden
        return $proc.ExitCode
    }
    else {
        Write-ActivityLog "PowerRun not found: $PowerRun" "WARN"
        return -1
    }
}

Write-ActivityLog "Module launched"

# ─── BLOATWARE SECTION ────────────────────────────────────────────────────────

$Script:SafeWhitelist = @(
    "Microsoft.Windows.ShellComponents", "Microsoft.Windows.SecHealthUI",
    "Microsoft.Windows.Search", "Microsoft.WindowsStore", "Microsoft.StorePurchaseApp",
    "Microsoft.DesktopAppInstaller", "Microsoft.Net.", "Microsoft.VCLibs.", "Microsoft.UI.Xaml",
    "Microsoft.WindowsAppRuntime", "NcsiUwpApp", "Microsoft.AccountsControl", "Microsoft.AsyncTextService",
    "Microsoft.BioEnrollment", "Microsoft.CredDialogHost", "Microsoft.ECApp", "Microsoft.LockApp",
    "Microsoft.Win32WebViewHost", "Microsoft.Windows.Apprep", "Microsoft.Windows.CallingShell",
    "Microsoft.Windows.OOBENetworkCaptivePortal", "Microsoft.Windows.OOBENetworkConnectionFlow",
    "Microsoft.Windows.PeopleExperienceHost", "Microsoft.Windows.PinningConfirmationDialog",
    "Microsoft.Windows.XGpuEjectDialog", "Microsoft.WindowsNotepad", "Microsoft.Paint",
    "Microsoft.WindowsCalculator", "Windows.CBSPreview", "windows.immersivecontrolpanel",
    "Windows.PrintDialog", "InputApp", "Microsoft.Windows.CloudExperienceHost",
    "Microsoft.Windows.ContentDeliveryManager", "Microsoft.Windows.StartMenuExperienceHost",
    "MicrosoftWindows.Client.CBS", "MicrosoftWindows.UndockedDevKit", "Microsoft.WindowsTerminal",
    "Microsoft.WindowsTerminalPreview", "Microsoft.HEIFImageExtension", "Microsoft.VP9VideoExtensions",
    "Microsoft.WebpImageExtension", "Microsoft.RawImageExtension", "Microsoft.NarratorQuickStart",
    "Windows.Photos"
)

$Script:OptionalKeywords = @(
    "Mail", "Calendar", "Xbox", "OneNote", "Skype", "YourPhone", "Sticky",
    "Zune", "Groove", "MixedReality", "Bing", "Wallet", "FeedbackHub",
    "GetHelp", "Maps", "3DBuilder", "3DViewer", "Print3D", "Getstarted", "Alarms", "Camera"
)

# Friendly display names for well-known packages
$Script:KnownNames = @{
    "Microsoft.XboxGamingOverlay"            = "Xbox Game Bar"
    "Microsoft.XboxIdentityProvider"         = "Xbox Identity Provider"
    "Microsoft.XboxSpeechToTextOverlay"      = "Xbox Speech to Text"
    "Microsoft.Xbox.TCUI"                    = "Xbox TCUI"
    "Microsoft.XboxGameOverlay"              = "Xbox Game Overlay"
    "Microsoft.GamingApp"                    = "Xbox Gaming App"
    "Microsoft.3DBuilder"                    = "3D Builder"
    "Microsoft.Microsoft3DViewer"            = "3D Viewer"
    "Microsoft.MicrosoftOfficeHub"           = "Office Hub (Get Office)"
    "Microsoft.MicrosoftSolitaireCollection" = "Solitaire Collection"
    "Microsoft.SkypeApp"                     = "Skype"
    "Microsoft.Office.OneNote"               = "OneNote"
    "Microsoft.People"                       = "People"
    "Microsoft.MixedReality.Portal"          = "Mixed Reality Portal"
    "Microsoft.YourPhone"                    = "Your Phone (Link to Windows)"
    "Microsoft.WindowsFeedbackHub"           = "Feedback Hub"
    "Microsoft.GetHelp"                      = "Get Help"
    "Microsoft.ZuneMusic"                    = "Groove Music"
    "Microsoft.ZuneVideo"                    = "Movies & TV"
    "microsoft.windowscommunicationsapps"    = "Mail & Calendar"
    "Microsoft.WindowsMaps"                  = "Maps"
    "Microsoft.WindowsAlarms"                = "Alarms & Clock"
    "Microsoft.WindowsCamera"                = "Camera"
    "Microsoft.BingNews"                     = "Microsoft News"
    "Microsoft.BingWeather"                  = "Weather (MSN)"
    "Microsoft.BingSports"                   = "Sports (MSN)"
    "Microsoft.BingFinance"                  = "Finance (MSN)"
    "Microsoft.549981C3F5F10"                = "Cortana App"
    "Microsoft.Getstarted"                   = "Tips (Get Started)"
    "Microsoft.Print3D"                      = "Print 3D"
    "Microsoft.MicrosoftStickyNotes"         = "Sticky Notes"
    "Microsoft.Wallet"                       = "Microsoft Wallet"
    "MicrosoftTeams"                         = "Microsoft Teams (Consumer)"
    "Microsoft.Teams"                        = "Microsoft Teams"
    "Microsoft.WindowsFeedback"              = "Windows Feedback"
    "Microsoft.OutlookForWindows"            = "Outlook (New)"
    "Microsoft.MicrosoftEdge.Stable"         = "Microsoft Edge (Store)"
    "king.com.CandyCrushSaga"                = "Candy Crush Saga"
    "king.com.CandyCrushSodaSaga"            = "Candy Crush Soda Saga"
    "king.com.FarmHeroesSaga"                = "Farm Heroes Saga"
    "Facebook.Facebook"                      = "Facebook"
    "Twitter.Twitter"                        = "Twitter / X"
    "BytedancePte.TikTok"                    = "TikTok"
    "SpotifyAB.SpotifyMusic"                 = "Spotify"
    "5319275A.WhatsAppDesktop"               = "WhatsApp"
    "Disney.37853D22215B2"                   = "Disney+"
    "AmazonVideo.PrimeVideo"                 = "Prime Video"
    "ROBLOXCORPORATION.ROBLOX"               = "Roblox"
    "Clipchamp.Clipchamp"                    = "Clipchamp (Video Editor)"
    "Microsoft.PowerAutomateDesktop"         = "Power Automate Desktop"
    "Microsoft.Todos"                        = "Microsoft To Do"
    "MSTeams"                                = "Microsoft Teams (Work)"
}

function Get-FriendlyName {
    param([string]$PackageName)
    if ($Script:KnownNames.ContainsKey($PackageName)) {
        return $Script:KnownNames[$PackageName]
    }
    # Strip publisher prefix and version cruft
    $clean = $PackageName -replace "^[A-Z0-9]+\.", "" -replace "_[0-9]+\.[0-9]+.*$", ""
    $clean = $clean -replace "([a-z])([A-Z])", '$1 $2'
    return $clean
}

function Get-BloatwareList {
    Write-GandiStatus -Status "WAIT" -Message "Scanning installed UWP apps..."
    $result = @()
    try {
        $allPkgs = Get-AppxPackage -AllUsers -ErrorAction Stop | Sort-Object Name
        foreach ($pkg in $allPkgs) {
            if ($pkg.IsFramework) { continue }
            $safe = $false
            foreach ($wl in $Script:SafeWhitelist) {
                if ($pkg.Name -like "*$wl*") { $safe = $true; break }
            }
            if ($safe) { continue }
            $rec = "safe"
            foreach ($kw in $Script:OptionalKeywords) {
                if ($pkg.Name -match $kw) { $rec = "optional"; break }
            }
            $friendly = Get-FriendlyName -PackageName $pkg.Name
            $result += [PSCustomObject]@{
                Name    = $friendly
                Rec     = $rec
                Type    = "UWP"
                Id      = $pkg.Name
                Checked = $true
            }
        }
    }
    catch {
        Write-ActivityLog "Get-AppxPackage FAILED: $($_.Exception.Message)" "FAIL"
        Write-GandiStatus -Status "FAIL" -Message "Scan failed: $($_.Exception.Message)"
        Start-Sleep 2
    }
    $result += [PSCustomObject]@{ Name = "Disable GameDVR/Game Bar"; Rec = "safe"; Type = "REG"; Id = "GAMEDVR_OFF"; Checked = $true }
    $result += [PSCustomObject]@{ Name = "Clean Shell Context Menu Ext"; Rec = "safe"; Type = "REG"; Id = "SHELL_CONTEXT_CLEAN"; Checked = $true }
    $result += [PSCustomObject]@{ Name = "Disable Explorer Quick Access"; Rec = "safe"; Type = "REG"; Id = "EXPLORER_QA_OFF"; Checked = $true }
    $result += [PSCustomObject]@{ Name = "Remove Edge Desktop Shortcut"; Rec = "optional"; Type = "REG"; Id = "EDGE_SHORTCUT"; Checked = $false }
    return $result
}

# ─── SOFTWARE SECTION ─────────────────────────────────────────────────────────

function Get-SoftwareList {
    $result = @()
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $seenNames = @{}
    foreach ($path in $paths) {
        $entries = Get-ItemProperty $path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and $_.DisplayName -ne "" -and $_.SystemComponent -ne 1 -and $null -eq $_.ParentKeyName }
        foreach ($e in $entries) {
            if ($seenNames.ContainsKey($e.DisplayName)) { continue }
            $seenNames[$e.DisplayName] = $true
            $result += [PSCustomObject]@{
                Name      = $e.DisplayName
                Rec       = "optional"
                Type      = "MSI"
                Id        = $e.UninstallString
                Version   = $e.DisplayVersion
                Publisher = $e.Publisher
                Checked   = $false
            }
        }
    }
    return $result | Sort-Object Name
}

# ─── DEFENDER SECTION ─────────────────────────────────────────────────────────

function Get-DefenderList {
    return @(
        [PSCustomObject]@{ Name = "Disable Windows Defender Real-Time Protection"; Rec = "unsafe"; Type = "DEF"; Id = "DEF_REALTIME"; Checked = $false }
        [PSCustomObject]@{ Name = "Disable Defender Cloud Protection (MAPS)"; Rec = "unsafe"; Type = "DEF"; Id = "DEF_MAPS"; Checked = $false }
        [PSCustomObject]@{ Name = "Disable Defender Sample Submission"; Rec = "safe"; Type = "DEF"; Id = "DEF_SAMPLE"; Checked = $true }
        [PSCustomObject]@{ Name = "Disable Defender Automatic Updates"; Rec = "unsafe"; Type = "DEF"; Id = "DEF_UPDATE"; Checked = $false }
        [PSCustomObject]@{ Name = "Disable Defender PUA Protection"; Rec = "optional"; Type = "DEF"; Id = "DEF_PUA"; Checked = $false }
        [PSCustomObject]@{ Name = "Disable SmartScreen (Explorer)"; Rec = "unsafe"; Type = "DEF"; Id = "DEF_SMARTSCREEN_EXP"; Checked = $false }
        [PSCustomObject]@{ Name = "Disable SmartScreen (Edge)"; Rec = "unsafe"; Type = "DEF"; Id = "DEF_SMARTSCREEN_EDGE"; Checked = $false }
        [PSCustomObject]@{ Name = "Disable Security Center Tray Notifications"; Rec = "safe"; Type = "DEF"; Id = "DEF_TRAY"; Checked = $true }
        [PSCustomObject]@{ Name = "Disable Defender Tamper Protection (PowerRun)"; Rec = "unsafe"; Type = "DEF"; Id = "DEF_TAMPER"; Checked = $false }
    )
}

# ─── MS EDGE SECTION ──────────────────────────────────────────────────────────

function Get-EdgeList {
    return @(
        [PSCustomObject]@{ Name = "Disable Edge Background Running"; Rec = "safe"; Type = "EDGE"; Id = "EDGE_BG_RUN"; Checked = $true }
        [PSCustomObject]@{ Name = "Disable Edge Startup Boost"; Rec = "safe"; Type = "EDGE"; Id = "EDGE_BOOST"; Checked = $true }
        [PSCustomObject]@{ Name = "Remove Edge Desktop Shortcut"; Rec = "safe"; Type = "EDGE"; Id = "EDGE_SHORTCUT"; Checked = $true }
        [PSCustomObject]@{ Name = "Remove Edge Taskbar Shortcut"; Rec = "safe"; Type = "EDGE"; Id = "EDGE_TASKBAR"; Checked = $true }
        [PSCustomObject]@{ Name = "Disable Edge Recommendations"; Rec = "safe"; Type = "EDGE"; Id = "EDGE_RECM"; Checked = $true }
        [PSCustomObject]@{ Name = "Block Edge Telemetry (Registry)"; Rec = "safe"; Type = "EDGE"; Id = "EDGE_TELEM"; Checked = $true }
        [PSCustomObject]@{ Name = "Uninstall Edge (PowerRun)"; Rec = "unsafe"; Type = "EDGE"; Id = "EDGE_UNINSTALL"; Checked = $false }
    )
}

# ─── EXECUTION HANDLERS ───────────────────────────────────────────────────────

function Invoke-RemoveBloat {
    param($Item)
    try {
        switch ($Item.Type) {
            "UWP" {
                # Try standard first
                $pkg = Get-AppxPackage -AllUsers -Name $Item.Id -ErrorAction SilentlyContinue
                if ($pkg) {
                    try { $pkg | Remove-AppxPackage -AllUsers -ErrorAction Stop }
                    catch {
                        # Fallback to PowerRun
                        Invoke-PowerRun "powershell.exe -NoProfile -Command `"Get-AppxPackage -AllUsers -Name '$($Item.Id)' | Remove-AppxPackage -AllUsers`"" | Out-Null
                    }
                }
                Write-ActivityLog "REMOVED UWP: $($Item.Id)" "OK"
            }
            "REG" {
                switch ($Item.Id) {
                    "GAMEDVR_OFF" {
                        $p = "HKCU:\System\GameConfigStore"
                        if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                        Set-ItemProperty -Path $p -Name "GameDVR_Enabled" -Value 0 -ErrorAction SilentlyContinue
                        $p2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
                        if (!(Test-Path $p2)) { New-Item -Path $p2 -Force | Out-Null }
                        Set-ItemProperty -Path $p2 -Name "AllowGameDVR" -Value 0 -ErrorAction SilentlyContinue
                    }
                    "SHELL_CONTEXT_CLEAN" {
                        foreach ($k in @("HKCU:\Software\Classes\*\shellex\ContextMenuHandlers", "HKCU:\Software\Classes\Directory\shellex\ContextMenuHandlers")) {
                            if (Test-Path $k) {
                                Get-ChildItem $k -ErrorAction SilentlyContinue |
                                Where-Object { $_.Name -notmatch "Open|7-Zip|WinRAR|Notepad" } |
                                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                            }
                        }
                    }
                    "EXPLORER_QA_OFF" {
                        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Value 0 -ErrorAction SilentlyContinue
                        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Value 0 -ErrorAction SilentlyContinue
                    }
                    "EDGE_SHORTCUT" {
                        foreach ($d in @([Environment]::GetFolderPath("Desktop"), "$env:PUBLIC\Desktop")) {
                            $l = Join-Path $d "Microsoft Edge.lnk"
                            if (Test-Path -LiteralPath $l) { Remove-Item -LiteralPath $l -Force -ErrorAction SilentlyContinue }
                        }
                    }
                }
                Write-ActivityLog "APPLIED REG: $($Item.Id)" "OK"
            }
            "MSI" {
                if ($Item.Id -match "^msiexec") {
                    $uninstallArgs = $Item.Id -replace "msiexec.exe", "" -replace "MsiExec.exe", ""
                    Start-Process "msiexec.exe" -ArgumentList "$uninstallArgs /quiet /norestart" -Wait -ErrorAction SilentlyContinue
                }
                elseif ($null -ne $Item.Id) {
                    Start-Process "cmd.exe" -ArgumentList "/c `"$($Item.Id)`"" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                }
                Write-ActivityLog "UNINSTALLED: $($Item.Name)" "OK"
            }
            "DEF" {
                switch ($Item.Id) {
                    "DEF_REALTIME" {
                        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
                        Invoke-PowerRun "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection`" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f" | Out-Null
                    }
                    "DEF_MAPS" {
                        Set-MpPreference -MAPSReporting Disabled -ErrorAction SilentlyContinue
                        Invoke-PowerRun "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet`" /v SpynetReporting /t REG_DWORD /d 0 /f" | Out-Null
                    }
                    "DEF_SAMPLE" {
                        Set-MpPreference -SubmitSamplesConsent NeverSend -ErrorAction SilentlyContinue
                    }
                    "DEF_UPDATE" {
                        Invoke-PowerRun "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates`" /v ForceUpdateFromMU /t REG_DWORD /d 0 /f" | Out-Null
                    }
                    "DEF_PUA" {
                        Set-MpPreference -PUAProtection Disabled -ErrorAction SilentlyContinue
                    }
                    "DEF_SMARTSCREEN_EXP" {
                        Invoke-PowerRun "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Windows\System`" /v EnableSmartScreen /t REG_DWORD /d 0 /f" | Out-Null
                    }
                    "DEF_SMARTSCREEN_EDGE" {
                        Invoke-PowerRun "reg add `"HKLM\SOFTWARE\Policies\Microsoft\Edge`" /v SmartScreenEnabled /t REG_DWORD /d 0 /f" | Out-Null
                    }
                    "DEF_TRAY" {
                        $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications"
                        if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                        Set-ItemProperty -Path $p -Name "DisableNotifications" -Value 1 -ErrorAction SilentlyContinue
                    }
                    "DEF_TAMPER" {
                        Invoke-PowerRun "reg add `"HKLM\SOFTWARE\Microsoft\Windows Defender`" /v TamperProtection /t REG_DWORD /d 4 /f" | Out-Null
                    }
                }
                Write-ActivityLog "DEFENDER: $($Item.Id)" "OK"
            }
            "EDGE" {
                switch ($Item.Id) {
                    "EDGE_BG_RUN" {
                        $ep = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
                        if (!(Test-Path $ep)) { New-Item -Path $ep -Force | Out-Null }
                        Set-ItemProperty -Path $ep -Name "BackgroundModeEnabled" -Value 0 -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path $ep -Name "StartupBoostEnabled"   -Value 0 -ErrorAction SilentlyContinue
                    }
                    "EDGE_BOOST" {
                        $ep = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
                        if (!(Test-Path $ep)) { New-Item -Path $ep -Force | Out-Null }
                        Set-ItemProperty -Path $ep -Name "StartupBoostEnabled" -Value 0 -ErrorAction SilentlyContinue
                    }
                    "EDGE_SHORTCUT" {
                        foreach ($d in @([Environment]::GetFolderPath("Desktop"), "$env:PUBLIC\Desktop")) {
                            $l = Join-Path $d "Microsoft Edge.lnk"
                            if (Test-Path -LiteralPath $l) { Remove-Item -LiteralPath $l -Force -ErrorAction SilentlyContinue }
                        }
                    }
                    "EDGE_TASKBAR" {
                        $tb = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk"
                        if (Test-Path -LiteralPath $tb) { Remove-Item -LiteralPath $tb -Force -ErrorAction SilentlyContinue }
                    }
                    "EDGE_RECM" {
                        $ep = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
                        if (!(Test-Path $ep)) { New-Item -Path $ep -Force | Out-Null }
                        Set-ItemProperty -Path $ep -Name "PromotionsEnabled" -Value 0 -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path $ep -Name "ShowMicrosoftRewards" -Value 0 -ErrorAction SilentlyContinue
                    }
                    "EDGE_TELEM" {
                        $ep = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
                        if (!(Test-Path $ep)) { New-Item -Path $ep -Force | Out-Null }
                        Set-ItemProperty -Path $ep -Name "MetricsReportingEnabled" -Value 0 -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path $ep -Name "SendSiteInfoToImproveServices" -Value 0 -ErrorAction SilentlyContinue
                    }
                    "EDGE_UNINSTALL" {
                        # Find Edge setup and uninstall via PowerRun (needs TrustedInstaller)
                        $edgeSetup = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application"
                        if (!(Test-Path $edgeSetup)) { $edgeSetup = "$env:ProgramFiles\Microsoft\Edge\Application" }
                        $ver = (Get-ChildItem $edgeSetup -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1).Name
                        if ($ver) {
                            $installer = "$edgeSetup\$ver\Installer\setup.exe"
                            if (Test-Path $installer) {
                                Invoke-PowerRun "`"$installer`" --uninstall --system-level --verbose-logging --force-uninstall" | Out-Null
                            }
                        }
                    }
                }
                Write-ActivityLog "EDGE: $($Item.Id)" "OK"
            }
        }
        return $true
    }
    catch {
        Write-ActivityLog "FAILED $($Item.Id): $($_.Exception.Message)" "FAIL"
        Write-Host "  [!] Skipped $($Item.Name): $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

# ─── CHECKLIST UI ─────────────────────────────────────────────────────────────

function Invoke-ChecklistUI {
    param([string]$Title, [array]$Items, [string]$ConfirmLabel = "Execute")
    if ($Items.Count -eq 0) { Write-GandiStatus -Status "OK" -Message "No items found."; Start-Sleep 2; return }
    $Checked = @{}
    for ($i = 0; $i -lt $Items.Count; $i++) { $Checked[$i] = $Items[$i].Checked }
    $Cursor = 0; $Vis = 22; $Half = [Math]::Ceiling([Math]::Min($Items.Count, $Vis) / 2); $Top = 0
    [Console]::Clear()
    while ($true) {
        if ($Cursor -lt $Top) { $Top = $Cursor }
        if ($Cursor -ge ($Top + $Vis)) { $Top = $Cursor - $Vis + 1 }
        [Console]::Clear()
        Show-GandiHeader -Title $Title
        $sel = ($Checked.Values | Where-Object { $_ }).Count
        Show-GandiKeyValue -Key "Total" -Value $Items.Count -ValueColor "White"
        Show-GandiKeyValue -Key "Selected" -Value $sel -ValueColor $(if ($sel -gt 0) { "Red" } else { "DarkGray" })
        Write-Host ""
        for ($i = 0; $i -lt $Half; $i++) {
            $absL = $Top + $i
            if ($absL -lt $Items.Count) {
                $li = $Items[$absL]
                $lc = if ($Checked[$absL]) { "[X]" } else { "[ ]" }
                $ln = if ($li.Name.Length -gt 30) { $li.Name.Substring(0, 27) + ".." } else { $li.Name }
                $lf = switch ($li.Rec) { 'safe' { 'White' } 'unsafe' { 'Red' } default { 'Yellow' } }
                $lb = if ($absL -eq $Cursor) { 'DarkCyan' } else { 'Black' }
                Write-Host ("  {0} {1,-30}  " -f $lc, $ln) -ForegroundColor $lf -BackgroundColor $lb -NoNewline
            }
            $absR = $Top + $i + $Half
            if ($absR -lt $Items.Count) {
                $ri = $Items[$absR]
                $rc = if ($Checked[$absR]) { "[X]" } else { "[ ]" }
                $rn = if ($ri.Name.Length -gt 30) { $ri.Name.Substring(0, 27) + ".." } else { $ri.Name }
                $rf = switch ($ri.Rec) { 'safe' { 'White' } 'unsafe' { 'Red' } default { 'Yellow' } }
                $rb = if ($absR -eq $Cursor) { 'DarkCyan' } else { 'Black' }
                Write-Host ("  {0} {1,-30}" -f $rc, $rn) -ForegroundColor $rf -BackgroundColor $rb
            }
            else { Write-Host "".PadRight(40) }
        }
        Write-Host "`n  ARROWS: NAV  |  SPACE: TOGGLE  |  A: ALL  |  N: NONE  |  ENTER: $ConfirmLabel  |  ESC: BACK" -ForegroundColor DarkGray
        $k = [Console]::ReadKey($true)
        switch ($k.Key) {
            'UpArrow' { if ($Cursor -gt 0) { $Cursor-- } }
            'DownArrow' { if ($Cursor -lt ($Items.Count - 1)) { $Cursor++ } }
            'LeftArrow' { if ($Cursor -ge $Half) { $Cursor -= $Half } }
            'RightArrow' { if ($Cursor + $Half -lt $Items.Count) { $Cursor += $Half } }
            'Spacebar' { $Checked[$Cursor] = -not $Checked[$Cursor] }
            'A' { 0..($Items.Count - 1) | ForEach-Object { $Checked[$_] = $true } }
            'N' { 0..($Items.Count - 1) | ForEach-Object { $Checked[$_] = $false } }
            'Escape' { return }
            'Enter' {
                $exec = @(0..($Items.Count - 1) | Where-Object { $Checked[$_] } | ForEach-Object { $Items[$_] })
                if ($exec.Count -eq 0) { continue }
                [Console]::Clear(); Show-GandiHeader -Title "CONFIRM"
                Write-Host "  $($exec.Count) item(s) will be processed. Proceed? (YES/NO)"
                if ((Read-Host "  CMD") -ne 'YES') { [Console]::Clear(); continue }
                $ok = 0; $fail = 0
                foreach ($item in $exec) {
                    Write-GandiStatus -Status "WAIT" -Message "Processing: $($item.Name)"
                    if (Invoke-RemoveBloat -Item $item) { 
                        $ok++
                        # Cari indexnya dan uncheck
                        for ($i = 0; $i -lt $Items.Count; $i++) {
                            if ($Items[$i].Id -eq $item.Id) {
                                $Checked[$i] = $false
                            }
                        }
                    }
                    else { 
                        $fail++ 
                    }
                }
                Write-Host ""
                Write-GandiStatus -Status "OK" -Message "Done. Success: $ok  |  Skipped: $fail"
                Start-Sleep 3
                # Tidak return, tapi paksa loop render dari awal
                [Console]::Clear()
                continue
            }
        }
    }
}

# ─── MAIN LOOP ────────────────────────────────────────────────────────────────

while ($true) {
    [Console]::Clear()
    Set-GandiConsole -Title "GANDIWIN :: 01 REMOVE BLOATWARE"
    Show-GandiHeader -Title "01 REMOVE BLOATWARE"
    Write-Host ""
    Write-Host "  [1] Bloatware          " -NoNewline -ForegroundColor Cyan
    Write-Host "  Remove UWP apps + shell tweaks" -ForegroundColor DarkGray
    Write-Host "  [2] Software           " -NoNewline -ForegroundColor Cyan
    Write-Host "  Uninstall Win32 / MSI programs" -ForegroundColor DarkGray
    Write-Host "  [3] Defender           " -NoNewline -ForegroundColor Yellow
    Write-Host "  Disable Defender features (use with caution)" -ForegroundColor DarkGray
    Write-Host "  [4] MS Edge            " -NoNewline -ForegroundColor Yellow
    Write-Host "  Disable / uninstall Microsoft Edge" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [Q] Exit" -ForegroundColor DarkGray

    $c = (Read-Host "`n  CMD").ToUpper()
    switch ($c) {
        '1' {
            $list = Get-BloatwareList
            Write-ActivityLog "MENU: Bloatware ($($list.Count) items)"
            Invoke-ChecklistUI "BLOATWARE" $list "Remove"
        }
        '2' {
            Write-GandiStatus -Status "WAIT" -Message "Scanning installed Win32 software..."
            $list = Get-SoftwareList
            Write-ActivityLog "MENU: Software ($($list.Count) items)"
            Invoke-ChecklistUI "SOFTWARE" $list "Uninstall"
        }
        '3' {
            Write-ActivityLog "MENU: Defender"
            Invoke-ChecklistUI "DEFENDER" (Get-DefenderList) "Apply"
        }
        '4' {
            Write-ActivityLog "MENU: MS Edge"
            Invoke-ChecklistUI "MS EDGE" (Get-EdgeList) "Apply"
        }
        'Q' { Invoke-GandiTypewriter -Text "CLOSING..." -DelayMs 10 -Color Red; Start-Sleep 1; exit }
    }
}
