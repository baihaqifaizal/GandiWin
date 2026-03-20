# AUTO-GENERATED from Win11Debloat

WIN11_DEBLOAT_TWEAKS = [
    # --- CATEGORY: Privacy & Suggested Content ---
    {
        "id": "w11d_DisableLocationServices",
        "name": "Windows location services & app location access",
        "description": "This will turn off Windows Location Services and deny apps access to your location. This feature uses policies, which will lock down certain settings.",
        "category": "Privacy & Suggested Content",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\LocationAndSensors', 'key': 'DisableLocation', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableFindMyDevice",
        "name": "Find My Device location tracking",
        "description": "This will turn off the 'Find My Device' feature, which periodically sends your device's location to Microsoft. This feature uses policies, which will lock down certain settings.",
        "category": "Privacy & Suggested Content",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\FindMyDevice', 'key': 'AllowFindMyDevice', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableSettings365Ads",
        "name": "Microsoft 365 Copilot ads in Settings Home",
        "description": "This will turn off the Microsoft 365 Copilot ads that appear in the Settings Home page.",
        "category": "Privacy & Suggested Content",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent', 'key': 'DisableConsumerAccountStateContent', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    # --- CATEGORY: AI ---
    {
        "id": "w11d_DisableCopilot",
        "name": "Microsoft Copilot",
        "description": "This will disable and uninstall Microsoft Copilot, Windows' built-in AI assistant.",
        "category": "AI",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced', 'key': 'ShowCopilotButton', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKCU\\Software\\Policies\\Microsoft\\Windows\\WindowsCopilot', 'key': 'TurnOffWindowsCopilot', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsCopilot', 'key': 'TurnOffWindowsCopilot', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableRecall",
        "name": "Windows Recall",
        "description": "This will disable Windows Recall, an AI-powered feature that provides quick access to recently used files, apps and activities. This feature uses policies, which will lock down certain settings.",
        "category": "AI",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Policies\\Microsoft\\Windows\\WindowsAI', 'key': 'DisableAIDataAnalysis', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsAI', 'key': 'DisableAIDataAnalysis', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsAI', 'key': 'AllowRecallEnablement', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsAI', 'key': 'TurnOffSavingSnapshots', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableClickToDo",
        "name": "Click To Do, AI text & image analysis",
        "description": "This will disable Click To Do, which provides AI-powered text and image analysis features in Windows. This feature uses policies, which will lock down certain settings.",
        "category": "AI",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Policies\\Microsoft\\Windows\\WindowsAI', 'key': 'DisableClickToDo', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsAI', 'key': 'DisableClickToDo', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableAISvcAutoStart",
        "name": "AI service from starting automatically",
        "description": "This will set the WSAIFabricSvc service to manual startup, preventing the service from starting automatically with Windows.",
        "category": "AI",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SYSTEM\\CurrentControlSet\\Services\\WSAIFabricSvc', 'key': 'Start', 'value': 3, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableEdgeAI",
        "name": "AI features in Microsoft Edge",
        "description": "This will turn off AI features in Microsoft Edge, such as the AI-powered sidebar and Copilot features. This feature uses policies, which will lock down certain settings.",
        "category": "AI",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Edge', 'key': 'CopilotCDPPageContext', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Edge', 'key': 'CopilotPageContext', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Edge', 'key': 'HubsSidebarEnabled', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Edge', 'key': 'EdgeEntraCopilotPageContext', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Edge', 'key': 'EdgeHistoryAISearchEnabled', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Edge', 'key': 'ComposeInlineEnabled', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Edge', 'key': 'GenAILocalFoundationalModelSettings', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Edge', 'key': 'NewTabPageBingChatEnabled', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisablePaintAI",
        "name": "AI features in Paint",
        "description": "This will turn off AI features in Paint, such as the AI-powered image generation and editing tools. This feature uses policies, which will lock down certain settings.",
        "category": "AI",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Paint', 'key': 'DisableCocreator', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Paint', 'key': 'DisableGenerativeFill', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Paint', 'key': 'DisableImageCreator', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Paint', 'key': 'DisableGenerativeErase', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Paint', 'key': 'DisableRemoveBackground', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableNotepadAI",
        "name": "AI features in Notepad",
        "description": "This will turn off AI features in Notepad, such as the AI-powered writing suggestions. This feature uses policies, which will lock down certain settings.",
        "category": "AI",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SOFTWARE\\Policies\\WindowsNotepad', 'key': 'DisableAIFeatures', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    # --- CATEGORY: Gaming ---
    {
        "id": "w11d_DisableDVR",
        "name": "Xbox game/screen recording",
        "description": "This will disable the Xbox game/screen recording features included with the Game Bar app. This feature uses policies, which will lock down certain settings.",
        "category": "Gaming",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\System\\GameConfigStore', 'key': 'GameDVR_Enabled', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\GameDVR', 'key': 'AppCaptureEnabled', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\GameDVR', 'key': 'AllowGameDVR', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableGameBarIntegration",
        "name": "Game Bar integration",
        "description": "This will disable the Game Bar integration with games and controllers. This stops annoying ms-gamebar popups when launching games or connecting a controller.",
        "category": "Gaming",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\SOFTWARE\\Microsoft\\GameBar', 'key': 'UseNexusForGameBarEnabled', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKCR\\ms-gamebar', 'key': 'URL Protocol', 'value': '', 'reg_type': 'SZ'},
            {'path': 'HKCR\\ms-gamebar', 'key': 'NoOpenWith', 'value': '', 'reg_type': 'SZ'},
            {'path': 'HKCR\\ms-gamebarservices', 'key': 'URL Protocol', 'value': '', 'reg_type': 'SZ'},
            {'path': 'HKCR\\ms-gamebarservices', 'key': 'NoOpenWith', 'value': '', 'reg_type': 'SZ'},
        ]
    },
    # --- CATEGORY: Start Menu & Search ---
    {
        "id": "w11d_DisableStartRecommended",
        "name": "recommended section in the start menu",
        "description": "This will hide the recommended section in the start menu, which shows recently added apps, recently opened files and app recommendations. This feature uses policies, which will lock down certain settings.",
        "category": "Start Menu & Search",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer', 'key': 'HideRecommendedSection', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\PolicyManager\\current\\device\\Start', 'key': 'HideRecommendedSection', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\PolicyManager\\current\\device\\Education', 'key': 'IsEducationEnvironment', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced', 'key': 'Start_Layout', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableStartAllApps",
        "name": "'All Apps' section in the start menu",
        "description": "This will hide the 'All Apps' section in the start menu, which shows all installed apps. WARNING: Hiding this section may make it harder to find installed apps on your system. This feature uses policies, which will lock down certain settings.",
        "category": "Start Menu & Search",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer', 'key': 'NoStartMenuMorePrograms', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableStartPhoneLink",
        "name": "Phone Link integration in the start menu",
        "description": "This will remove the Phone Link integration in the start menu when you have a mobile device linked to your PC.",
        "category": "Start Menu & Search",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Start\\Companions\\Microsoft.YourPhone_8wekyb3d8bbwe', 'key': 'IsEnabled', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableSearchHighlights",
        "name": "Search Highlights in the taskbar search box",
        "description": "This will turn off Search Highlights, which shows dynamically curated branded content and trending topics in the Windows search box on the taskbar.",
        "category": "Start Menu & Search",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\SearchSettings', 'key': 'IsDynamicSearchBoxEnabled', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableSearchHistory",
        "name": "local Windows Search history",
        "description": "This setting disables local search history in Windows Search. This does not affect web search history or the search history saved in Microsoft Edge.",
        "category": "Start Menu & Search",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\SearchSettings', 'key': 'IsDeviceSearchHistoryEnabled', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    # --- CATEGORY: Other ---
    {
        "id": "w11d_DisableSettingsHome",
        "name": "Settings 'Home' page",
        "description": "Removes the 'Home' page from the Settings app.",
        "category": "Other",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer', 'key': 'SettingsPageVisibility', 'value': 'hide:home', 'reg_type': 'SZ'},
        ]
    },
    {
        "id": "w11d_DisableBraveBloat",
        "name": "bloat in Brave browser (AI, Crypto, etc.)",
        "description": "This will disable Brave's built-in AI features, Crypto wallet, News, Rewards, Talk and VPN. This feature uses policies, which will lock down certain settings.",
        "category": "Other",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\Software\\Policies\\BraveSoftware\\Brave', 'key': 'BraveVPNDisabled', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\Software\\Policies\\BraveSoftware\\Brave', 'key': 'BraveWalletDisabled', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\Software\\Policies\\BraveSoftware\\Brave', 'key': 'BraveAIChatEnabled', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\Software\\Policies\\BraveSoftware\\Brave', 'key': 'BraveRewardsDisabled', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\Software\\Policies\\BraveSoftware\\Brave', 'key': 'BraveTalkDisabled', 'value': 1, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\Software\\Policies\\BraveSoftware\\Brave', 'key': 'BraveNewsDisabled', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    # --- CATEGORY: Appearance ---
    {
        "id": "w11d_EnableDarkMode",
        "name": "theme for system and apps",
        "description": "This will set the app and system theme to dark mode.",
        "category": "Appearance",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize', 'key': 'AppsUseLightTheme', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize', 'key': 'SystemUsesLightTheme', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableTransparency",
        "name": "transparency effects",
        "description": "This will disable transparency effects on Windows and interfaces. Which can help improve performance on older hardware.",
        "category": "Appearance",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize', 'key': 'EnableTransparency', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    # --- CATEGORY: System ---
    {
        "id": "w11d_DisableDragTray",
        "name": "'Drag Tray' for sharing & moving files",
        "description": "The Drag Tray is a new feature for sharing & moving files in Windows 11, it appears at the top of the screen when dragging files.",
        "category": "System",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\CDP', 'key': 'DragTrayEnabled', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableMouseAcceleration",
        "name": "Enhance Pointer Precision (mouse acceleration)",
        "description": "This will disable mouse acceleration which is enabled by default in Windows. This makes mouse movement more consistent and predictable.",
        "category": "System",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Control Panel\\Mouse', 'key': 'MouseSpeed', 'value': '0', 'reg_type': 'SZ'},
            {'path': 'HKCU\\Control Panel\\Mouse', 'key': 'MouseThreshold1', 'value': '0', 'reg_type': 'SZ'},
            {'path': 'HKCU\\Control Panel\\Mouse', 'key': 'MouseThreshold2', 'value': '0', 'reg_type': 'SZ'},
        ]
    },
    {
        "id": "w11d_DisableStickyKeys",
        "name": "Sticky Keys keyboard shortcut (5x shift)",
        "description": "This will prevent the Sticky Keys dialog from appearing when you press the Shift key 5 times in a row.",
        "category": "System",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Control Panel\\Accessibility\\StickyKeys', 'key': 'Flags', 'value': '506', 'reg_type': 'SZ'},
        ]
    },
    {
        "id": "w11d_DisableStorageSense",
        "name": "Storage Sense automatic disk cleanup",
        "description": "This will disable Storage Sense, which automatically frees up disk space by deleting temporary files, emptying the recycle bin and cleaning up files in the Downloads folder.",
        "category": "System",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\StorageSense\\Parameters\\StoragePolicy', 'key': '01', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableFastStartup",
        "name": "fast start-up",
        "description": "Fast Start-up helps your PC start faster after shutdown by saving a system image to disk. Disabling Fast Start-up can help with certain issues, but may result in slightly longer boot times.",
        "category": "System",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Power', 'key': 'HiberbootEnabled', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableBitlockerAutoEncryption",
        "name": "BitLocker automatic device encryption",
        "description": "For devices that support it, Windows 11 automatically enables BitLocker device encryption. Disabling this will turn off automatic encryption of the device, but you can still manually enable BitLocker encryption if desired.",
        "category": "System",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SYSTEM\\CurrentControlSet\\Control\\BitLocker', 'key': 'PreventDeviceEncryption', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableModernStandbyNetworking",
        "name": "Modern Standby network connectivity",
        "description": "By default, devices that support Modern Standby maintain network connectivity while in sleep mode. Disabling network connectivity during Modern Standby can help save battery life.",
        "category": "System",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Power\\PowerSettings\\f15576e8-98b7-4186-b944-eafa664402d9', 'key': 'ACSettingIndex', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Power\\PowerSettings\\f15576e8-98b7-4186-b944-eafa664402d9', 'key': 'DCSettingIndex', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    # --- CATEGORY: Multi-tasking ---
    {
        "id": "w11d_DisableWindowSnapping",
        "name": "window snapping",
        "description": "This will turn off the ability to snap windows to the sides or corners of the screen.",
        "category": "Multi-tasking",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Control Panel\\Desktop', 'key': 'WindowArrangementActive', 'value': '0', 'reg_type': 'SZ'},
        ]
    },
    {
        "id": "w11d_HideTabsInAltTab",
        "name": "tabs from apps when snapping or pressing Alt+Tab",
        "description": "Disable showing tabs from apps when snapping or pressing Alt+Tab...",
        "category": "Multi-tasking",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced', 'key': 'MultiTaskingAltTabFilter', 'value': 3, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_Show3TabsInAltTab",
        "name": "tabs from apps when snapping or pressing Alt+Tab",
        "description": "Enable showing 3 tabs from apps when snapping or pressing Alt+Tab...",
        "category": "Multi-tasking",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced', 'key': 'MultiTaskingAltTabFilter', 'value': 2, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_Show5TabsInAltTab",
        "name": "tabs from apps when snapping or pressing Alt+Tab",
        "description": "Enable showing 5 tabs from apps when snapping or pressing Alt+Tab...",
        "category": "Multi-tasking",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced', 'key': 'MultiTaskingAltTabFilter', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_Show20TabsInAltTab",
        "name": "tabs from apps when snapping or pressing Alt+Tab",
        "description": "Enable showing 20 tabs from apps when snapping or pressing Alt+Tab...",
        "category": "Multi-tasking",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced', 'key': 'MultiTaskingAltTabFilter', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    # --- CATEGORY: Taskbar ---
    {
        "id": "w11d_EnableEndTask",
        "name": "'End Task' option in taskbar context menu",
        "description": "When enabled, adds an 'End Task' option to the right-click context menu for apps in the taskbar, allowing you to quickly force close apps.",
        "category": "Taskbar",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\TaskbarDeveloperSettings', 'key': 'TaskbarEndTask', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_EnableLastActiveClick",
        "name": "'Last Active Click' behavior for taskbar apps",
        "description": "When enabled, clicking on an app in the taskbar will switch to the last active window of that app, instead of only showing the thumbnail preview.",
        "category": "Taskbar",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced', 'key': 'LastActiveClick', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    # --- CATEGORY: File Explorer ---
    {
        "id": "w11d_ExplorerToHome",
        "name": "Change the default location that File Explorer opens to 'Home'",
        "description": "Changing the default location that File Explorer opens to, to 'Home'...",
        "category": "File Explorer",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced', 'key': 'LaunchTo', 'value': 2, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_ExplorerToThisPC",
        "name": "Change the default location that File Explorer opens to 'This PC'",
        "description": "Changing the default location that File Explorer opens to, to 'This PC'...",
        "category": "File Explorer",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced', 'key': 'LaunchTo', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_ExplorerToDownloads",
        "name": "Change the default location that File Explorer opens to 'Downloads'",
        "description": "Changing the default location that File Explorer opens to, to 'Downloads'...",
        "category": "File Explorer",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced', 'key': 'LaunchTo', 'value': 3, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_ExplorerToOneDrive",
        "name": "Change the default location that File Explorer opens to 'OneDrive'",
        "description": "Changing the default location that File Explorer opens to, to 'OneDrive'...",
        "category": "File Explorer",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced', 'key': 'LaunchTo', 'value': 4, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_AddFoldersToThisPC",
        "name": "common folders back to 'This PC' page",
        "description": "This setting will add common folders like Desktop, Documents, Downloads, Music, Pictures and Videos back to the 'This PC' page in File Explorer.",
        "category": "File Explorer",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace\\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}', 'key': 'HiddenByDefault', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace\\{d3162b92-9365-467a-956b-92703aca08af}', 'key': 'HiddenByDefault', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace\\{088e3905-0323-4b02-9826-5d99428e115f}', 'key': 'HiddenByDefault', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace\\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}', 'key': 'HiddenByDefault', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace\\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}', 'key': 'HiddenByDefault', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace\\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}', 'key': 'HiddenByDefault', 'value': 0, 'reg_type': 'DWORD'},
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace\\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}', 'key': 'HiddenByDefault', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    # --- CATEGORY: Windows Update ---
    {
        "id": "w11d_DisableUpdateASAP",
        "name": "updates as soon as they're available",
        "description": "This will prevent your PC from being among the first to receive new non-security updates. Your PC will still receive these updates eventually.",
        "category": "Windows Update",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings', 'key': 'IsContinuousInnovationOptedIn', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_PreventUpdateAutoReboot",
        "name": "automatic restarts after updates while signed in",
        "description": "This will prevent your PC from automatically restarting after updates while any user is signed in.",
        "category": "Windows Update",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU', 'key': 'NoAutoRebootWithLoggedOnUsers', 'value': 1, 'reg_type': 'DWORD'},
        ]
    },
    {
        "id": "w11d_DisableDeliveryOptimization",
        "name": "sharing downloaded updates with other PCs",
        "description": "This will prevent your PC from sharing downloaded updates with other PCs on the local network or on the internet. This also prevents your PC from downloading updates from other PCs.",
        "category": "Windows Update",
        "risk": "safe",
        "type": "registry",
        "actions": [
            {'path': 'HKU\\S-1-5-20\\Software\\Microsoft\\Windows\\CurrentVersion\\DeliveryOptimization\\Settings', 'key': 'DownloadMode', 'value': 0, 'reg_type': 'DWORD'},
        ]
    },
]

