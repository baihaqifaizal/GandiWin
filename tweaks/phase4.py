PHASE4_TWEAKS = [
    {
        "id": "disable_nagle",
        "name": "Matikan Nagle's Algorithm",
        "description": "Hapus delay pengiriman paket TCP kecil untuk input gaming yang lebih responsif.",
        "detail": "Nagle's Algorithm menahan paket data kecil dan menggabungkannya sebelum dikirim. Di gaming, ini berarti input dari keyboard/mouse ditahan beberapa milidetik sebelum dikirim ke server. Mematikan ini membuat respon input lebih 'snappy'. Upload bandwidth bisa sedikit naik.",
        "phase": 4,
        "category": "Network",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {
                "path": r"HKLM\SOFTWARE\Microsoft\MSMQ\Parameters",
                "key": "TCPNoDelay",
                "value": 1,
                "reg_type": "DWORD",
            },
        ],
        "needs_restart": False,
        "rollback": True,
        "tags": ["network", "gaming", "tcp"],
    },
    {
        "id": "disable_fullscreen_optimization",
        "name": "Matikan Fullscreen Optimization",
        "description": "Nonaktifkan fitur yang memaksa game ke borderless mode dan menambah 1-5ms input lag.",
        "detail": "Fullscreen Optimizations adalah fitur Windows 10/11 yang memaksa mode Fullscreen Borderless meski game di true fullscreen. GPU pipeline berubah dan bisa tambah 1-5ms input latency. Tweak ini set registry flag global.",
        "phase": 4,
        "category": "Gaming",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {
                "path": r"HKCU\System\GameConfigStore",
                "key": "GameDVR_FSEBehaviorMode",
                "value": 2,
                "reg_type": "DWORD",
            },
            {
                "path": r"HKCU\System\GameConfigStore",
                "key": "GameDVR_HonorUserFSEBehaviorMode",
                "value": 1,
                "reg_type": "DWORD",
            },
            {
                "path": r"HKCU\System\GameConfigStore",
                "key": "GameDVR_FSEBehavior",
                "value": 2,
                "reg_type": "DWORD",
            },
        ],
        "needs_restart": False,
        "rollback": True,
        "tags": ["gaming", "input_lag", "fullscreen"],
    },
    {
        "id": "remove_game_bar_dvr",
        "name": "Hapus Xbox Game Bar & DVR",
        "description": "Matikan Game Bar yang merekam gameplay di background dan memakan GPU encoder.",
        "detail": "Xbox Game Bar merekam gameplay secara pasif di background (DVR mode) bahkan saat tidak digunakan — menggunakan GPU encoder dan disk I/O tanpa izin. Tweak ini menghapus Game Bar apps dan mematikan DVR via registry.",
        "phase": 4,
        "category": "Gaming",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {
                "path": r"HKCU\System\GameConfigStore",
                "key": "GameDVR_Enabled",
                "value": 0,
                "reg_type": "DWORD",
            },
            {
                "path": r"HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR",
                "key": "AllowGameDVR",
                "value": 0,
                "reg_type": "DWORD",
            },
            {
                "path": r"HKCU\SOFTWARE\Microsoft\GameBar",
                "key": "AllowAutoGameMode",
                "value": 0,
                "reg_type": "DWORD",
            },
        ],
        "needs_restart": False,
        "rollback": True,
        "tags": ["gaming", "xbox", "dvr"],
    },
    {
        "id": "change_dns_cloudflare",
        "name": "Ganti DNS ke Cloudflare (1.1.1.1)",
        "description": "Ganti DNS ISP yang lambat (50-200ms) ke Cloudflare (~8ms) untuk resolve lebih cepat.",
        "detail": "DNS default ISP Indonesia sering lambat resolve. Setiap kali game connect ke server baru, harus resolve DNS dulu. Cloudflare 1.1.1.1 adalah DNS publik tercepat dengan rata-rata ~8ms di Indonesia.",
        "phase": 4,
        "category": "Network",
        "risk": "safe",
        "type": "powershell",
        "actions": [
            {
                "command": (
                    "$adapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object -First 1; "
                    "if ($adapter) { "
                    "Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @('1.1.1.1','1.0.0.1'); "
                    "Write-Output \"DNS set to Cloudflare on $($adapter.Name)\" "
                    "} else { Write-Error 'No active adapter found' }"
                )
            },
        ],
        "needs_restart": False,
        "rollback": True,
        "rollback_cmd": (
            "$adapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object -First 1; "
            "if ($adapter) { Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses }"
        ),
        "tags": ["network", "dns", "gaming"],
    },
    {
        "id": "optimize_network_adapter",
        "name": "Optimasi Network Adapter",
        "description": "Naikkan buffer size dan optimasi setting adapter jaringan untuk throughput lebih stabil.",
        "detail": "Disable IPv6 jika ISP tidak support (kurangi overhead). Naikkan Receive/Transmit Buffers untuk throughput stabil. Pastikan Auto-Negotiation aktif.",
        "phase": 4,
        "category": "Network",
        "risk": "safe",
        "type": "powershell",
        "actions": [
            {
                "command": (
                    "$adapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object -First 1; "
                    "if ($adapter) { "
                    "Disable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue; "
                    "Write-Output \"IPv6 disabled on $($adapter.Name)\" "
                    "}"
                )
            },
        ],
        "needs_restart": False,
        "rollback": True,
        "rollback_cmd": (
            "$adapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object -First 1; "
            "if ($adapter) { Enable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 }"
        ),
        "tags": ["network", "adapter", "ipv6"],
    },
]
