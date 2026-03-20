PHASE2_TWEAKS = [
    {
        "id": "disable_spectre_meltdown",
        "name": "Nonaktifkan Spectre/Meltdown Patch",
        "description": "Nonaktifkan patch keamanan CPU untuk mendapatkan kembali 3-15% performa.",
        "detail": "Spectre dan Meltdown adalah kerentanan hardware CPU yang ditemukan 2018. Microsoft menambahkan patch software yang memaksa CPU melakukan pengecekan tambahan setiap kali ada spekulasi instruksi. Patch ini menurunkan performa CPU sekitar 3-15% tergantung workload. PERINGATAN: PC menjadi rentan terhadap Spectre/Meltdown exploit. Hanya aman jika PC tidak digunakan untuk browsing/email di environment tidak terpercaya.",
        "phase": 2,
        "category": "Kernel",
        "risk": "danger",
        "type": "registry",
        "actions": [
            {
                "path": r"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management",
                "key": "FeatureSettingsOverride",
                "value": 3,
                "reg_type": "DWORD",
            },
            {
                "path": r"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management",
                "key": "FeatureSettingsOverrideMask",
                "value": 3,
                "reg_type": "DWORD",
            },
        ],
        "needs_restart": True,
        "rollback": True,
        "tags": ["kernel", "security", "cpu"],
    },
    {
        "id": "cpu_core_unparking",
        "name": "CPU Core Unparking",
        "description": "Pastikan semua core CPU selalu aktif untuk menghilangkan micro-stutter.",
        "detail": "Windows 'memarkirkan' core CPU saat idle untuk hemat daya. Saat load tiba-tiba naik, butuh 1-10ms untuk bangunkan core yang di-park. Ini menyebabkan micro-stutter terutama saat gaming. Tweak ini set core parking ke 0% (semua core selalu aktif). Konsumsi daya naik saat idle.",
        "phase": 2,
        "category": "Kernel",
        "risk": "warning",
        "type": "registry",
        "actions": [
            {
                "path": r"HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583",
                "key": "ValueMax",
                "value": 0,
                "reg_type": "DWORD",
            },
            {
                "path": r"HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583",
                "key": "ValueMin",
                "value": 0,
                "reg_type": "DWORD",
            },
        ],
        "needs_restart": False,
        "rollback": True,
        "tags": ["kernel", "cpu", "performance"],
    },
    {
        "id": "enable_msi_mode",
        "name": "Aktifkan MSI Mode Interrupt",
        "description": "Ganti line-based interrupts ke MSI (Message Signaled Interrupt) untuk GPU dan NIC.",
        "detail": "Hardware secara default menggunakan Line-based Interrupts yang bisa stack (antrian menumpuk). MSI adalah mode modern yang lebih efisien — setiap interrupt dikirim sebagai pesan langsung ke CPU. Perlu deteksi device otomatis.",
        "phase": 2,
        "category": "Kernel",
        "risk": "warning",
        "type": "powershell",
        "actions": [
            {
                "command": (
                    "Get-CimInstance -ClassName Win32_VideoController | ForEach-Object { "
                    "$path = 'HKLM:\\SYSTEM\\CurrentControlSet\\Enum\\' + $_.PNPDeviceID + "
                    "'\\Device Parameters\\Interrupt Management\\MessageSignaledInterruptProperties'; "
                    "if (Test-Path $path) { Set-ItemProperty -Path $path -Name 'MSISupported' -Value 1 -Type DWord } "
                    "}"
                )
            },
        ],
        "needs_restart": True,
        "rollback": True,
        "tags": ["kernel", "gpu", "interrupt"],
    },
    {
        "id": "network_throttling_index",
        "name": "Hapus Network Throttling",
        "description": "Hilangkan batas throughput jaringan per-proses yang dipasang Windows.",
        "detail": "Windows membatasi throughput jaringan per-proses untuk memprioritaskan multimedia playback. Nilai default 10 artinya hanya 10 packet burst per interval. Nilai FFFFFFFF menghilangkan limit. Ping game lebih stabil, download lebih konsisten.",
        "phase": 2,
        "category": "Network",
        "risk": "warning",
        "type": "registry",
        "actions": [
            {
                "path": r"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile",
                "key": "NetworkThrottlingIndex",
                "value": 0xFFFFFFFF,
                "reg_type": "DWORD",
            },
            {
                "path": r"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile",
                "key": "SystemResponsiveness",
                "value": 0,
                "reg_type": "DWORD",
            },
        ],
        "needs_restart": False,
        "rollback": True,
        "tags": ["network", "gaming", "performance"],
    },
    {
        "id": "enable_hags",
        "name": "Aktifkan GPU Hardware Scheduling",
        "description": "Biarkan GPU modern mengatur scheduling-nya sendiri untuk FPS lebih stabil.",
        "detail": "Secara default, CPU yang mengatur penjadwalan task GPU. Dengan HAGS aktif, GPU modern (NVIDIA RTX, AMD RX 5000+) mengatur scheduling sendiri — lebih efisien dan mengurangi beban CPU. Syarat: GPU dan driver harus support HAGS. Pada driver lama bisa menyebabkan crash.",
        "phase": 2,
        "category": "Kernel",
        "risk": "warning",
        "type": "registry",
        "actions": [
            {
                "path": r"HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers",
                "key": "HwSchMode",
                "value": 2,
                "reg_type": "DWORD",
            }
        ],
        "needs_restart": True,
        "rollback": True,
        "tags": ["kernel", "gpu", "gaming"],
    },
]
