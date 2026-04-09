@echo off
title GANDIWIN PRE-CHECK
color 0B
setlocal enabledelayedexpansion

:: ==============================
:: CEK ADMIN
:: ==============================
net session >nul 2>&1
if %errorLevel% == 0 (set admin=YES) else (set admin=NO)

:MENU
cls
echo ==============================================================
echo              GANDIWIN PRE-CHECK
echo ==============================================================
if "%admin%"=="YES" (
    echo Status: ADMIN MODE
) else (
    echo Status: LIMITED MODE ^(Run as Admin disarankan^)
)
echo ==============================================================
echo.
echo [1] SYSTEM INFO (System Info + Battery + Network + Thermal)
echo [2] MONITOR (Task Manager + Resource Monitor + Performance Monitor + Event Viewer)
echo [3] CONFIGURATION (Device Manager + Services + msconfig + Pagefile + Disk Management)
echo [4] SFC Scan
echo [5] DISM Repair
echo [6] CPU Benchmark
echo [7] Driver Error Search
echo [8] Check Disk Full (Restart)
echo [9] Memory Diagnostic (Restart)
echo [10] Advanced Boot Menu (Restart)
echo.
echo ==============================================================
echo [0] EXIT
echo.
set /p c=Select option: 

if "%c%"=="1" goto PS1_CHECK
if "%c%"=="2" goto OPENMONITOR
if "%c%"=="3" goto OPENCONFIG
if "%c%"=="4" goto SFC
if "%c%"=="5" goto DISM
if "%c%"=="6" goto CPUBENCH
if "%c%"=="7" goto DRIVERCHECK
if "%c%"=="8" goto CHK
if "%c%"=="9" goto MEMDIAG
if "%c%"=="10" goto ADVBOOT
if "%c%"=="0" goto END

echo Pilihan tidak valid!
pause
goto MENU

:: ==============================
:: PS1 CHECK - Try system_check.ps1 first
:: ==============================
:PS1_CHECK
set "ps1script=%~dp0system_check.ps1"
if not exist "%ps1script%" goto FULLINFO

powershell -NoProfile -Command "exit ($PSVersionTable.PSVersion -lt [Version]'5.1')" 2>nul
if %errorlevel% neq 0 goto FULLINFO

echo Launching GandiWin System Check (PowerShell)...
start "GandiWin System Check" powershell -NoProfile -ExecutionPolicy Bypass -File "%ps1script%"
goto MENU

:: ==============================
:: 1. FULLINFO (Fallback CMD version matching PS1 output)
:: ==============================
:FULLINFO
cls
echo ==============================================================
echo   GANDIWIN SYSTEM CHECK [CMD FALLBACK]
echo   Generated: %DATE% %TIME%
echo ==============================================================
echo.

echo Mengumpulkan informasi sistem...
echo.

:: --- OVERVIEW ---
echo [OVERVIEW]
for /f "tokens=2 delims==" %%A in ('wmic computersystem get Name /value ^| find "="') do set CompName=%%A
for /f "tokens=2 delims==" %%A in ('wmic computersystem get Manufacturer /value ^| find "="') do set CompManufacturer=%%A
for /f "tokens=2 delims==" %%A in ('wmic computersystem get Model /value ^| find "="') do set CompModel=%%A
echo   Computer Name : %CompName%
echo   Manufacturer  : %CompManufacturer%
echo   Model         : %CompModel%
echo.

:: --- MOTHERBOARD ---
echo [MOTHERBOARD]
for /f "tokens=2 delims==" %%A in ('wmic baseboard get Manufacturer /value ^| find "="') do set MBManufacturer=%%A
for /f "tokens=2 delims==" %%A in ('wmic baseboard get Product /value ^| find "="') do set MBModel=%%A
for /f "tokens=2 delims==" %%A in ('wmic bios get SMBIOSBIOSVersion /value ^| find "="') do set BIOSVersion=%%A
for /f "tokens=2 delims==" %%A in ('wmic bios get ReleaseDate /value ^| find "="') do set BIOSDateRaw=%%A
set BIOSDate=%BIOSDateRaw:~0,8%
echo   Manufacturer  : %MBManufacturer%
echo   Model         : %MBModel%
echo   BIOS Date     : %BIOSDate%
echo   BIOS Version  : %BIOSVersion%
echo   Boot Type     : N/A (requires PowerShell)
echo   TPM Chip      : N/A (requires PowerShell)
echo.

