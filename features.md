### **FASE 1: FONDASI SOFTWARE & KONFIGURASI 01 sampai 20**

## **01 Thermal Check**

- **Masalah:** Software tweaks tidak akan berguna jika CPU/GPU terlalu panas (95°C+).
- **Detil:** Sistem akan memotong kecepatan clock (Throttle) secara paksa untuk mencegah kerusakan. Ini sering disalahartikan sebagai "Windows lemot".
- **Solusi:** Gunakan **HWMonitor** atau **HWiNFO64**. Jika suhu mendekati 100°C, bersihkan debu, ganti thermal paste, atau naikkan fan curve. _Clean install Windows tidak bisa mengatasi thermal throttling._

## **02 Antivirus Conflict**

- **Masalah:** User pasang Windows Defender + Avast + Smadav bersamaan.
- **Detil:** Dua antivirus akan "sabet menyabet" file saat diakses. Ini membuat proses buka file atau game jadi sangat lambat.
- **Solusi:** Percaya satu antivirus. Jika pakai Defender, matikan Smadav/Avast. Jika pakai pihak ketiga, matikan Defender total via Registry atau Group Policy.

## **03 Bloatware Removal**

- **Masalah:** Vendor laptop sering memasang aplikasi trial, game demo, dan utilitas duplikatif yang berjalan diam-diam.
- **Detil:** Aplikasi ini seringkali membuat _scheduled task_ dan service sendiri. Contoh: McAfee Trial, DropBox Promo, Candy Crush, dan aplikasi UWP lainnya.
- **Solusi:** Gunakan PowerShell command **`Get-AppxPackage -AllUsers | Remove-AppxPackage`** untuk penghapusan massal atau gunakan tools open-source seperti _Bulk Crap Uninstaller_ (BCUninstaller) untuk scan lebih dalam termasuk sisa registry.

## **04 Startup Control**

- **Masalah:** Program seperti Spotify, Steam, atau Updater Adobe berjalan saat booting dengan status "High Impact".
- **Detil:** Mereka "mencuri" bandwidth disk I/O paling keras di detik-detik pertama login, membuat PC terasa lemot saat baru dinyalakan.
- **Solusi:** Buka **Task Manager > Tab Startup**. Klik kanan > Disable pada aplikasi yang tidak perlu siap sedia. Prioritaskan hanya antivirus dan driver audio.

## **05 Background Services**

- **Masalah:** Windows menjalankan puluhan servis yang mungkin tidak kamu butuh (misal: Print Spooler jika tidak punya printer, Fax service, Xbox services).
- **Detil:** Servis ini "nongkrong" di RAM dan CPU cycles.
- **Solusi:** Buka **`services.msc`**. Ubah Startup Type menjadi **Disable** atau **Manual** untuk servis yang tidak kritis seperti: _Geolocation Service, Xbox Accessory Management, Parental Controls_.

## **06 Background Apps**

- **Masalah:** Berbeda dengan _Startup_, fitur ini mengizinkan aplikasi (khususnya UWP/Store apps seperti Mail, Weather, News) untuk "hidup" di background menerima update notifikasi meski tidak dibuka.
- **Detil:** Ini makan bandwidth dan CPU cycles untuk hal yang tidak kamu lihat. Fiture ini sering diabaikan padahal sangat boros resource.
- **Solusi:** Buka **Settings > Apps > Advanced App Settings > Background Apps Permissions**. Set ke **"Let Windows Decide"** (seringkali salah arah) atau lebih baik pilih **"Never"** atau matikan toggle **"Let apps run in background"** secara global jika kamu tidak butuh notifikasi instan dari aplikasi toko.

## **07 Telemetry Disabler**

- **Masalah:** Servis **`DiagTrack`** dan **`dmwappushservice`** mengirim data ke Microsoft secara real-time.
- **Detil:** Proses ini aktif menulis log di disk dan menggunakan koneksi internet di background.
- **Solusi:** Nonaktifkan via **`gpedit.msc`** (Computer Configuration > Administrative Templates > Windows Components > Data Collection and Preview Builds). Atau disable service **`Connected User Experiences and Telemetry`**.

## **08 Delivery Optimization**

