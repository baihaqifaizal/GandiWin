function Export-GandiWinHTML {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LeftColumn,

        [Parameter(Mandatory = $true)]
        [string]$RightColumn,

        [Parameter(Mandatory = $true)]
        [string]$ExportPath,

        [Parameter(Mandatory = $true)]
        [string]$ExportTimeDisp,

        [Parameter(Mandatory = $true)]
        [string]$AppVersion,

        [Parameter(Mandatory = $true)]
        [string]$LogoPath
    )

    $HtmlPath = $ExportPath -replace "\.log$", ".html"

    # Convert Logo to Base64 for Zero-Dependency Email/Sharing
    $LogoImg = ""
    if (Test-Path $LogoPath) {
        try {
            $ImageBytes = [System.IO.File]::ReadAllBytes($LogoPath)
            $Base64 = [Convert]::ToBase64String($ImageBytes)
            $LogoImg = "<img class='watermark' src='data:image/png;base64,$Base64' />"
        }
        catch { }
    }

    # Helper function to inject HTML span tags for color highlights
    function Format-HtmlLogContent {
        param([string]$Text)
        
        # HTML Escape
        $Text = $Text.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")

        # Custom Highlighting Rules matching the PDF layout
        $Text = $Text -replace "\[OVERVIEW\]", "<span class='hl-yellow'>[OVERVIEW]</span>"
        $Text = $Text -replace "\[MOTHERBOARD\]", "<span class='hl-green'>[MOTHERBOARD]</span>"
        $Text = $Text -replace "\[OPERATING SYSTEM\]", "<span class='hl-red'>[OPERATING SYSTEM]</span>"
        $Text = $Text -replace "\[PROCESSOR\]", "<span class='hl-cyan'>[PROCESSOR]</span>"
        $Text = $Text -replace "\[RAM\]", "<span class='hl-green'>[RAM]</span>"
        $Text = $Text -replace "\[GRAPHICS\]", "<span class='hl-magenta'>[GRAPHICS]</span>"
        $Text = $Text -replace "\[DISPLAY\]", "<span class='hl-yellow'>[DISPLAY]</span>"
        $Text = $Text -replace "\[STORAGE\]", "<span class='hl-cyan'>[STORAGE]</span>"
        $Text = $Text -replace "\[NETWORK\]", "<span class='hl-green'>[NETWORK]</span>"
        $Text = $Text -replace "\[BATTERY\]", "<span class='hl-magenta'>[BATTERY]</span>"
        $Text = $Text -replace "\[THERMAL\]", "<span class='hl-red'>[THERMAL]</span>"
        $Text = $Text -replace "\[POWER PLAN\]", "<span class='hl-yellow'>[POWER PLAN]</span>"
        $Text = $Text -replace "\[PERFORMANCE METRICS\]", "<span class='hl-green'>[PERFORMANCE METRICS]</span>"
        
        $Text = $Text -replace "\[MEMORY DETAILED\]", "<span class='hl-cyan'>[MEMORY DETAILED]</span>"
        $Text = $Text -replace "\[STORAGE PERFORMANCE\]", "<span class='hl-magenta'>[STORAGE PERFORMANCE]</span>"
        $Text = $Text -replace "\[SERVICES RUNNING AUTOMATIC LIST\]", "<span class='hl-yellow'>[SERVICES RUNNING AUTOMATIC LIST]</span>"
        
        # Color free space text red as seen in the PDF output
        $Text = [regex]::Replace($Text, "(free of )([0-9\.]+ GB)", '$1<span class="red-text">$2</span>')
        
        return $Text
    }

    $HtmlLeft = (Format-HtmlLogContent $LeftColumn).TrimStart()
    $HtmlRight = (Format-HtmlLogContent $RightColumn).TrimStart()

    $HTML = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>GANDIWIN SYSTEM CHECK</title>
<style>
@page {
    size: 215mm 330mm;
    margin: 0mm; /* Menghilangkan margin browser & header/footer otomatis */
}
* {
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
    box-sizing: border-box;
}
body {
    font-family: 'Consolas', 'Courier New', monospace;
    font-size: 7.8pt; /* Font diperkecil sedikit agar presisi */
    line-height: 1.2; /* Baris dipepetkan agar ruang vertikal lebih lega */
    background-color: white;
    background-image: radial-gradient(#d3d3d3 1px, transparent 1px);
    background-size: 15px 15px;
    color: black;
    margin: 0;
    padding: 6mm 12.7mm 10mm 12.7mm; /* Ruang kosong atas dikurangi menjadi 6mm */
    width: 215mm;
    height: 328mm; /* Paksa lebih kecil 2mm dari tinggi kertas untuk mencegah bocor ke page 2 */
    overflow: hidden; /* Memaksa memotong kalau ada yang bocor */
}
.watermark {
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%) rotate(-45deg);
    opacity: 0.12;
    z-index: -10;
    pointer-events: none;
    width: 100%;
    max-width: 650px;
}
.wrapper {
    position: relative;
    height: 100%;
}
.header pre {
    font-weight: bold;
    margin-bottom: 8px; /* Margin atas judul direkatkan */
}
.grid {
    display: flex;
    justify-content: space-between;
    gap: 15mm;
}
.col {
    flex: 1;
}
.col-right {
    max-width: 48%;
}
pre {
    font-family: inherit;
    font-size: inherit;
    margin: 0;
    white-space: pre-wrap;
    word-wrap: break-word;
}
.hl-yellow { background-color: #FFFF00; color: black; font-weight: bold; padding: 0 3px;}
.hl-green { background-color: #00FF00; color: black; font-weight: bold; padding: 0 3px;}
.hl-red { background-color: #FF0000; color: white; font-weight: bold; padding: 0 3px;}
.hl-cyan { background-color: #00FFFF; color: black; font-weight: bold; padding: 0 3px;}
.hl-magenta { background-color: #FF00FF; color: white; font-weight: bold; padding: 0 3px;}
.red-text { color: #cc0000; font-weight: bold; }

.footer {
    position: absolute;
    bottom: 0; /* Mengikat kuat ke bawah halaman pertama */
    left: 0;
    right: 0;
    display: flex;
    justify-content: space-between;
    font-style: italic;
    font-size: 8pt;
    font-weight: bold;
}
</style>
</head>
<body>
    <div class="wrapper">
        $LogoImg
        <div class="grid">
            <div class="col">
                <div class="header">
<pre>=============================================================
GANDIWIN SYSTEM CHECK - PERFORMANCE LOG
=============================================================</pre>
                </div>
                <pre>$HtmlLeft</pre>
            </div>
            <div class="col col-right">
                <pre>$HtmlRight</pre>
            </div>
        </div>

        <div class="footer">
            <span>`$$AppVersion</span>
            <span>//$ExportTimeDisp</span>
        </div>
    </div>
    
    <script>
        window.onload = function() {
            setTimeout(function() { window.print(); }, 800);
        }
    </script>
</body>
</html>
"@

    $HTML | Out-File -FilePath $HtmlPath -Encoding UTF8
    
    try {
        Start-Process $HtmlPath
    }
    catch { }
}

Export-ModuleMember -Function Export-GandiWinHTML