:: --- OPERATING SYSTEM ---
echo [OPERATING SYSTEM]
for /f "tokens=2 delims==" %%A in ('wmic os get Caption /value ^| find "="') do set OSCaption=%%A
for /f "tokens=2 delims==" %%A in ('wmic os get BuildNumber /value ^| find "="') do set OSBuild=%%A
for /f "tokens=2 delims==" %%A in ('wmic os get OSArchitecture /value ^| find "="') do set OSArch=%%A
echo   OS            : %OSCaption% (%OSArch%) Build %OSBuild%
echo   Boot Mode     : N/A (requires PowerShell)
echo   Secure Boot   : N/A (requires PowerShell)
echo   HVCI          : N/A (requires PowerShell)
echo.

:: --- PROCESSOR ---
echo [PROCESSOR]
for /f "tokens=2 delims==" %%A in ('wmic cpu get Name /value ^| find "="') do set CPUName=%%A
for /f "tokens=2 delims==" %%A in ('wmic cpu get NumberOfCores /value ^| find "="') do set CPUCores=%%A
for /f "tokens=2 delims==" %%A in ('wmic cpu get NumberOfLogicalProcessors /value ^| find "="') do set CPUThreads=%%A
for /f "tokens=2 delims==" %%A in ('wmic cpu get MaxClockSpeed /value ^| find "="') do set CPUMaxClock=%%A
for /f "tokens=2 delims==" %%A in ('wmic cpu get CurrentClockSpeed /value ^| find "="') do set CPUCurrentClock=%%A
set CPUVendor=Unknown
echo %CPUName% | findstr /I "Intel" >nul && set CPUVendor=Intel
echo %CPUName% | findstr /I "AMD" >nul && set CPUVendor=AMD

:: Base Clock = CurrentClockSpeed (base speed Windows reports)
set /a CPUBaseGHzInt=%CPUCurrentClock% / 1000
set /a CPUBaseGHzDec=(%CPUCurrentClock% %% 1000) / 100

:: Max Turbo = MaxClockSpeed (hardware capability)
set /a CPUMaxGHzInt=%CPUMaxClock% / 1000
set /a CPUMaxGHzDec=(%CPUMaxClock% %% 1000) / 100

:: Real-time CPU freq using % Processor Performance (approximation via typeperf)
set CPURealGHzInt=%CPUBaseGHzInt%
set CPURealGHzDec=%CPUBaseGHzDec%
for /f "tokens=2 delims=." %%A in ('typeperf "\Processor Information(_Total)\%% Processor Performance" -sc 1 2^>nul ^| findstr /V "Path" ^| findstr /V "error"') do (
    set PerfPct=%%A
    if defined PerfPct (
        :: Remove quotes if any
        set PerfPct=!PerfPct:"=!
        :: Calculate: BaseClock * (PerfPct / 100)
        set /a PerfInt=!PerfPct:~0,-2!
        set /a CPURealFreq=%CPUCurrentClock% * !PerfInt! / 100
        set /a CPURealGHzInt=!CPURealFreq! / 1000
        set /a CPURealGHzDec=(!CPURealFreq! %% 1000) / 100
    )
)

:: Boost Mode Detection (parse powercfg output using GUID query)
set BoostModeAC=Unknown
set BoostModeDC=Unknown

:: Get active power plan GUID
for /f "tokens=3" %%A in ('powercfg /getactivescheme ^| findstr /C:"GUID:"') do set ActivePlanGUID=%%A

if defined ActivePlanGUID (
    :: Query boost policy using GUIDs
    set "subGroup=54533251-82be-4824-96c1-47b60b740d00"
    set "boostPolicy=be337238-0d82-4146-a960-4f3749d470c7"
    
    :: Parse AC Setting
    for /f "tokens=8" %%A in ('powercfg /query %ActivePlanGUID% %subGroup% %boostPolicy% 2^>nul ^| findstr /C:"Current AC Power Setting Index"') do set acVal=%%A
    if defined acVal (
        if "!acVal!"=="0x00000000" set BoostModeAC=Disabled
        if "!acVal!"=="0x00000001" set BoostModeAC=Enabled
        if "!acVal!"=="0x00000002" set BoostModeAC=Aggressive
    )
    
    :: Parse DC Setting
    for /f "tokens=8" %%A in ('powercfg /query %ActivePlanGUID% %subGroup% %boostPolicy% 2^>nul ^| findstr /C:"Current DC Power Setting Index"') do set dcVal=%%A
    if defined dcVal (
        if "!dcVal!"=="0x00000000" set BoostModeDC=Disabled
        if "!dcVal!"=="0x00000001" set BoostModeDC=Enabled
        if "!dcVal!"=="0x00000002" set BoostModeDC=Aggressive
    )
)