- **Masalah:** Windows menggunakan PC-mu sebagai "server" untuk mengirim update ke komputer lain di internet (Peer-to-Peer).
- **Detil:** Ini makan Upload Bandwidth parah. Saat kamu main game online, ping bisa naik drastis karena Windows diam-diam mengupload update ke tetangga.
- **Solusi:** Buka **Settings > Windows Update > Advanced Options > Delivery Optimization**. Matikan toggle **"Allow downloads from other PCs"**. Ini menghentikan Windows mencuri bandwidthmu.

## **09 Scheduled Tasks**

- **Masalah:** Windows punya jadwal otomatis yang mengganggu, seperti _Compatibility Appraiser_ yang mengecek apakah PC bisa di-upgrade.
- **Detil:** Task ini sering jalan tiba-tiba saat PC idle, membuat harddisk bising atau CPU naik.
- **Solusi:** Buka **`taskschd.msc`**. Disable task di folder _Application Experience_ dan _Customer Experience Improvement Program_.

## **10 Disk Clean up**

- **Masalah:** File temporary, cache browser, dan log sistem menumpuk memakan space dan memperlambat indeks file.
- **Detil:** Space yang terlalu penuh (terutama di SSD) memperlambat _write cycle_. Logical errors pada file system membuat Windows "berpikir" lama saat mengakses file.
- **Solusi:** Jalankan **`cleanmgr /sageset:1`** untuk memilih semua opsi pembersihan, lalu **`cleanmgr /sagerun:1`**. Gunakan **`chkdsk C: /f`** untuk perbaikan file system logika.

## **11 NTFS Repair**

- **Masalah:** File System error (bukan bad sector fisik).
- **Detil:** Korupsi kecil pada $MFT (Master File Table) membuat Windows susah mencari lokasi file, bikin lag saat browsing folder.
- **Solusi:** Rutin jalankan **`chkdsk C: /f`** (Fix) untuk memperbaiki indeks logika tanpa perlu scan fisik yang lama.

## **12 AppData Cleanup**

- **Masalah:** Folder **`C:\Users\...\AppData\Local\Temp`** dan cache Spotify/Discord menumpuk.
- **Detil:** Bisa mencapai puluhan GB. Folder **`Roaming`** juga bisa penuh konfigurasi software sampah.
- **Solusi:** Manual hapus isi folder **`%temp%`**, **`prefetch`**, dan cek folder **`AppData`** milik software yang sudah di-uninstall tapi foldernya masih ada.

## **13 Ghost Drivers**

- **Masalah:** Sisa driver printer lama, mouse USB lama, atau HP smartphone driver yang sudah tidak dipakai masih "tinggal".
- **Detil:** Driver bayangan ini bisa menyebabkan Plug and Play service bekerja ekstra saat booting.
- **Solusi:** Di CMD ketik **`set devmgr_show_nonpresent_devices=1`**. Lalu di Device Manager klik View > Show Hidden Devices. Uninstall driver yang ikonnya pudar (grayed out).

## **14 Hibernation Disable**

- **Masalah:** File **`hiberfil.sys`** bisa menghabiskan beberapa GB SSD. Fitur Fast Startup sering bikin sistem "tidak fresh".
- **Detil:** Fast Startup adalah hybrid hibernate, bisa menyebabkan bug dan memakan waktu write disk.
- **Solusi:** CMD: **`powercfg -h off`**. Ini menghapus file hiberfil.sys dan memaksa sistem melakukan "Cold Boot" yang lebih bersih setiap kali dinyalakan.

## **15 Virtual Memory**

- **Masalah:** Windows mengatur pagefile secara otomatis, seringkali terfragmentasi dan terlalu kecil.
- **Detil:** Saat RAM penuh, file **`pagefile.sys`** yang lambat membuat PC freeze.
- **Solusi:** Set manual ukuran Pagefile (Initial & Maximum) sekitar 1.5x - 2x RAM fisik. Taruh di SSD jika ada.

## **16 Disable Spectre & Meltdown Mitigations (Raw Speed)**

