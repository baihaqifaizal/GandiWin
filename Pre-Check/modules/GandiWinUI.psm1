<#
.SYNOPSIS
    GandiWinUI - World-class Hacker UI Template for GandiWin v3.0
.DESCRIPTION
    Provides aesthetically pleasing formatting functions for PowerShell CLI scripts.
    Strictly follows ATURAN.md (No unicode emoji, ASCII/Box drawing only).
#>

$FontSnippet = @"
using System;
using System.Runtime.InteropServices;
public static class GandiTerminal {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CONSOLE_FONT_INFO_EX {
        public uint cbSize;
        public uint nFont;
        public short dwFontSizeX;
        public short dwFontSizeY;
        public int FontFamily;
        public int FontWeight;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string FaceName;
    }
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr GetStdHandle(int nStdHandle);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern bool GetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFO_EX lpConsoleCurrentFontEx);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool SetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFO_EX lpConsoleCurrentFontEx);
    public static void SetFont() {
        IntPtr hnd = GetStdHandle(-11);
        if (hnd != IntPtr.Zero) {
            CONSOLE_FONT_INFO_EX font = new CONSOLE_FONT_INFO_EX();
            font.cbSize = (uint)Marshal.SizeOf(font);
            if (GetCurrentConsoleFontEx(hnd, false, ref font)) {
                font.FaceName = "Consolas";
                font.dwFontSizeX = 0;
                font.dwFontSizeY = 18;
                SetCurrentConsoleFontEx(hnd, false, ref font);
            }
        }
    }
}
"@
try { Add-Type -TypeDefinition $FontSnippet -ErrorAction SilentlyContinue } catch {}

function Set-GandiConsole {
    param(
        [string]$Title = "GANDIWIN TERMINAL"
    )
    try { [GandiTerminal]::SetFont() } catch {}
    [Console]::Title = $Title
    [Console]::BackgroundColor = "Black"
    [Console]::ForegroundColor = "White"
    Clear-Host
}

function Show-GandiBanner {
    $Banner = @"
  ██████╗  █████╗ ███╗   ██╗██████╗ ██╗██╗    ██╗██╗███╗   ██╗
 ██╔════╝ ██╔══██╗████╗  ██║██╔══██╗██║██║    ██║██║████╗  ██║
 ██║  ███╗███████║██╔██╗ ██║██║  ██║██║██║ █╗ ██║██║██╔██╗ ██║
 ██║   ██║██╔══██║██║╚██╗██║██║  ██║██║██║███╗██║██║██║╚██╗██║
 ╚██████╔╝██║  ██║██║ ╚████║██████╔╝██║╚███╔███╔╝██║██║ ╚████║
  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝ ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝
"@
    Write-Host ""
    foreach ($Line in $Banner -split "`r`n") {
        Write-Host $Line -ForegroundColor Cyan
    }
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host "  >> SYSTEM OVERRIDE INITIATED <<                 v3.0 POWER EDITION" -ForegroundColor DarkGray
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-GandiHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "  ██==========================================================██" -ForegroundColor DarkCyan
    Write-Host "  ||" -NoNewline -ForegroundColor DarkCyan
    Write-Host " $Title ".PadRight(58) -NoNewline -ForegroundColor Yellow
    Write-Host "||" -ForegroundColor DarkCyan
    Write-Host "  ██==========================================================██" -ForegroundColor DarkCyan
    Write-Host ""
}
function Write-GandiStatus {
    param(
        [ValidateSet("OK", "FAIL", "WARN", "INFO", "WAIT")]
        [string]$Status,
        [string]$Message
    )
    $ColorMap = @{
        "OK"   = "Green"
        "FAIL" = "Red"
        "WARN" = "Yellow"
        "INFO" = "Cyan"
        "WAIT" = "DarkGray"
    }
    
    $StatusText = ""
    switch ($Status) {
        "OK" { $StatusText = "[  OK  ]" }
        "FAIL" { $StatusText = "[ FAIL ]" }
        "WARN" { $StatusText = "[ WARN ]" }
        "INFO" { $StatusText = "[ INFO ]" }
        "WAIT" { $StatusText = "[ WAIT ]" }
    }
    
    $Color = $ColorMap[$Status]
    Write-Host "  $StatusText " -NoNewline -ForegroundColor $Color
    Write-Host $Message -ForegroundColor White
}

function Invoke-GandiTypewriter {
    param(
        [string]$Text,
        [int]$DelayMs = 15,
        [string]$Color = "Cyan"
    )
    Write-Host "  [*] " -NoNewline -ForegroundColor DarkGray
    foreach ($Char in $Text.ToCharArray()) {
        Write-Host $Char -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $DelayMs
    }
    Write-Host ""
}

function Show-GandiBox {
    param(
        [string]$Title,
        [string]$Color = "DarkCyan"
    )
    $Width = 76
    $TopLine = "  ╔" + ("═" * ($Width - 4)) + "╗"
    $MidLine = "  ║ " + $Title.PadRight($Width - 6) + " ║"
    $BotLine = "  ╚" + ("═" * ($Width - 4)) + "╝"
    
    Write-Host ""
    Write-Host $TopLine -ForegroundColor $Color
    Write-Host $MidLine -ForegroundColor Yellow
    Write-Host $BotLine -ForegroundColor $Color
}

function Show-GandiKeyValue {
    param(
        [string]$Key,
        [string]$Value,
        [string]$KeyColor = "White",
        [string]$ValueColor = "Cyan"
    )
    $PaddedKey = $Key.PadRight(20)
    Write-Host "    $PaddedKey : " -NoNewline -ForegroundColor $KeyColor
    Write-Host $Value -ForegroundColor $ValueColor
}

Export-ModuleMember -Function Set-GandiConsole, Show-GandiBanner, Show-GandiHeader, Write-GandiStatus, Invoke-GandiTypewriter, Show-GandiBox, Show-GandiKeyValue