echo   Model         : %CPUName%
echo   Vendor        : %CPUVendor%
echo   Cores/Threads : %CPUCores% / %CPUThreads%
echo   Base Clock    : %CPUBaseGHzInt%.%CPUBaseGHzDec% GHz
echo   Max Turbo     : %CPUMaxGHzInt%.%CPUMaxGHzDec% GHz (Available)
echo   Current Clock : %CPURealGHzInt%.%CPURealGHzDec% GHz (Real-time)
echo   Boost Mode AC : %BoostModeAC%
echo   Boost Mode DC : %BoostModeDC%
echo   TDP           : N/A
echo.

:: --- RAM ---
echo [RAM INFO]
for /f "tokens=2 delims==" %%A in ('wmic os get TotalVisibleMemorySize /value ^| find "="') do set RAMTotalKB=%%A
set /a RAMTotalGB=%RAMTotalKB% / 1048576
for /f "tokens=2 delims==" %%A in ('wmic os get FreePhysicalMemory /value ^| find "="') do set RAMFreeKB=%%A
set /a RAMFreeGB=%RAMFreeKB% / 1048576
set /a RAMUsedGB=%RAMTotalGB% - %RAMFreeGB%
if %RAMTotalGB% GTR 0 (set /a RAMUsage=%RAMUsedGB% * 100 / %RAMTotalGB%) else (set RAMUsage=0)
for /f "tokens=2 delims==" %%A in ('wmic memorychip get Speed /value ^| find "="') do set RAMSpeed=%%A
for /f %%A in ('wmic memorychip get BankLabel ^| find "BANK" /c') do set RAMModules=%%A
echo   Total RAM      : %RAMTotalGB% GB
echo   Used RAM       : %RAMUsedGB% GB
echo   Usage Rate     : %RAMUsage%%%
echo   Speed          : %RAMSpeed% MHz
echo   Modules        : %RAMModules%
echo.

:: --- VIRTUAL MEMORY ---
echo [VIRTUAL MEMORY]
for /f "tokens=2 delims==" %%A in ('wmic os get TotalVirtualMemorySize /value ^| find "="') do set VirtTotalKB=%%A
for /f "tokens=2 delims==" %%A in ('wmic os get FreeVirtualMemory /value ^| find "="') do set VirtFreeKB=%%A
set /a VirtTotalGB=%VirtTotalKB% / 1048576
set /a VirtUsedGB=(%VirtTotalKB% - %VirtFreeKB%) / 1048576
echo   Virtual Memory Total : %VirtTotalGB% GB
echo   Virtual Memory Used  : %VirtUsedGB% GB
echo.

:: --- PAGE FILE ---
echo [PAGE FILE CONFIGURATION]
wmic pagefileusage get Name,AllocatedBaseSize /format:table 2>nul | findstr /V "Name" | findstr "." >nul
if %errorlevel% equ 0 (
    for /f "tokens=1,2" %%A in ('wmic pagefileusage get Name^,AllocatedBaseSize /format:table ^| findstr ":"') do (
        echo   Page File        : %%A (%%B MB)
    )
) else (
    echo   Page File        : None / Disabled
)
echo.

:: --- GRAPHICS ---
echo [GRAPHICS]
for /f "tokens=2 delims==" %%A in ('wmic path win32_videocontroller get Name /value ^| find "="') do set GPUName=%%A
for /f "tokens=2 delims==" %%A in ('wmic path win32_videocontroller get DriverVersion /value ^| find "="') do set GPUDriver=%%A
for /f "tokens=2 delims==" %%A in ('wmic path win32_videocontroller get AdapterRAM /value ^| find "="') do set GPURAM=%%A
set /a GPUMEM=%GPURAM% / 1048576
set GPUType=Integrated
echo %GPUName% | findstr /I "RTX GTX" >nul && set GPUType=Discrete
echo %GPUName% | findstr /I "RX Vega" >nul && set GPUType=Discrete
echo   Model         : %GPUName%
echo   Driver Version: %GPUDriver%
echo   Type          : %GPUType%
echo   Memory        : %GPUMEM% MB
echo.

