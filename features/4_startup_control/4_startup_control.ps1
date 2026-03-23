# ============================================================================
# GANDIWIN v3.0 - FEATURE 04: STARTUP CONTROL
# ============================================================================
# Powerful startup management tool that touches all Windows startup locations
# Target: Windows 10/11 with PowerShell 5.1+
# ============================================================================

# WAJIB ada di setiap script utama (Rule 1.4)
$MinPSVersion = [Version]"5.1"
if ($PSVersionTable.PSVersion -lt $MinPSVersion) {
    Write-Host "[ERROR] PowerShell 5.1+ required!" -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    pause
    exit 1
}

# Resolve script directory
if ($PSScriptRoot -ne '') { $ScriptDir = $PSScriptRoot }
else { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }

# Import UI Module
$UIModule = "$ScriptDir\..\..\modules\GandiWinUI.psm1"
if (Test-Path $UIModule) { Import-Module $UIModule -Force }

# Setup logging
$LogFile = "$ScriptDir\..\..\logs\menu.log"
if (!(Test-Path (Split-Path $LogFile))) { New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null }

function Write-ActivityLog {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMsg = "[$Timestamp] [$Level] [4_STARTUP_CTRL] $Message"
    try { Add-Content -Path $LogFile -Value $LogMsg -ErrorAction SilentlyContinue } catch {}
}

# ============================================================================
# ADMIN CHECK
# ============================================================================
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================================================
# STARTUP LOCATIONS REGISTRY PATHS
# ============================================================================
$StartupLocations = @(
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Scope = "Machine"; Type = "Registry"},
    @{Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Scope = "Machine"; Type = "Registry"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Scope = "User"; Type = "Registry"},
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"; Scope = "Machine"; Type = "Registry"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"; Scope = "User"; Type = "Registry"},
    @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellServiceObjects"; Scope = "Machine"; Type = "Registry"},
    @{Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellServiceObjects"; Scope = "User"; Type = "Registry"}
)