WIN11_DEBLOAT_DROPDOWNS = [
    {
        "id": "w11d_group_SearchIcon",
        "name": "Taskbar search style",
        "description": "This setting allows you to customize the appearance of the search box on the taskbar.",
        "category": "Taskbar",
        "options": [
            {
                "label": "Hide",
                "feature_ids": ["w11d_HideSearchTb"]
            },
            {
                "label": "Show search icon only",
                "feature_ids": ["w11d_ShowSearchIconTb"]
            },
            {
                "label": "Show search icon and label",
                "feature_ids": ["w11d_ShowSearchLabelTb"]
            },
            {
                "label": "Show search box",
                "feature_ids": ["w11d_ShowSearchBoxTb"]
            },
        ]
    },
    {
        "id": "w11d_group_MultiMon",
        "name": "Show taskbar apps on",
        "description": "This setting allows you to choose where taskbar app buttons are shown when using multiple monitors.",
        "category": "Taskbar",
        "options": [
            {
                "label": "All taskbars",
                "feature_ids": ["w11d_MMTaskbarModeAll"]
            },
            {
                "label": "Main taskbar and taskbar where window is open",
                "feature_ids": ["w11d_MMTaskbarModeMainActive"]
            },
            {
                "label": "Taskbar where window is open",
                "feature_ids": ["w11d_MMTaskbarModeActive"]
            },
        ]
    },
    {
        "id": "w11d_group_CombineButtons",
        "name": "Combine taskbar buttons on the main display",
        "description": "This setting allows you to choose how taskbar buttons are combined on the main display.",
        "category": "Taskbar",
        "options": [
            {
                "label": "Always",
                "feature_ids": ["w11d_CombineTaskbarAlways"]
            },
            {
                "label": "When taskbar is full",
                "feature_ids": ["w11d_CombineTaskbarWhenFull"]
            },
            {
                "label": "Never",
                "feature_ids": ["w11d_CombineTaskbarNever"]
            },
        ]
    },
    {
        "id": "w11d_group_CombineMMButtons",
        "name": "Combine taskbar buttons on secondary displays",
        "description": "This setting allows you to choose how taskbar buttons are combined on secondary displays.",
        "category": "Taskbar",
        "options": [
            {
                "label": "Always",
                "feature_ids": ["w11d_CombineMMTaskbarAlways"]
            },
            {
                "label": "When taskbar is full",
                "feature_ids": ["w11d_CombineMMTaskbarWhenFull"]
            },
            {
                "label": "Never",
                "feature_ids": ["w11d_CombineMMTaskbarNever"]
            },
        ]
    },
    {
        "id": "w11d_group_ClearStart",
        "name": "Remove pinned apps from the start menu",
        "description": "This setting allows you to quickly remove all pinned apps from the start menu.",
        "category": "Start Menu & Search",
        "options": [
            {
                "label": "Remove for the selected user",
                "feature_ids": ["w11d_ClearStart"]
            },
            {
                "label": "Remove for all users",
                "feature_ids": ["w11d_ClearStartAllUsers"]
            },
        ]
    },
    {
        "id": "w11d_group_ExplorerLocation",
        "name": "Open File Explorer to",
        "description": "This setting allows you to choose the default location that File Explorer opens to.",
        "category": "File Explorer",
        "options": [
            {
                "label": "Home",
                "feature_ids": ["w11d_ExplorerToHome"]
            },
            {
                "label": "This PC",
                "feature_ids": ["w11d_ExplorerToThisPC"]
            },
            {
                "label": "Downloads",
                "feature_ids": ["w11d_ExplorerToDownloads"]
            },
            {
                "label": "OneDrive",
                "feature_ids": ["w11d_ExplorerToOneDrive"]
            },
        ]
    },
    {
        "id": "w11d_group_ShowTabsInAltTab",
        "name": "Show tabs from apps when snapping or pressing Alt+Tab",
        "description": "This setting allows you to choose whether to show tabs from apps (such as Edge browser tabs) when snapping windows or pressing Alt+Tab.",
        "category": "Multi-tasking",
        "options": [
            {
                "label": "Don't show tabs",
                "feature_ids": ["w11d_HideTabsInAltTab"]
            },
            {
                "label": "Show 3 most recent tabs",
                "feature_ids": ["w11d_Show3TabsInAltTab"]
            },
            {
                "label": "Show 5 most recent tabs",
                "feature_ids": ["w11d_Show5TabsInAltTab"]
            },
            {
                "label": "Show 20 most recent tabs",
                "feature_ids": ["w11d_Show20TabsInAltTab"]
            },
        ]
    },
]