:: --- DISPLAY ---
echo [DISPLAY CONFIGURATION]
for /f "tokens=2 delims==" %%A in ('wmic path win32_videocontroller get CurrentHorizontalResolution^,CurrentVerticalResolution^,CurrentRefreshRate /value ^| find "="') do set DisplayData=%%A
for /f "tokens=1,2 delims=." %%A in ('wmic path win32_videocontroller get CurrentHorizontalResolution /value ^| find "="') do set HRes=%%B
for /f "tokens=1,2 delims=." %%A in ('wmic path win32_videocontroller get CurrentVerticalResolution /value ^| find "="') do set VRes=%%B
for /f "tokens=2 delims==" %%A in ('wmic path win32_videocontroller get CurrentRefreshRate /value ^| find "="') do set RefreshRaw=%%A
if defined HRes if defined VRes (
    echo   Resolution    : %HRes% x %VRes%
) else (
    echo   Resolution    : N/A
)
if defined RefreshRaw (
    set /a RefreshHz=%RefreshRaw% / 100
    echo   Refresh Rate  : %RefreshHz% Hz
) else (
    echo   Refresh Rate  : N/A
)
echo   GPU Model     : %GPUName%
echo.

:: --- STORAGE ---
echo [STORAGE]
:: Get disk health from PhysicalDisk (SMART)
wmic /namespace:\\root\Microsoft\Windows\Storage PATH MSFT_PhysicalDisk get HealthStatus^,MediaType /format:table 2>nul | findstr "." >nul
if %errorlevel% equ 0 (
    for /f "tokens=2 delims==" %%A in ('wmic /namespace:\\root\Microsoft\Windows\Storage PATH MSFT_PhysicalDisk get MediaType /value ^| find "="') do set DiskType=%%A
    for /f "tokens=2 delims==" %%A in ('wmic /namespace:\\root\Microsoft\Windows\Storage PATH MSFT_PhysicalDisk get HealthStatus /value ^| find "="') do set DiskHealth=%%A
    echo   Media Type     : %DiskType%
    echo   Physical Health: [ %DiskHealth% ]
) else (
    echo   Media Type     : Unknown
    echo   Physical Health: [ Unknown ]
)
echo.
for /f "tokens=1,2,3 delims= " %%A in ('wmic logicaldisk where "DriveType=3" get DeviceID^,FreeSpace^,Size /format:table ^| find ":"') do (
    set "DriveLetter=%%A"
    set "FreeSpace=%%B"
    set "TotalSize=%%C"
    if not "%%A"=="" (
        set /a FreeGB=%%B / 1073741824
        set /a TotalGB=%%C / 1073741824
        if !TotalGB! GTR 0 (set /a Percent=!FreeGB! * 100 / !TotalGB!) else (set Percent=0)
        echo   Drive %%A: !FreeGB! GB free of !TotalGB! GB (!Percent!%%)
    )
)
echo.

:: --- NETWORK ---
echo [NETWORK]
for /f "tokens=2 delims==" %%A in ('wmic nic where "NetEnabled=true" get Name /value ^| find "="') do (
    echo   Adapter       : %%A
)
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /C:"DNS Servers"') do (
    echo   DNS Servers   :%%A
    goto :DNSSkip
)
:DNSSkip
echo.

:: --- BATTERY ---
echo [BATTERY STATUS]
for /f "tokens=2 delims==" %%A in ('wmic path Win32_Battery get EstimatedChargeRemaining /value ^| find "="') do set BatteryCharge=%%A
for /f "tokens=2 delims==" %%A in ('wmic path Win32_Battery get BatteryStatus /value ^| find "="') do set BatteryStatus=%%A
if defined BatteryCharge (
    echo   Charge        : %BatteryCharge%%%
    echo   Status        : %BatteryStatus%
    
    :: Battery Wear Level
    set WearLevel=
    :: Method 1: WMI BatteryFullChargedCapacity + BatteryStaticData
    for /f "tokens=2 delims==" %%B in ('wmic /namespace:\\root\WMI PATH BatteryFullChargedCapacity get FullChargedCapacity /value 2^>nul ^| find "="') do set BattFull=%%B
    for /f "tokens=2 delims==" %%B in ('wmic /namespace:\\root\WMI PATH BatteryStaticData get DesignedCapacity /value 2^>nul ^| find "="') do set BattDesign=%%B
    if defined BattFull if defined BattDesign if !BattDesign! GTR 0 (
        set /a WearLevel=!BattFull! * 100 / !BattDesign!
    )
    
    :: Method 2: Fallback to Win32_PortableBattery (works better on Legacy Boot)
    if not defined WearLevel (
        for /f "tokens=2 delims==" %%B in ('wmic path Win32_PortableBattery get FullChargeCapacity /value 2^>nul ^| find "="') do set BattFull2=%%B
        for /f "tokens=2 delims==" %%B in ('wmic path Win32_PortableBattery get DesignCapacity /value 2^>nul ^| find "="') do set BattDesign2=%%B
        if defined BattFull2 if defined BattDesign2 if !BattDesign2! GTR 0 (
            set /a WearLevel=!BattFull2! * 100 / !BattDesign2!
        )
    )
    
    if defined WearLevel (
        echo   Health/Wear   : !WearLevel!%% (Full Cap vs Design Cap)
    ) else (
        echo   Health/Wear   : N/A
    )
) else (
    echo   Battery       : Not detected / Desktop system
)
echo.