- **Detil Teknis:** Patch keamanan CPU (Spectre/Meltdown) memaksa CPU melakukan pengecekan spekulasi instruksi. Ini menurunkan performa mentah (IPC) CPU.
- **Tweak Kernel:**
  - Buka Regedit: **`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`**.
  - Buat DWORD baru bernama **`FeatureSettingsOverride`**, isi value **`3`**.
  - Buat DWORD **`FeatureSettingsOverrideMask`**, isi value **`3`**.
  - _Hasil:_ CPU bekerja tanpa "rem" keamanan. Resiko: Rentan exploit malware, tapi performa kalkulasi naik signifikan.

## **17 CPU Core Unparking**

- **Detil Teknis:** Core CPU "di-park" (tidur) saat idle. Butuh waktu milidetik untuk bangun, menyebabkan micro-stutter.
- **Tweak Kernel:**
  - Regedit: **`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\...`** (Key yang panjang terkait Processor Power Management).
  - Ubah attribute **`ValueMax`** dan **`ValueMin`** untuk core parking.
  - Atau gunakan tool kecil seperti _ParkControl_ untuk mengeset "Core Parking" ke 0% (Unparked).

## **18 MSI Mode Interrupt**

- **Detil Teknis:** Defaultnya, GPU/SSD pakai "Line-based interrupt" yang bisa nge-stack. MSI (Message Signaled Interrupts) lebih modern dan efisien.
- **Tweak Kernel:**
  - Buka Device Manager > Network Adapters / Display Adapters.
  - Klik kanan Properties > Details > Location Path.
  - Cek path **`PCIROOT...`**. Buka Regedit di **`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\...`** sesuai path tadi.
  - Cari key **`Device Parameters\Interrupt Management\MessageSignaledInterruptProperties`**.
  - Ubah **`MSISupported`** dari **`0`** menjadi **`1`**.
  - _Hasil:_ Input lag berkurang, latency network & GPU turun.

## **19 Network Throttling**

- **Detil Teknis:** Windows membatasi throughput jaringan untuk memprioritaskan multimedia, tapi seringkali salah kalkulasi.
- **Tweak Kernel:**
  - Regedit: **`HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile`**.
  - Cari **`NetworkThrottlingIndex`**. Ubah value ke **`FFFFFFFF`** (Hexadecimal).
  - _Hasil:_ Windows tidak akan "nahan" paket data, ping lebih stabil, download lebih kencang.

## **20 GPU HAGS**

- **Detil Teknis:** CPU biasanya ngatur scheduling GPU. GPU modern (RTX series ke atas) bisa ngurus sendiri lebih cepat.
- **Tweak Kernel:**
  - Regedit: **`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\GraphicsDrivers`**.
  - Buat DWORD **`HwSchMode`**, isi value **`2`**.
  - Atau aktifkan via Settings > System > Display > Graphics > Change Default Graphics Settings.
  - _Hasil:_ Beban CPU berkurang, manajemen VRAM lebih efisien, FPS lebih stabil.

## **21 Nagle Algorithm**

- **Masalah:** Windows menahan paket data kecil untuk digabung jadi paket besar (Nagle Algorithm) guna hemat bandwidth.
- **Detil:** Di gaming, ini buruk. Tombol yang kamu tekan sedikit ditahan sebelum dikirim ke server. Ini terasa "floaty".
- **Solusi (Registry):**
  - Regedit: **`HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSMQ\Parameters`**.
  - Buat DWORD **`TcpNoDelay`**, value **`1`**.
  - Lakukan juga di **`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{Interface-ID}`**. Tambahkan DWORD **`TcpAckFrequency`** = **`1`**.

## **22 Visual Effects**

- **Masalah:** Animasi fade, slide, dan shadow di Windows memakan overhead GPU dan CPU.
- **Detil:** Pada PC tanpa GPU dedicated, animasi ini menyebabkan "laggy" feeling saat membuka/menutup jendela.
- **Solusi:** Ketik **`sysdm.cpl`** > Tab Advanced > Performance Settings. Pilih **"Adjust for best performance"** atau centang minimalis: _Show thumbnails, Smooth edges of screen fonts_.

## **23 Power Plan**