$StartupFolders = @(
    @{Path = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"; Scope = "All Users"; Type = "Folder"},
    @{Path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"; Scope = "Current User"; Type = "Folder"}
)

# ============================================================================
# GATHER ALL STARTUP ITEMS
# ============================================================================
function Get-AllStartupItems {
    $Items = @()

    # Registry Run keys
    foreach ($Loc in $StartupLocations) {
        try {
            $RegItems = Get-ItemProperty -Path $Loc.Path -ErrorAction SilentlyContinue
            if ($RegItems) {
                $RegItems.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS|Default' } | ForEach-Object {
                    $Items += [PSCustomObject]@{
                        Name        = $_.Name
                        Command     = $_.Value
                        Location    = $Loc.Path
                        Scope       = $Loc.Scope
                        Type        = $Loc.Type
                        Enabled     = $true
                        Category    = Get-StartupCategory -Name $_.Name -Command $_.Value
                    }
                }
            }
        }
        catch {}
    }

    # Startup Folders
    foreach ($Folder in $StartupFolders) {
        try {
            if (Test-Path $Folder.Path) {
                $Files = Get-ChildItem -Path $Folder.Path -ErrorAction SilentlyContinue
                foreach ($File in $Files) {
                    $Items += [PSCustomObject]@{
                        Name        = $File.BaseName
                        Command     = $File.FullName
                        Location    = $Folder.Path
                        Scope       = $Folder.Scope
                        Type        = $Folder.Type
                        Enabled     = $true
                        Category    = Get-StartupCategory -Name $File.BaseName -Command $File.FullName
                    }
                }
            }
        }
        catch {}
    }

    # Scheduled Tasks (startup-related)
    try {
        $Tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
            $_.Triggers -like "*Logon*" -or $_.Triggers -like "*AtStartup*"
        }
        foreach ($Task in $Tasks) {
            $State = (Get-ScheduledTaskInfo -TaskName $Task.TaskName -TaskPath $Task.TaskPath).LastRunResult
            $Items += [PSCustomObject]@{
                Name        = $Task.TaskName
                Command     = "schtasks /run /tn `"$($Task.TaskPath)$($Task.TaskName)`""
                Location    = "Task Scheduler\$($Task.TaskPath)"
                Scope       = "System"
                Type        = "ScheduledTask"
                Enabled     = ($Task.State -eq "Ready")
                Category    = Get-StartupCategory -Name $Task.TaskName -Command $Task.TaskPath
            }
        }
    }
    catch {}

    # Services (Auto-start)
    try {
        $Services = Get-CimInstance Win32_Service -Filter "StartMode='Auto'" -ErrorAction SilentlyContinue
        foreach ($Svc in $Services) {
            $Items += [PSCustomObject]@{
                Name        = $Svc.Name
                Command     = $Svc.PathName
                Location    = "Services.msc"
                Scope       = "System"
                Type        = "Service"
                Enabled     = ($Svc.State -eq "Running")
                Category    = Get-StartupCategory -Name $Svc.Name -Command $Svc.PathName
            }
        }
    }
    catch {}

    return $Items | Sort-Object Category, Name -Unique
}

function Get-StartupCategory {
    param([string]$Name, [string]$Command)

    $Critical = @("windows defender", "security health", "antimalware", "msascuil", "msmpeng")
    $System = @("runtimebroker", "ctfmon", "sideloading", "microsoft", "windows", "system", "service", "host")
    $Gaming = @("nvidia", "amd", "intel", "steam", "epic", "origin", "uplay", "battle", "razer", "logitech", "corsair")
    $Cloud = @("onedrive", "dropbox", "google drive", "icloud", "box")
    $Browser = @("chrome", "firefox", "edge", "opera", "brave", "browser")
    $Communication = @("discord", "teams", "skype", "zoom", "slack", "telegram", "whatsapp")
    $Media = @("spotify", "vlc", "itunes", "music", "video", "media")

    $LowerName = $Name.ToLower()
    $LowerCmd = $Command.ToLower()
    $Combined = "$LowerName $LowerCmd"

    if ($Critical | Where-Object { $Combined -like "*$_*" }) { return "CRITICAL" }
    if ($System | Where-Object { $Combined -like "*$_*" }) { return "SYSTEM" }
    if ($Gaming | Where-Object { $Combined -like "*$_*" }) { return "GAMING" }
    if ($Cloud | Where-Object { $Combined -like "*$_*" }) { return "CLOUD" }
    if ($Browser | Where-Object { $Combined -like "*$_*" }) { return "BROWSER" }
    if ($Communication | Where-Object { $Combined -like "*$_*" }) { return "COMMUNICATION" }
    if ($Media | Where-Object { $Combined -like "*$_*" }) { return "MEDIA" }
    return "APPLICATION"
}

# ============================================================================
# DISABLE/ENABLE STARTUP ITEMS
# ============================================================================
function Disable-StartupItem {
    param($Item)

    try {
        if ($Item.Type -eq "Registry") {
            # Rename value with _DISABLED_ prefix instead of deleting
            $CurrentVal = Get-ItemProperty -Path $Item.Location -Name $Item.Name -ErrorAction Stop
            $DisabledName = "_DISABLED_$($Item.Name)"
            Rename-ItemProperty -Path $Item.Location -Name $Item.Name -NewName $DisabledName -Force
            Write-ActivityLog "DISABLED: $($Item.Name) at $($Item.Location)" "OK"
            return $true
        }
        elseif ($Item.Type -eq "Folder") {
            # Move to disabled folder
            $DisabledFolder = "$PSScriptRoot\DisabledStartup"
            if (!(Test-Path $DisabledFolder)) { New-Item -ItemType Directory -Path $DisabledFolder -Force | Out-Null }
            $SourceFile = $Item.Command
            $FileName = Split-Path $SourceFile -Leaf
            Move-Item -Path $SourceFile -Destination "$DisabledFolder\$FileName" -Force
            Write-ActivityLog "DISABLED: $($Item.Name) (moved to DisabledStartup)" "OK"
            return $true
        }
        elseif ($Item.Type -eq "ScheduledTask") {
            Disable-ScheduledTask -TaskName $Item.Name -ErrorAction SilentlyContinue
            Write-ActivityLog "DISABLED: Scheduled Task $($Item.Name)" "OK"
            return $true
        }
        elseif ($Item.Type -eq "Service") {
            Set-Service -Name $Item.Name -StartupType Disabled -ErrorAction SilentlyContinue
            Stop-Service -Name $Item.Name -Force -ErrorAction SilentlyContinue
            Write-ActivityLog "DISABLED: Service $($Item.Name)" "OK"
            return $true
        }
    }
    catch {
        Write-ActivityLog "FAILED to disable $($Item.Name): $($_.Exception.Message)" "FAIL"
        return $false
    }
    return $false
}

function Enable-StartupItem {
    param($Item)

    try {
        if ($Item.Type -eq "Registry") {
            # Check for disabled version
            $DisabledName = "_DISABLED_$($Item.Name)"
            $Props = Get-ItemProperty -Path $Item.Location -ErrorAction SilentlyContinue
            if ($Props.$DisabledName) {
                Rename-ItemProperty -Path $Item.Location -Name $DisabledName -NewName $Item.Name -Force
                Write-ActivityLog "ENABLED: $($Item.Name) at $($Item.Location)" "OK"
                return $true
            }
            # If original exists but item shows as disabled, it might be in a different state
            Write-ActivityLog "Item $($Item.Name) may already be enabled" "INFO"
            return $false
        }
        elseif ($Item.Type -eq "Folder") {
            # Check disabled folder
            $DisabledFolder = "$PSScriptRoot\DisabledStartup"
            if (Test-Path $DisabledFolder) {
                $FileName = Split-Path $Item.Command -Leaf
                $DisabledFile = Get-ChildItem -Path $DisabledFolder -Filter $FileName -ErrorAction SilentlyContinue
                if ($DisabledFile) {
                    $TargetFolder = $Item.Location
                    Move-Item -Path $DisabledFile.FullName -Destination "$TargetFolder\$FileName" -Force
                    Write-ActivityLog "ENABLED: $($Item.Name) (restored from DisabledStartup)" "OK"
                    return $true
                }
            }
            return $false
        }
        elseif ($Item.Type -eq "ScheduledTask") {
            Enable-ScheduledTask -TaskName $Item.Name -ErrorAction SilentlyContinue
            Write-ActivityLog "ENABLED: Scheduled Task $($Item.Name)" "OK"
            return $true
        }
        elseif ($Item.Type -eq "Service") {
            Set-Service -Name $Item.Name -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $Item.Name -ErrorAction SilentlyContinue
            Write-ActivityLog "ENABLED: Service $($Item.Name)" "OK"
            return $true
        }
    }
    catch {
        Write-ActivityLog "FAILED to enable $($Item.Name): $($_.Exception.Message)" "FAIL"
        return $false
    }
    return $false
}

# ============================================================================
# QUICK TWEAKS - POWER PRESETS
# ============================================================================
function Invoke-MaxPerformanceTweak {
    Write-GandiStatus -Status "WAIT" -Message "Applying MAXIMUM PERFORMANCE startup profile..."
    Start-Sleep -Milliseconds 500

    $Disabled = 0
    $Items = Get-AllStartupItems

    foreach ($Item in $Items) {
        if ($Item.Category -in @("CLOUD", "MEDIA", "BROWSER", "COMMUNICATION", "APPLICATION", "GAMING")) {
            if ($Item.Enabled) {
                Disable-StartupItem -Item $Item | Out-Null
                $Disabled++
            }
        }
    }

    Write-GandiStatus -Status "OK" -Message "Disabled $Disabled non-essential startup items"
    Write-ActivityLog "MAX PERFORMANCE: Disabled $Disabled startup items" "OK"
    Read-Host "  Press ENTER to continue" | Out-Null
}

function Invoke-GamingModeTweak {
    Write-GandiStatus -Status "WAIT" -Message "Applying GAMING MODE startup profile..."
    Start-Sleep -Milliseconds 500

    $Disabled = 0
    $Items = Get-AllStartupItems

    foreach ($Item in $Items) {
        if ($Item.Category -in @("CLOUD", "MEDIA", "BROWSER", "COMMUNICATION", "APPLICATION")) {
            if ($Item.Enabled) {
                Disable-StartupItem -Item $Item | Out-Null
                $Disabled++
            }
        }
    }

    Write-GandiStatus -Status "OK" -Message "Disabled $Disabled gaming-unfriendly startup items"
    Write-ActivityLog "GAMING MODE: Disabled $Disabled startup items" "OK"
    Read-Host "  Press ENTER to continue" | Out-Null
}

function Invoke-MinimalTweak {
    Write-GandiStatus -Status "WAIT" -Message "Applying MINIMAL startup profile (safe)..."
    Start-Sleep -Milliseconds 500

    $Disabled = 0
    $Items = Get-AllStartupItems

    foreach ($Item in $Items) {
        if ($Item.Category -in @("CLOUD", "MEDIA", "APPLICATION")) {
            if ($Item.Enabled) {
                Disable-StartupItem -Item $Item | Out-Null
                $Disabled++
            }
        }
    }

    Write-GandiStatus -Status "OK" -Message "Disabled $Disabled optional startup items"
    Write-ActivityLog "MINIMAL MODE: Disabled $Disabled startup items" "OK"
    Read-Host "  Press ENTER to continue" | Out-Null
}

function Restore-AllDisabled {
    Write-GandiStatus -Status "WARN" -Message "Restoring ALL disabled startup items..."
    Start-Sleep -Milliseconds 500

    $Restored = 0
    $Items = Get-AllStartupItems

    # Restore registry items
    foreach ($Loc in $StartupLocations) {
        try {
            $Props = Get-ItemProperty -Path $Loc.Path -ErrorAction SilentlyContinue
            if ($Props) {
                $DisabledProps = $Props.PSObject.Properties | Where-Object { $_.Name -like "_DISABLED_*" }
                foreach ($Prop in $DisabledProps) {
                    $OriginalName = $Prop.Name -replace "_DISABLED_", ""
                    Rename-ItemProperty -Path $Loc.Path -Name $Prop.Name -NewName $OriginalName -Force
                    $Restored++
                }
            }
        }
        catch {}
    }

    # Restore folder items
    $DisabledFolder = "$PSScriptRoot\DisabledStartup"
    if (Test-Path $DisabledFolder) {
        $Files = Get-ChildItem -Path $DisabledFolder -ErrorAction SilentlyContinue
        foreach ($File in $Files) {
            # Find original location
            foreach ($Folder in $StartupFolders) {
                if (Test-Path $Folder.Path) {
                    Move-Item -Path $File.FullName -Destination "$($Folder.Path)\$($File.Name)" -Force
                    $Restored++
                    break
                }
            }
        }
        Remove-Item -Path $DisabledFolder -Force -ErrorAction SilentlyContinue
    }

    Write-GandiStatus -Status "OK" -Message "Restored $Restored startup items"
    Write-ActivityLog "RESTORE ALL: Restored $Restored startup items" "OK"
    Read-Host "  Press ENTER to continue" | Out-Null
}

# ============================================================================
# INTERACTIVE LIST UI
# ============================================================================
function Invoke-StartupListUI {
    param([string]$FilterCategory)

    $Items = Get-AllStartupItems
    if ($FilterCategory) {
        $Items = $Items | Where-Object { $_.Category -eq $FilterCategory }
    }

    if ($Items.Count -eq 0) {
        Write-GandiStatus -Status "INFO" -Message "No startup items found in this category."
        Start-Sleep -Seconds 2
        return
    }

    $Cursor = 0
    $Vis = 18
    $Top = 0
    $ActionMode = $false

    [Console]::Clear()

    while ($true) {
        if ($Cursor -lt $Top) { $Top = $Cursor }
        if ($Cursor -ge ($Top + $Vis)) { $Top = $Cursor - $Vis + 1 }

        [Console]::SetCursorPosition(0, 0)
        Show-GandiHeader -Title "04 STARTUP CONTROL"

        $EnabledCount = ($Items | Where-Object { $_.Enabled }).Count
        $DisabledCount = ($Items | Where-Object { $_.Enabled -eq $false }).Count

        Show-GandiKeyValue "Total Items" $Items.Count "White" "Cyan"
        Show-GandiKeyValue "Enabled" $EnabledCount "White" "Green"
        Show-GandiKeyValue "Disabled" $DisabledCount "White" "Red"
        Write-Host ""

        $slice = $Items[$Top..([Math]::Min($Top + $Vis - 1, $Items.Count - 1))]
        for ($i = 0; $i -lt $slice.Count; $i++) {
            $idx = $Top + $i
            $Item = $Items[$idx]

            $statusIcon = if ($Item.Enabled) { "[+]" } else { "[-]" }
            $statusColor = if ($Item.Enabled) { "Green" } else { "Red" }

            $catColor = switch ($Item.Category) {
                "CRITICAL" { "DarkRed" }
                "SYSTEM" { "DarkYellow" }
                "GAMING" { "Yellow" }
                "CLOUD" { "Cyan" }
                "BROWSER" { "Blue" }
                "COMMUNICATION" { "Magenta" }
                "MEDIA" { "DarkMagenta" }
                default { "White" }
            }

            $namePad = $Item.Name.PadRight(25).Substring(0, 25)
            $locPad = $Item.Type.PadRight(12).Substring(0, 12)

            $bg = if ($idx -eq $Cursor) { "DarkCyan" } else { "Black" }

            Write-Host "  " -NoNewline
            Write-Host "$statusIcon " -NoNewline -ForegroundColor $statusColor
            Write-Host "$namePad " -NoNewline -ForegroundColor White -BackgroundColor $bg
            Write-Host "$locPad " -NoNewline -ForegroundColor $catColor -BackgroundColor $bg
            Write-Host $Item.Category -ForegroundColor Gray -BackgroundColor $bg
        }

        Write-Host ""
        Write-Host "  NAV: UP/DOWN | TOGGLE: SPACE | ENABLE: E | DISABLE: D | REFRESH: R | ESC: BACK" -ForegroundColor DarkGray

        $k = [Console]::ReadKey($true)
        switch ($k.Key) {
            'UpArrow' { if ($Cursor -gt 0) { $Cursor-- } }
            'DownArrow' { if ($Cursor -lt ($Items.Count - 1)) { $Cursor++ } }
            'Spacebar' {
                $Item = $Items[$Cursor]
                if ($Item.Category -in @("CRITICAL", "SYSTEM")) {
                    Write-GandiStatus -Status "WARN" -Message "Cannot modify $([char]0x00B7) items!"
                    Start-Sleep -Milliseconds 800
                }
                else {
                    if ($Item.Enabled) { Disable-StartupItem -Item $Item }
                    else { Enable-StartupItem -Item $Item }
                    $Items = Get-AllStartupItems
                    if ($FilterCategory) { $Items = $Items | Where-Object { $_.Category -eq $FilterCategory } }
                }
            }
            'E' {
                $Item = $Items[$Cursor]
                if ($Item.Enabled -eq $false) {
                    Enable-StartupItem -Item $Item
                    $Items = Get-AllStartupItems
                    if ($FilterCategory) { $Items = $Items | Where-Object { $_.Category -eq $FilterCategory } }
                }
            }
            'D' {
                $Item = $Items[$Cursor]
                if ($Item.Enabled) {
                    if ($Item.Category -in @("CRITICAL", "SYSTEM")) {
                        Write-GandiStatus -Status "WARN" -Message "Cannot disable $([char]0x00B7) items!"
                        Start-Sleep -Milliseconds 800
                    }
                    else {
                        Disable-StartupItem -Item $Item
                        $Items = Get-AllStartupItems
                        if ($FilterCategory) { $Items = $Items | Where-Object { $_.Category -eq $FilterCategory } }
                    }
                }
            }
            'R' { $Items = Get-AllStartupItems; if ($FilterCategory) { $Items = $Items | Where-Object { $_.Category -eq $FilterCategory } } }
            'Escape' { return }
        }
    }
}

# ============================================================================
# MAIN MENU
# ============================================================================
while ($true) {
    Set-GandiConsole -Title "GANDIWIN :: STARTUP CONTROL"
    Show-GandiHeader -Title "04 STARTUP CONTROL"

    Write-ActivityLog "Startup Control module launched"

    # Admin status
    $IsAdmin = Test-IsAdmin
    $AdminText = if ($IsAdmin) { "YES - Full access" } else { "NO - Limited functionality" }
    $AdminColor = if ($IsAdmin) { "Green" } else { "Red" }
    Show-GandiKeyValue "Administrator" $AdminText "White" $AdminColor

    # Quick stats
    $AllItems = Get-AllStartupItems
    $EnabledCount = ($AllItems | Where-Object { $_.Enabled }).Count
    $DisabledCount = ($AllItems | Where-Object { $_.Enabled -eq $false }).Count

    Write-Host ""
    Show-GandiBox -Title "STARTUP OVERVIEW"
    Show-GandiKeyValue "Total Startup Items" $AllItems.Count "White" "Cyan"
    Show-GandiKeyValue "Currently Enabled" $EnabledCount "White" "Green"
    Show-GandiKeyValue "Currently Disabled" $DisabledCount "White" "Red"

    Write-Host ""
    Write-Host "  [ QUICK TWEAKS - ONE CLICK OPTIMIZATION ]" -ForegroundColor Yellow
    Write-Host "  [1] MAXIMUM PERFORMANCE (Aggressive - disable most apps)" -ForegroundColor White
    Write-Host "  [2] GAMING MODE (Keep gaming apps, disable others)" -ForegroundColor White
    Write-Host "  [3] MINIMAL (Safe - disable only optional apps)" -ForegroundColor White
    Write-Host "  [4] RESTORE ALL (Re-enable everything)" -ForegroundColor White
    Write-Host ""
    Write-Host "  [ MANUAL CONTROL ]" -ForegroundColor Yellow
    Write-Host "  [5] View All Startup Items" -ForegroundColor White
    Write-Host "  [6] View Critical Items Only" -ForegroundColor DarkRed
    Write-Host "  [7] View System Items Only" -ForegroundColor DarkYellow
    Write-Host "  [8] View Application Items Only" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [9] REFRESH SCAN" -ForegroundColor Yellow
    Write-Host "  [0] BACK TO MENU" -ForegroundColor Yellow
    Write-Host ""

    $Choice = Read-Host "  AWAITING COMMAND"

    Write-Host ""
    switch ($Choice) {
        '1' { Invoke-MaxPerformanceTweak }
        '2' { Invoke-GamingModeTweak }
        '3' { Invoke-MinimalTweak }
        '4' { Restore-AllDisabled }
        '5' { Invoke-StartupListUI }
        '6' { Invoke-StartupListUI -FilterCategory "CRITICAL" }
        '7' { Invoke-StartupListUI -FilterCategory "SYSTEM" }
        '8' { Invoke-StartupListUI -FilterCategory "APPLICATION" }
        '9' { Write-GandiStatus -Status "INFO" -Message "Rescanning startup items..."; Start-Sleep -Seconds 1 }
        '0' {
            Write-ActivityLog "Startup Control module exited"
            Invoke-GandiTypewriter -Text "CLOSING STARTUP CONTROL..." -DelayMs 10 -Color Red
            Start-Sleep -Seconds 1
            exit
        }
        default { Write-GandiStatus -Status "FAIL" -Message "Invalid command."; Start-Sleep -Seconds 1 }
    }
}