:: --- THERMAL ---
echo [THERMAL INFO]
wmic /namespace:\\root\wmi PATH MSAcpi_ThermalZoneTemperature get CurrentTemperature 2>nul | findstr "[0-9]" >nul
if %errorlevel% equ 0 (
    for /f "tokens=2 delims==" %%A in ('wmic /namespace:\\root\wmi PATH MSAcpi_ThermalZoneTemperature get CurrentTemperature /value ^| find "="') do (
        set /a TempRaw=%%A / 10 - 273
        echo   Current Temp   : !TempRaw! C

        :: CPU Profile Detection
        for /f "tokens=2 delims==" %%B in ('wmic cpu get Name /value ^| find "="') do set CPUNameThermal=%%B

        set ThermalProfile=Standard/Desktop PC
        set ThermalSafeLimit=80.0 C
        set ThermalStatus=SANGAT AMAN
        set ThermalNote=Suhu optimal.

        :: Check Low Power (U/Y/G series, Pentium, Celeron)
        echo !CPUNameThermal! | findstr /R "[0-9]U [0-9]Y [0-9]G Athlon Pentium Celeron" >nul
        if !errorlevel! equ 0 (
            set ThermalProfile=Low Power ^(Ultrabook/Office^)
            set ThermalSafeLimit=85.0 C
            if !TempRaw! LSS 45 (set ThermalStatus=SANGAT AMAN & set ThermalNote=Suhu sangat baik.)
            if !TempRaw! GEQ 45 if !TempRaw! LSS 60 (set ThermalStatus=AMAN & set ThermalNote=Suhu wajar untuk kerja ringan.)
            if !TempRaw! GEQ 60 if !TempRaw! LSS 75 (set ThermalStatus=NORMAL & set ThermalNote=Suhu wajar saat multitasking.)
            if !TempRaw! GEQ 75 if !TempRaw! LSS 85 (set ThermalStatus=WASPADA & set ThermalNote=Mendekati batas maksimal laptop tipis.)
            if !TempRaw! GEQ 85 (set ThermalStatus=KRITIS & set ThermalNote=Bahaya Throttling! Cek kipas/pasta termal.)
        )

        :: Check High Performance (H/HS/HX/HK series)
        echo !CPUNameThermal! | findstr /R "[0-9]H [0-9]HS [0-9]HX [0-9]HK [0-9]XT" >nul
        if !errorlevel! equ 0 (
            set ThermalProfile=High Performance ^(Gaming/Creator^)
            set ThermalSafeLimit=95.0 C
            if !TempRaw! LSS 50 (set ThermalStatus=SANGAT AMAN & set ThermalNote=Sistem pendingin prima.)
            if !TempRaw! GEQ 50 if !TempRaw! LSS 65 (set ThermalStatus=AMAN & set ThermalNote=Suhu wajar untuk idle/ringan.)
            if !TempRaw! GEQ 65 if !TempRaw! LSS 85 (set ThermalStatus=NORMAL & set ThermalNote=Suhu optimal saat gaming/rendering.)
            if !TempRaw! GEQ 85 if !TempRaw! LSS 95 (set ThermalStatus=WASPADA & set ThermalNote=Sistem bekerja ekstra keras.)
            if !TempRaw! GEQ 95 (set ThermalStatus=KRITIS & set ThermalNote=Overheat! Waktunya repaste / bersihkan debu.)
        )

        :: Desktop fallback temperature checks
        echo !ThermalProfile! | findstr "Standard" >nul
        if !errorlevel! equ 0 (
            if !TempRaw! GEQ 45 if !TempRaw! LSS 60 (set ThermalStatus=AMAN & set ThermalNote=Beban kerja standar.)
            if !TempRaw! GEQ 60 if !TempRaw! LSS 75 (set ThermalStatus=NORMAL & set ThermalNote=Suhu wajar untuk beban berat.)
            if !TempRaw! GEQ 75 if !TempRaw! LSS 85 (set ThermalStatus=WASPADA & set ThermalNote=Airflow casing mungkin kurang baik.)
            if !TempRaw! GEQ 85 (set ThermalStatus=KRITIS & set ThermalNote=Bahaya Overheat! Cek heatsink/AIO.)
        )

        echo   CPU Profile    : !ThermalProfile!
        echo   Safe Limit     : Up to !ThermalSafeLimit!
        echo   Status         : [ !ThermalStatus! ]
        echo   Recommendation : !ThermalNote!
    )
) else (
    echo   Temperature    : N/A (Sensor not available)
)
echo.