- **Masalah:** Power Plan "Balanced" seringkali membatasi kecepatan CPU (throttling) untuk hemat daya.
- **Detil:** CPU sering turun ke clock speed rendah saat beban naik turun, menyebabkan delay.
- **Solusi:** Aktifkan **"Ultimate Performance"** power plan (hidden) via CMD: **`powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61`**. Set _Minimum Processor State_ ke 100% agar CPU selalu siaga.

## **24 USB Selective Suspend**

- **Masalah:** Windows mematikan daya ke port USB untuk hemat energi, terutama pada laptop.
- **Detil:** Saat kamu diam sebentar lalu menyentuh mouse, ada jeda 1-2 detik sebelum cursor bergerak karena USB port baru "bangun". Ini sering disalahartikan sebagai mouse lag.
- **Solusi:** Buka **Control Panel > Hardware and Sound > Power Options > Change plan settings > Change advanced power settings**. Buka **USB Settings > USB selective suspend setting**. Set menjadi **Disabled**. Ini membuat mouse/keyboard selalu siaga tanpa jeda.

## **25 Mouse Precision**

- **Masalah:** Fitur aksesibilitas yang secara default nyala, memproses gerakan mouse untuk "menghaluskan"nya.
- **Detil:** Fitur "Enhance Pointer Precision" menambah lapisan kalkulasi antara gerakan tangan dan cursor di layar. Untuk desainer/gamer, ini terasa "floaty" atau tidak akurat.
- **Solusi:** Buka **Control Panel > Mouse > Pointer Options**. **Uncheck** "Enhance pointer precision". Lalu di **Control Panel > Ease of Access > Make the keyboard easier to use**, pastikan **uncheck** "Turn on Filter Keys". Ini menghapus delay software pada input.

## **26 Shell Extensions**

- **Masalah:** Menu klik kanan lambat karena banyak entri dari software lama (misal: Open with Notepad++, Upload to Dropbox, Scan with AV).
- **Detil:** Windows harus load library (.dll) dari software tersebut setiap kali menu konteks dibuka.
- **Solusi:** Gunakan freeware **ShellExView**. Disable extension yang statusnya "No" di kolom "Microsoft Approved" atau yang tidak perlu.

## **27 Explorer Quick Access**

- **Masalah:** File Explorer default menampilkan folder yang sering dibuka di "Quick Access".
- **Detil:** Jika ada file yang corrupt atau lokasi jaringan yang sudah tidak bisa diakses di riwayat Quick Access, File Explorer akan "freeze" sebentar setiap kali dibuka sambil menunggu _timeout_.
- **Solusi:** Buka **File Explorer > View > Options**. Pada bagian "Privacy", **Uncheck** "Show recently used files in Quick Access" dan "Show frequently used folders in Quick Access". Klik **Clear** File Explorer History. Ini membuat folder membuka instan tanpa loading riwayat.

## **28 Indexing Service**

- **Masalah:** **`Windows Search`** mengindex seluruh file di PC, memakan disk I/O terus menerus.
- **Detil:** Saat kamu mendownload file besar atau copy data, indexing ikut bekerja keras di belakang.
- **Solusi:** Matikan indexing di drive Data (D:/E:), biarkan hanya di drive System (C:). Atau stop service **`WSearch`** total jika kamu jarang mencari file.

## **29 Registry Optimization**

- **Masalah:** Setelah install/uninstall software berulang kali, registry menjadi bengkak dengan _invalid keys_ dan _broken links_.
- **Detil:** Windows harus memuat database Registry ke memori saat boot. Ukuran registry yang besar memperlambat proses ini.
- **Solusi:** Gunakan tools terpercaya untuk menghapus _invalid entries_, atau secara manual bersihkan key **`HKEY_LOCAL_MACHINE\SOFTWARE`** dan **`HKCU\SOFTWARE`** dari sisa software yang sudah di-uninstall.

## **30 Game Mode Bar**

- **Masalah:** Windows merekam gameplay di background (DVR) untuk fitur "Replay".
- **Detil:** Fitur ini makan resource HDD/SSD I/O dan GPU secara diam-diam.
- **Solusi:** Matikan total di Settings > Gaming. Atau uninstall via PowerShell: **`Get-AppxPackage *Microsoft.XboxGamingOverlay* | Remove-AppxPackage`**.