:: --- POWER PLAN ---
echo [POWER PLAN]
for /f "tokens=2 delims=:" %%A in ('powercfg /getactivescheme ^| findstr ":"') do set ActivePlan=%%A
if defined ActivePlan (
    set ActivePlan=!ActivePlan:~1!
    echo   Active Plan        : !ActivePlan!
    echo !ActivePlan! | findstr /I "Balanced" >nul
    if !errorlevel! equ 0 (
        echo   Health Recommendation: Optimal for Hardware Longevity.
    ) else (
        echo !ActivePlan! | findstr /I "High performance" >nul
        if !errorlevel! equ 0 (
            echo   Health Recommendation: High Performance detected. Monitor thermals for longevity.
        ) else (
            echo !ActivePlan! | findstr /I "Power saver" >nul
            if !errorlevel! equ 0 (
                echo   Health Recommendation: Maximum battery life. Reduced system performance.
            ) else (
                echo   Health Recommendation: Custom plan active. Review thermals periodically.
            )
        )
    )
) else (
    echo   Active Plan        : N/A
    echo   Health Recommendation: N/A
)
echo.

echo ==============================================================
pause
goto MENU

:: ==============================
:: 2. MONITORING
:: ==============================
:OPENMONITOR
start taskmgr
start resmon
start perfmon
start eventvwr
echo Tools Monitoring telah dibuka.
pause
goto MENU

:: ==============================
:: 3. CONFIGURATION
:: ==============================
:OPENCONFIG
start devmgmt.msc
start services.msc
start msconfig
start SystemPropertiesPerformance.exe
start diskmgmt.msc
echo Tools Konfigurasi telah dibuka.
pause
goto MENU

:: ==============================
:: 4. SFC SCAN
:: ==============================
:SFC
if "%admin%"=="NO" (echo Butuh hak Administrator! & pause & goto MENU)
sfc /scannow
pause
goto MENU

:: ==============================
:: 5. DISM REPAIR
:: ==============================
:DISM
if "%admin%"=="NO" (echo Butuh hak Administrator! & pause & goto MENU)
DISM /Online /Cleanup-Image /RestoreHealth
pause
goto MENU

:: ==============================
:: 6. CPU BENCHMARK
:: ==============================
:CPUBENCH
echo Menjalankan uji performa CPU (WinSAT)...
echo Harap tunggu, ini mungkin memakan waktu beberapa menit.
winsat cpuformal
pause
goto MENU

:: ==============================
:: 7. DRIVER ERROR SEARCH
:: ==============================
:DRIVERCHECK
cls
echo Mencari perangkat dengan Driver Error (Yellow Bang)...
echo --------------------------------------------------------------
wmic path win32_pnpentity where "ConfigManagerErrorCode <> 0" get Caption, Status /format:table 2>nul
if %errorlevel% neq 0 echo Tidak ditemukan error pada driver hardware.
echo --------------------------------------------------------------
pause
goto MENU

:: ==============================
:: 8. CHECK DISK (RESTART)
:: ==============================
:CHK
if "%admin%"=="NO" (echo Butuh hak Administrator! & pause & goto MENU)
echo Perintah: chkdsk C: /f /r
set /p confirm=Jadwalkan scan saat restart? (Y/N): 
if /I "%confirm%"=="Y" (chkdsk C: /f /r)
pause
goto MENU

:: ==============================
:: 9. MEMORY DIAGNOSTIC
:: ==============================
:MEMDIAG
mdsched.exe
goto MENU

:: ==============================
:: 10. ADVANCED BOOT
:: ==============================
:ADVBOOT
shutdown /r /o /t 0
goto MENU

:END
exit