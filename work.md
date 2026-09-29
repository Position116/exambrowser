# work.md — Konteks Pengerjaan ExamBrow

> **Untuk agent sesi berikutnya:** BACA FILE INI DULU sebelum menganalisis project.
> Semua konteks, path, keputusan, dan fix ada di sini.

## 1. Aturan dari User (WAJIB DIPATUHI)

1. Jangan over-engineering, keep it simple
2. Kalau bingung, JANGAN berasumsi — tanya user (pakai ask_user)
3. Jangan buat perubahan random yang tidak penting
4. Selalu double-check hasil kerja (baca ulang, jalankan analyze/test/build)
5. Catat Semua Perubahan dan Berikan Solusi Editing Setiap File jika ada eror atau perubahan

Komunikasi dalam **Bahasa Indonesia**.

## 2. Ringkasan Project

- **Nama:** ExamBrow — kiosk exam browser untuk ujian online
- **Cara kerja:** Input URL server ujian (sudah ada, bukan buat backend) + PIN pengawas →
  webview fullscreen kiosk yang hanya boleh membuka host server ujian → keluar hanya dengan PIN
- **Tech:** Flutter 3.47.5 (stable), satu codebase untuk Windows/Android/iOS
- **Lokasi project:** `D:\Project Web\ExamBrow`
- **Spesifikasi minimal Android:** Android 10 (API 29) & RAM 4GB (cek runtime,
  ambang batas 3584 MB — lihat bagian 5 poin 9)

### File kode (buatan kita, di `lib/`)
| File | Isi |
|---|---|
| `lib/main.dart` | Entry point + window_manager setup (judul, min size 800x600) |
| `lib/settings_screen.dart` | Form URL server (tersimpan via shared_preferences, key: `server_url`); header "Exam Browser" + footer "CopyRight Ronald Aveiro"; TANPA input PIN |
| `lib/exam_screen.dart` | Webview kiosk: whitelist host, PopScope blokir back, WindowListener blokir close Windows, dialog PIN keluar, tombol gembok kecil pojok kanan-bawah (opacity 0.35), inject JS blokir copy-paste/seleksi teks (`_blockClipboardJs` via `onLoadStop`), kiosk Android (lihat bagian 5 poin 10), logout paksa saat layar HP dimatikan >5 dtk (poin 17) |
| `lib/update_service.dart` | Auto-update: cek GitHub Releases + layar update wajib (unduh APK + buka installer) |
| `lib/device_status_bar.dart` | Bar status bawah layar: jaringan REALTIME (warna: hijau WiFi/Ethernet, oranye seluler, merah offline, abu tak-diketahui) + nama perangkat + versi OS + RAM (Android only, via MethodChannel getTotalRamMb) |
| `test/widget_test.dart` | Test halaman pengaturan (LULUS) |
| `SETUP.md` | Panduan setup untuk user |
| `EXAM_SYSTEMS.md` | Katalog sistem ujian online (ANBK/CBT/Moodle dll) + cara isi URL whitelist |
| `windows/CMakeLists.txt` | +1 baris fix coroutine (lihat bagian 5) |
| `android/.../MainActivity.kt` | + FLAG_SECURE (blokir screenshot/rekaman layar) + MethodChannel `exam_brow/device_info` (getTotalRamMb) + MethodChannel `exam_brow/kiosk` (start/stop/isDeviceOwner: KEEP_SCREEN_ON + Lock Task Mode penuh bila device owner, fallback pinning; blokir overlay via DISALLOW_CREATE_WINDOWS) |
| `android/.../ExamAdminReceiver.kt` + `res/xml/device_admin.xml` | Device admin minimal — syarat provisioning device owner (`dpm set-device-owner`, poin 18) |
| `tool/gen_icon.ps1` + `assets/icon/` | Generator icon (PowerShell System.Drawing) + PNG sumber icon |
| `windows/runner/kiosk_hardening.h/.cpp` | Hardening kiosk Windows: DisableTaskMgr + NoWinKeys via registry HKCU, backup/restore + self-heal (poin 18) |
| `windows/runner/resources/app_icon.ico` | Icon Windows (generate otomatis, JANGAN edit manual) |

### Dependencies (pubspec.yaml)
- `flutter_inappwebview: ^6.1.5` (webview; Windows pakai endorsed package `flutter_inappwebview_windows 0.6.0` + WebView2 + **butuh nuget.exe**)
- `window_manager: ^0.4.3`
- `shared_preferences: ^2.3.2`
- `connectivity_plus: ^7.3.1` (jaringan realtime; API v7 = List<ConnectivityResult>)
- `device_info_plus: ^13.2.0` (nama perangkat + versi OS)
- `flutter_lints: ^5.0.0`
- `flutter_launcher_icons: ^0.14.4` (dev; config di pubspec.yaml, key `flutter_launcher_icons`)

(catatan: `cupertino_icons` sudah dihapus dari pubspec karena tidak terpakai)

### PIN keluar aplikasi: `123456` (TETAP — tidak bisa diubah dari UI; input PIN
di halaman depan sudah DIHAPUS per permintaan user 25 Sep 2026)

## 3. Toolchain Terinstall (lokasi & versi PENTING)

| Tool | Lokasi | Catatan |
|---|---|---|
| Flutter 3.47.5 | `C:\src\flutter\bin` | Sudah di User PATH. Kalau bash sesi ini tidak kenal `flutter`, export: `export PATH="/c/src/flutter/bin:$PATH"` |
| Git | `C:\Program Files\Git` | Di Machine PATH |
| JDK 17 (Temurin 17.0.20.1+1) | `C:\tools\jdk-17.0.20.1+1` | Tidak di PATH; Flutter sudah diarahkan via `flutter config --jdk-dir` |
| Android SDK | `C:\Android\Sdk` | platform-tools, platforms/android-36, build-tools/36.1.0, cmdline-tools/latest (**v19.0 — DOWNGRADED, jangan upgrade!**) |
| cmdline-tools | `C:\Android\Sdk\cmdline-tools\latest` | Versi 13114758 (v19.0). Versi terbaru (16111833) CRASH di Gradle (0xC0000409) |
| nuget.exe | `C:\tools\nuget\nuget.exe` | Di User PATH. Wajib untuk build Windows (plugin inappwebview) |
| VS Build Tools 2026 (18.10.0) | `C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools` | Workload C++ OK, TAPI lihat fix coroutine |
| Licenses SDK | `C:\Android\Sdk\licenses\` | Diisi manual: android-sdk-license (3 hash) + android-sdk-preview-license |

### flutter doctor (terakhir): semua [√] kecuali tidak ada Android Studio/emulator (tidak masalah, build CLI jalan)

## 4. Status Build (per 28 Sep 2026)

| Target | Status | Output |
|---|---|---|
| `flutter analyze` | ✅ 0 issue | — |
| `flutter test` | ✅ lulus | — |
| **Windows release** | ✅ BERHASIL ulang 25 Sep 2026 malam (v0.1.3: footer logo © + tanpa PIN depan) | `build\windows\x64\runner\Release\exam_brow.exe` |
| **Android APK release** | ✅ BERHASIL — fat 48.2 MB (3 ABI); **pakai versi split-per-abi**: arm64 17.9 MB (vivo 1918), armeabi-v7a 15.3 MB, x86_64 19.2 MB | `build\app\outputs\flutter-apk\app-<abi>-release.apk` |
| iOS | ⛔ TIDAK BISA dari Windows (butuh Mac+Xcode) | folder `ios/` sudah ada & siap |
| **Release GitHub v0.1.3** | ✅ TERBIT lengkap 28 Sep 2026 | arm64 19,4 MB + v7a 16,8 MB + win zip 12,4 MB; signature APK = keystore permanen (SHA-256 match, terverifikasi apksigner) |

## 5. Masalah yang Sudah Dipecahkan (jangan diulang/error sama)

1. **VS 2026 menolak experimental/coroutine** plugin inappwebview_windows 0.6.0 →
   fix: di `windows/CMakeLists.txt` ditambah:
   `add_compile_definitions(_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)`
2. **Build Windows butuh nuget** → install ke `C:\tools\nuget`
3. **sdkmanager versi terbaru crash di Gradle** (0xC0000409) → downgrade ke cmdline-tools 13114758 (v19.0)
4. **Lisensi SDK tidak lengkap** → isi manual hash ke `C:\Android\Sdk\licenses\`
5. **Plugin flutter_inappwebview_android 1.1.3 pakai proguard-android.txt** (ditolak AGP baru) →
   ⚠️ PATCH DI PUB CACHE: `$LOCALAPPDATA/Pub/Cache/hosted/pub.dev/flutter_inappwebview_android-1.1.3/android/build.gradle`
   baris 44 & 48 diganti `proguard-android-optimize.txt`.
   ⚠️ Patch ini HILANG jika `flutter pub cache repair` / re-install plugin.
6. **Kotlin incremental cache korup** (shared_preferences_android) → hapus cache + `kotlin.incremental=false` di `android/gradle.properties`
7. **Manifest Android** → ditambah `<uses-permission android:name="android.permission.INTERNET"/>` (WAJIB untuk webview release) + label "ExamBrow"
8. **Icon aplikasi** → sumber: `assets/icon/app_icon.png` (topi wisuda, latar indigo #3F51B5,
   dibuat via `tool/gen_icon.ps1` karena ImageMagick tidak ada). Diterapkan ke Android
   (termasuk adaptive) + iOS + Windows pakai `flutter_launcher_icons 0.14.4`.
   Regenerate: `dart run flutter_launcher_icons`.
9. **Spesifikasi minimal Android** ✅ (25 Sep 2026):
   - **Android 10**: `minSdk = 29` hardcoded di `android/app/build.gradle.kts`
     (bukan `flutter.minSdkVersion`). HP < Android 10 otomatis tidak bisa install APK
     (terverifikasi via `aapt2 dump badging` → minSdkVersion:'29').
   - **RAM 4GB**: tidak ada mekanisme manifest Android untuk menolak install berdasar RAM,
     jadi dicek runtime: MethodChannel `exam_brow/device_info` (getTotalRamMb) di
     MainActivity.kt → `DeviceGate` di `lib/main.dart`. Di bawah 3584 MB (3,5 GB,
     toleransi karena HP 4GB terbaca ~3,5-3,8 GB) → layar blokir total
     (`_BlockedSpecScreen`), tidak bisa lanjut. Jika pembacaan RAM gagal
     (PlatformException/MissingPluginException) → aplikasi tetap jalan (fail-open).
   - Keputusan user: blokir total (bukan peringatan), threshold 3,5 GB (bukan 4096 MB).
10. **Kiosk mode Android** ✅ (25 Sep 2026, setelah feedback user: bisa buka app lain +
    lock screen muncul saat ujian):
    - `exam_brow/kiosk` MethodChannel di MainActivity.kt: `start` = FLAG_KEEP_SCREEN_ON
      (layar selalu menyala → HP tidak sleep → lock screen tidak muncul) + `startLockTask()`
      (screen pinning: home/recents tidak bisa keluar); `stop` = clear flag + `stopLockTask()`.
    - `exam_screen.dart`: `_enterKiosk`/`_exitKiosk` panggil channel saat Platform.isAndroid,
      plus `SystemUiMode.immersiveSticky` (status bar & nav bar disembunyikan; kembali masuk
      `edgeToEdge` saat keluar). Gagal kiosk → tetap jalan (fail-open, hanya whitelist webview).
    - CATATAN: bukan device owner, jadi pinning mode standar — Android bisa menampilkan
      toast "untuk melepas pin, tahan Back + Recents". Untuk pinning tanpa toast perlu
      device owner (dmode) / Lock Task Mode penuh — belum dikerjakan.
    - Branding: header AppBar "Exam Browser" (dulu "ExamBrow") + footer copyright di
      settings_screen.dart; test widget_test.dart ikut di-update.
11. **Ukuran APK** ✅ (25 Sep 2026): user tanya kenapa APK 48 MB vs aplikasi CBT lain 14 MB.
    Analisis: APK referensi (com.cbt.sims) BUKAN Flutter (tidak ada libflutter.so, native
    app kecil); APK Flutter default = fat APK 3 ABI (arm64+v7a+x86_64). Solusi:
    `flutter build apk --release --split-per-abi` → arm64 17.9 MB (-63%). HP target
    arm64-v8a → install app-arm64-v8a-release.apk. Batas bawah wajar Flutter ~8-9 MB
    (engine). Sisa ukuran: engine + plugin inappwebview.
12. **Auto-update Android** ✅ implementasi (25 Sep 2026): keputusan user = hosting di
    **GitHub Releases** + perilaku **wajib/paksa update**. Implementasi:
    - `lib/update_service.dart`: `checkForUpdate()` cek
      `api.github.com/repos/<repo>/releases/latest`, bandingkan semver vs
      packageInfo.version, pilih asset APK arm64-v8a (fallback .apk pertama).
      Gagal cek (offline/rate-limit 60/jam/repo salah) → return null (fail-open).
    - `UpdateScreen` (di file sama): layar update WAJIB tak bisa ditutup — unduh
      otomatis via dio (progress bar), lalu `OpenFilex.open(apk)` → installer Android
      (user tap "Install"). Gagal unduh → tombol Coba Lagi.
    - `main.dart` DeviceGate: setelah gate RAM lolos, Android cek update; ada versi
      baru → tampilkan UpdateScreen sebelum SettingsScreen.
    - AndroidManifest: + `REQUEST_INSTALL_PACKAGES` + FileProvider
      (`${applicationId}.fileProvider`) dengan `res/xml/file_paths.xml`.
    - Deps baru: package_info_plus, dio, open_filex, path_provider.
    - ⚠️ `kUpdateRepo = 'ronaldaveiro/exambrow'` masih PLACEHOLDER — menunggu nama
      repo GitHub asli dari user. Panduan rilis lengkap di SETUP.md (naikkan
      version+versionCode di pubspec → build split-per-abi → upload APK ke Release
      dengan tag = versionName).
13. **Perubahan PIN + perbaikan CI** ✅ (25 Sep 2026):
    - Input PIN di halaman depan DIHAPUS (user request); PIN keluar mode ujian
      TETAP `123456` via `kSupervisorPin` di exam_screen.dart (tidak dari UI).
    - CI release workflow: build pertama GAGAL (error proguard plugin — patch
      pub cache tidak ada di CI), percobaan ke-2 GAGAL (patch jalan SEBELUM
      pub get → folder plugin belum ada). Fix: step `flutter pub get` eksplisit
      SEBELUM patch + pin `flutter-version: 3.47.5`. Run ke-3 SUKSES.
    - Release v0.1.2 terbit otomatis via CI (assets: exambrow-v0.1.2-arm64-v8a.apk,
      exambrow-v0.1.2-armeabi-v7a.apk). Repo: Position116/exambrowser (public).
    - Alur rilis ke depan: bump version di pubspec.yaml → commit → tag vX.Y.Z →
      push → CI build+release otomatis → HP lama update sendiri saat buka app.
    - Uji E2E auto-update: DILAKUKAN dgn jalur berbeda (28 Sep 2026): app lama
      v0.1.2 di HP mendeteksi v0.1.3, unduh APK OK, installer terbuka; install
      DITOLAK Android (UPDATE_INCOMPATIBLE — transisi debug→key permanen,
      lihat poin 15). Mekanisme deteksi+unduh+buka-installer TERBUKTI jalan;
      uji timpa-langsung (tanpa uninstall) bermakna mulai v0.1.4.
14. **APK harus uninstall dulu + footer copyright** ✅ diperbaiki (26 Sep 2026):
    - Penyebab harus uninstall: release build memakai `debug` signing key.
      Tiap run CI generate debug keystore baru → tanda tangan beda tiap rilis →
      Android menolak timpa (`UPDATE_INCOMPATIBLE`) → harus uninstall dulu.
    - Fix: keystore permanen `android/app/exambrow-release.jks` (alias `exambrow`,
      validitas 30 thn, TIDAK di-commit — repo public!). Kredensial di
      `android/key.properties` (gitignored). `android/app/build.gradle.kts`
      pakai key permanen bila file ada, fallback debug bila tidak ada.
      CI (release.yml) memulihkan keystore dari secret `ANDROID_KEYSTORE_BASE64`
      + menulis key.properties dari secret `ANDROID_KEYSTORE_PASSWORD`,
      `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`.
    - ✅ 4 secret GitHub SUDAH DIISI (28 Sep 2026, manual via browser:
      ANDROID_KEYSTORE_BASE64 satu baris via clip.exe + 3 kredensial dari
      key.properties) → CI v0.1.3 re-run SUKSES (detail di poin 15).
      Nilai password ada di laptop (key.properties); base64: jalankan
      `certutil -encode android\app\exambrow-release.jks %TEMP%\ks.b64`
      lalu isi file itu sebagai secret (satu baris).
    - ⚠️ Install lama (debug-signed: v0.1.0/v0.1.1/v0.1.2) TIDAK bisa ditimpa
      APK key baru (tanda tangan beda = aturan Android, tidak bisa diakali) →
      user WAJIB uninstall manual SATU KALI TERAKHIR ke v0.1.3. Setelah itu
      semua update berikutnya (sama-sama key baru) bisa timpa langsung.
    - Footer settings_screen.dart: teks `CopyRight Ronald Aveiro` → logo
      `Icon(Icons.copyright)` + teks `Ronald Aveiro` (Row, center).
    - Versi di-bump ke `0.1.3+4` (arm64 versionCode 2004, terverifikasi via
      `aapt2 dump badging`). Status rilis v0.1.3: ✅ TERBIT lengkap
      (28 Sep 2026, lihat poin 15).
15. **Windows masuk GitHub Release** ✅ workflow (26 Sep 2026, BELUM rilis):
    - `release.yml`: job `release` → `android`, tambah job `windows`
      (`windows-latest`): Flutter 3.47.5 + `pub get` + `choco install
      nuget.commandline` (wajib plugin inappwebview) + `flutter build windows
      --release` + zip isi folder Release → `exambrow-vX.Y.Z-windows-x64.zip`
      → upload ke Release yang sama via softprops/action-gh-release.
    - Alasan zip: exe saja tidak jalan (butuh `flutter_windows.dll`, plugin
      dll, folder `data/`). User Windows: ekstrak zip → jalankan exe.
    - Build Windows lokal v0.1.3 terverifikasi: exe + flutter_assets fresh.
      Syarat build lokal: Developer Mode ON + nuget di PATH.
    - Status: workflow BELUM di-push; ikut terbang saat commit+tag v0.1.3
      (butuh 4 secret Android tetap diisi, kalau tidak job android gagal).
    - HASIL CI v0.1.3 (run 36159007710): job `windows` ✅ SUKSES —
      `exambrow-v0.1.3-windows-x64.zip` (12,4 MB) sudah terbit di Release v0.1.3.
      Job `android` ❌ GAGAL di step "Build APK" (restore keystore exit 0 tapi
      kemungkinan secret kosong/rusak → keystore tak valid). APK Android v0.1.3
      BELUM ada. Efek samping: `releases/latest` = v0.1.3 tanpa asset APK →
      `checkForUpdate()` return null (fail-open) → HP tidak melihat update
      sampai APK terbit. Perbaikan: isi/cek 4 secret → re-run failed jobs →
      APK ter-upload ke Release yang sama (tanpa tag baru).
    - ✅ SELESAI (28 Sep 2026): 4 secret diisi manual via browser
      (base64 keystore via clip.exe + 3 password dari key.properties) →
      Re-run failed jobs → attempt 3 SUKSES. Verifikasi APK arm64 dari Release:
      versionName=0.1.3, versionCode=2004, native-code arm64-v8a (aapt2);
      signature SHA-256 = c4eb1aeb...f8122594 = SAMA dengan keystore lokal
      (apksigner verify --print-certs, butuh JAVA_HOME di PATH untuk jalan).
      Release v0.1.3 KOMPLET: arm64 19,4 MB + v7a 16,8 MB + windows zip 12,4 MB.
      Auto-update sekarang berfungsi: HP dgn app lama akan melihat v0.1.3 + APK.
      MASIH WAJIB: user uninstall manual app lama (debug-signed) SATU KALI
      sebelum install v0.1.3; setelah itu update v0.1.4+ bisa timpa langsung.
    - UJI E2E AUTO-UPDATE dari v0.1.2 → v0.1.3 (28 Sep 2026, HP user): ✅ 3 dari
      4 langkah BERHASIL — update terdeteksi, APK terunduh otomatis, installer
      terbuka. Install DITOLAK Android dgn "paket ini bentrok dengan paket yang
      sudah ada" (INSTALL_FAILED_UPDATE_INCOMPATIBLE) = PERILAKU DUGA (debug key
      v0.1.2 ≠ key permanen v0.1.3), bukan bug. Solusi: uninstall 1x lalu install
      v0.1.3 manual. Mekanisme update (deteksi+unduh+buka installer) TERBUKTI jalan;
      uji install-langsung-tanpa-uninstall baru bermakna di v0.1.4 (key sama).
    - UJI MANUAL v0.1.3 LENGKAP LOLOS (28 Sep 2026, vivo 1918, tanpa kabel):
      semua checklist lolos — install, settings (header/footer/URL persist),
      whitelist, blokir back, kiosk (HOME/RECENTS + keep-screen-on + fullscreen),
      FLAG_SECURE (screenshot + screen record), blokir copy-paste, PIN keluar
      (salah ditolak, 123456 lolos). Detail per item di bagian 7.
    - UJI WINDOWS v0.1.3 LOLOS (28 Sep 2026): rebuild fresh (51,4s, Developer
      Mode + nuget OK; warning CMake CMP0175 dari plugin inappwebview =
      harmless) lalu exam_brow.exe diuji: icon + judul, header/footer, URL
      persist, fullscreen, whitelist, blokir copy/seleksi, tombol X diblokir
      saat ujian (WindowListener), PIN keluar (salah ditolak, 123456 lolos) —
      SEMUA LOLOS. Peluncuran dari Git Bash: `cmd //c start "" exam_brow.exe`
      timeout 15s tapi app jalan (quirk pipe Git Bash; cek via tasklist).
16. **Bar status perangkat + jaringan realtime** ✅ (28 Sep 2026, v0.1.4+5):
    - Permintaan user: "pada layar bagian bawah tambahkan deteksi perangkat,
      termasuk deteksi jaringan realtime" → ditampilkan di KEDUA layar
      (exam: bawah webview via Column+Expanded; settings: bottomNavigationBar).
    - Isi bar (user pilih via ask_user): jaringan realtime + nama perangkat +
      versi OS + RAM. Gaya: bar berwarna mengikuti status jaringan.
    - API connectivity_plus v7: checkConnectivity() & onConnectivityChanged
      mengembalikan List<ConnectivityResult> (bukan single value seperti v4).
      Subscribe dulu baru cek kondisi awal supaya tidak ada event terlewat.
    - Fail-open: baca info gagal → segmen disembunyikan, app jalan normal.
    - Permission ACCESS_NETWORK_STATE TIDAK perlu ditambah manual — otomatis
      ter-merge dari manifest plugin connectivity_plus.
    - Windows: nama = info.computerName, OS = info.productName; RAM segmen
      hanya Android (MethodChannel exam_brow/device_info getTotalRamMb).
    - Uji Windows LOLOS: bar muncul di kedua layar, realtime offline/online.
    - Android v0.1.4: build arm64 sukses (18,7 MB), verifikasi aapt2
      versionName=0.1.4 versionCode=2005, apksigner = keystore permanen
      (c4eb...2594) → bisa timpa v0.1.3 TANPA uninstall. Rilis via CI + tag
      v0.1.4 → sekaligus uji auto-update timpa langsung di HP.
    - HASIL AKHIR v0.1.4 di vivo 1918 (28 Sep 2026): CI run 36376360598
      SUKSES, Release v0.1.4 lengkap (arm64+v7a+win zip); auto-update
      v0.1.3→v0.1.4 TERPASANG TANPA uninstall (signature sama — alur
      auto-update SELESAI teruji penuh); bar status tampil di kedua layar:
      WiFi realtime + nama perangkat + versi Android + RAM ~3,8 GB.
      Backlog "uji timpa langsung" TUTUP.
    - ⚠️ PELAJARAN BUILD: app Windows yang masih berjalan mengunci file di
      folder Release → build baru GAGAL menyalin data TANPA error → app jalan
      versi lama/stale. WAJIB `taskkill //IM exam_brow.exe //F` SEBELUM
      `flutter build windows --release`.
17. **Logout paksa saat layar HP dimatikan** ✅ (29 Sep 2026, v0.1.5+6):
    - Permintaan user: saat ujian berjalan, jika layar HP dimatikan (tombol
      power) → aplikasi memulai ulang dari login (logout) — fitur keamanan
      supaya anak tetap fokus ke HP dan tidak "menghilang" dari ujian.
    - Keputusan user (via ask_user): sesi web server ujian IKUT dihapus
      (cookies + web storage) → anak harus login ulang di situs ujian.
    - Implementasi DI lib/exam_screen.dart SAJA (tanpa ubah kode native):
      `WidgetsBindingObserver.didChangeAppLifecycleState` — layar Android
      mati → state `paused` (timestamp `_leftForegroundAt`); saat `resumed`,
      jika durasi > 5 detik (`_screenOffGraceSeconds`, masa tenggang untuk
      layar mati sesaat mis. dialog konfirmasi pinning) → `_forceLogout()`:
      `_exitKiosk()` (stopLockTask + edgeToEdge) → hapus sesi via
      `CookieManager().deleteAllCookies()` + `WebStorageManager().deleteAllData()`
      (API terverifikasi ada di flutter_inappwebview 6.1.5) →
      `Navigator.popUntil(route.isFirst)` balik ke settings + menutup dialog
      PIN bila terbuka. TANPA PIN — inilah tujuannya.
    - Guard `Platform.isAndroid` di awal handler → Windows desktop tidak
      pernah `paused` oleh layar mati, otomatis tidak terpengaruh.
    - Fail-open: gagal hapus cookies/storage di-catch → tetap keluar mode
      ujian. Efek samping positif: lepas pin via gesture vivo + buka app
      lagi (>5 dtk) juga logout.
    - Verifikasi: analyze 0 issue, test lulus, build arm64 OK (versionName
      0.1.5 / versionCode 2006 via aapt2, signature c4eb1aeb...2594 = keystore
      permanen → bisa timpa v0.1.4 tanpa uninstall), build Windows OK.
    - Catatan toolchain: apksigner di Windows = `apksigner.bat` (bukan binary
      tanpa ekstensi); panggil via `cmd //c` dgn JAVA_HOME JDK 17 di PATH.
18. **Hardening kiosk setara Safe Exam Browser** ✅ (29 Sep 2026, v0.1.6+7):
    - Keputusan user (via ask_user): (a) Android pakai Lock Task Mode penuh
      via device owner dgn fallback pinning, (b) Windows kunci Task Manager
      + tombol Win saat ujian via registry HKCU, (c) ada layar status
      provisioning di app.
    - ANDROID (device owner = Lock Task Mode penuh, tanpa toast unpin):
      - File BARU `ExamAdminReceiver.kt` (DeviceAdminReceiver minimal) +
        `res/xml/device_admin.xml` (uses-policies: force-lock) + receiver di
        AndroidManifest (BIND_DEVICE_ADMIN) — syarat `dpm set-device-owner`.
      - MainActivity.kt channel `exam_brow/kiosk`: method BARU `isDeviceOwner`
        (dpm.isDeviceOwnerApp); `start` = bila device owner: setLockTaskPackages
        + addUserRestriction(DISALLOW_CREATE_WINDOWS = blokir overlay app
        lain) + startLockTask() (mode penuh); else fallback pinning standar
        (perilaku lama). `stop` = clearUserRestriction + stopLockTask.
      - Provisioning SEKALI per HP via adb (HP tanpa akun Google):
        `adb shell dpm set-device-owner com.example.exam_brow/.ExamAdminReceiver`
        — panduan lengkap di SETUP.md.
    - WINDOWS (registry HKCU, tanpa admin):
      - File BARU `kiosk_hardening.h/.cpp`: Apply() pasang DisableTaskMgr
        (Policies\System) + NoWinKeys (Policies\Explorer) sambil BACKUP nilai
        lama ke HKCU\Software\ExamBrow\KioskHardening; Revert() pulihkan
        persis; CleanupOrphans() bersihkan sisa lock sesi crash (dipanggil
        di OnCreate). OnDestroy runner juga Revert() (jaminan terakhir).
      - flutter_window.cpp: MethodChannel `exam_brow/kiosk` (lock/unlock) di
        sisi runner; exam_screen.dart `_enterKiosk`/`_exitKiosk` desktop
        kini invoke lock/unlock.
      - Keterbatasan OS: Ctrl+Alt+Del tidak bisa diblokir app manapun →
        solusi lab resmi: Assigned Access (dicatat di SETUP.md).
    - DART: settings_screen.dart kartu status kiosk Android (hijau "Kiosk
      penuh aktif (device owner)" / oranye "Kiosk standar (screen pinning)"
      + perintah adb SelectableText). Guard Platform.isAndroid — Windows/iOS
      tidak tampil.
    - PELAJARAN BUILD: file .cpp baru WAJIB didaftarkan di
      `windows/runner/CMakeLists.txt` (add_executable); include
      `<flutter/method_channel.h>` + `<flutter/standard_method_codec.h>` di
      flutter_window.h bila pakai MethodChannel di header; `<string>` untuk
      std::wstring. Error khas: C2059 (missing include), LNK2019 (file tidak
      terdaftar).
    - Verifikasi: analyze 0 issue, test lulus, build arm64 OK (versionName
      0.1.6 / versionCode 2007, signature c4eb1aeb...2594 = keystore
      permanen), build Windows OK setelah 3x fix di atas.

## 6. Command Cepat untuk Lanjut Kerja

```bash
# Regenerate icon (setelah edit assets/icon/*.png):
dart run flutter_launcher_icons

# Windows build/run:
export PATH="/c/src/flutter/bin:/c/tools/nuget:$PATH"
cd "/d/Project Web/ExamBrow" && flutter run -d windows

# Android build:
export PATH="/c/src/flutter/bin:$PATH"   # JAVA_HOME & JDK sudah via flutter config
cd "/d/Project Web/ExamBrow" && flutter build apk --release

# Cek sehat:
flutter analyze && flutter test && flutter doctor
```

Catatan bash Windows: argumen sdkmanager pakai `/` bukan `;` (mis. `platforms/android-36`),
`;` terpotong oleh bash. Terminal user = Git Bash (win32).
Build Windows butuh Developer Mode ON (untuk symlink plugin) + nuget di PATH:
`start ms-settings:developers` → nyalakan → `flutter build windows --release`.

## 7. Yang Belum Dikerjakan / Kandidat Lanjutan

- [x] Uji manual APK v0.1.3 di HP ✅ LENGKAP (28 Sep 2026, vivo 1918, uji manual tanpa
      kabel — semua checklist lolos):
      install dari Release arm64 tanpa hambatan (setelah uninstall 1x app debug-signed);
      settings: header "Exam Browser" + footer © Ronald Aveiro + URL tersimpan setelah
      app ditutup; webview: navigasi dalam host lancar, link keluar host DIBLOKIR,
      tombol Back HP diblokir (PopScope); kiosk: HOME & RECENTS terkunci, layar tetap
      nyala (KEEP_SCREEN_ON), status/nav bar tersembunyi; FLAG_SECURE: screenshot
      DIBLOKIR + screen record diblokir/hitam; long-press teks: seleksi/copy tidak
      muncul (JS inject); PIN: salah ditolak, 123456 keluar ke settings.
      - Windows build v0.1.3 ✅ DIUJI ULANG (28 Sep 2026): icon topi wisuda,
        header/footer, URL persist, fullscreen, whitelist, blokir copy, blokir
        close (X), PIN keluar — SEMUA LOLOS. Build di-rebuild fresh (51,4s)
        sebelum uji supaya exe pasti = source v0.1.3 (exe lama 3 menit lebih
        tua dari commit terakhir).
      ⚠️ vivo 1918: BACK saat PINNED memicu gesture unpin bawaan (dialog konfirmasi vivo);
      perilaku unpin standar Android untuk pinning non-device-owner, bukan bug aplikasi.
- [x] Uji E2E auto-update ✅ (28 Sep 2026): deteksi update + unduh APK + buka
      installer TERBUKTI jalan (v0.1.2→v0.1.3); install akhir ditolak Android
      karena transisi debug→key permanen (lihat poin 5.15). Timpa langsung
      TANPA uninstall TERBUKTI di v0.1.4 (28 Sep 2026) — alur auto-update
      selesai teruji penuh.
- [x] Blokir copy-paste/screenshot ✅ (25 Sep 2026): JS inject di exam_screen + FLAG_SECURE Android
- [x] Icon aplikasi ✅ (25 Sep 2026): flutter_launcher_icons + assets/icon/
- [x] Uji manual v0.1.5 di HP ✅ LOLOS (29 Sep 2026, konfirmasi user): saat
      ujian berjalan, layar dimatikan >5 dtk → dinyalakan → langsung di layar
      settings (logout tanpa PIN) + sesi login server ujian hangus.
      "sip berfungsi dengan baik" — fitur keamanan layar mati TUNTAS.
- [ ] Uji manual v0.1.6 di HP TANPA provisioning (pinning standar): perilaku
      harus sama seperti v0.1.5 — tidak ada regresi. Kartu status settings
      tampil oranye "Kiosk standar" + perintah adb.
- [ ] Uji provisioning device owner (butuh PC + adb + HP tanpa akun Google):
      jalankan `adb shell dpm set-device-owner com.example.exam_brow/.ExamAdminReceiver`
      → kartu status jadi hijau → mulai ujian → HOME/RECENTS hilang TOTAL,
      tidak ada toast unpin, overlay app lain tidak muncul → keluar PIN →
      kembali normal. Catat: vivo kadang menolak set-device-owner (fallback
      pinning aman).
- [ ] Uji hardening Windows: saat ujian, Ctrl+Shift+Esc TIDAK membuka Task
      Manager, tombol Win tidak jalan; keluar ujian (PIN) → Task Manager &
      Win kembali normal; kill app paksa di tengah ujian → buka app lagi →
      registry pulih otomatis.
- [ ] Deteksi kamera (belum dikerjakan)
- [ ] iOS build (butuh Mac atau Codemagic; akun Apple Developer $99/th untuk distribusi)
- [ ] Catatan keamanan (sudah di SETUP.md): kiosk ini level dasar — bukan setinggi Safe Exam Browser;
      siswa paham komputer masih bisa lewat task manager dsb. Untuk ujian resmi, pertimbangkan
      Assigned Access / pembatasan akun Windows / Guided Access di iOS.
- [ ] Icon aplikasi masih default Flutter (belum diganti)

## 8. Info Sistem User

- Windows 11 25H2, user: `Ronald Aveiro`, locale en-US
- Tidak ada Android Studio / emulator; device Android diuji via APK manual
- Drive D: untuk project & data, C: untuk toolchain

## 9. Register Perubahan (sesi 26 Sep 2026 — SUDAH ter-commit di 763fa5d) + Solusi Edit per File

Status: `M` = modified, `baru` = file baru. Cara cek: `git status --short`.
Sesi 28 Sep 2026 (lanjutan setelah terminal tertutup): hanya `work.md` berubah —
isi 4 secret, re-run CI sukses, verifikasi signature APK, hasil uji E2E update
v0.1.2→v0.1.3 (commit 6720f95, SUDAH di-push ke origin/main).
Lanjutan sesi 28 Sep: uji manual v0.1.3 di vivo 1918 LOLOS SEMUA (detail di
bagian 7) — tercatat di commit berikutnya. `image.png` (gambar aturan dari
user) DIHAPUS dari repo 28 Sep 2026 — working tree bersih.
Lanjutan lagi 28 Sep: fitur bar status (poin 16) → commit 6c57663 (v0.1.4) +
17580d1 (generated plugins), tag v0.1.4 → CI run 36376360598 sukses →
Release v0.1.4 lengkap → uji HP LOLOS SEMUA (auto-update tanpa uninstall +
bar status realtime di kedua layar).
Sesi 29 Sep 2026: fitur logout paksa saat layar HP dimatikan (poin 17) →
commit 23ccfac, tag v0.1.5 → Release v0.1.5 via CI → uji HP oleh user
LOLOS ("sip berfungsi dengan baik") — uji timpa langsung v0.1.4→v0.1.5
juga lulus (signature sama).
Sesi 29 Sep (lanjutan): hardening kiosk setara SEB (poin 18) → commit
9ea48b9, tag v0.1.6, SUDAH di-push → CI build + Release v0.1.6.
⚠️ BELUM dilakukan saat sesi ditutup: (a) verifikasi CI/Release v0.1.6
lengkap, (b) auto-update di HP + uji kartu status (oranye dulu),
(c) provisioning device owner di HP fisik, (d) uji hardening Windows
(Task Manager + Win key). Semua checklist uji ada di bagian 7.

| # | File | Status | Isi perubahan |
|---|---|---|---|
| 1 | `pubspec.yaml` | M | `version: 0.1.2+3` → `0.1.3+4` (versionName 0.1.3, versionCode 4; arm64 jadi 2004) |
| 2 | `lib/settings_screen.dart` | M | Footer `Text('CopyRight Ronald Aveiro')` → `Row` center berisi `Icon(Icons.copyright)` + `Text('Ronald Aveiro')` |
| 3 | `android/app/build.gradle.kts` | M | Signing release permanen dari `android/key.properties` (fallback debug key bila file tidak ada) |
| 4 | `android/key.properties` | baru, gitignored | `storePassword / keyPassword / keyAlias=exambrow / storeFile=exambrow-release.jks` |
| 5 | `android/app/exambrow-release.jks` | baru, gitignored | Keystore RSA 2048 permanen, validitas 30 thn — JANGAN hilang, JANGAN commit |
| 6 | `.gitignore` | M | +3 baris: `android/key.properties`, `android/app/*.jks`, `android/app/*.keystore` |
| 7 | `.github/workflows/release.yml` | M | Step "Restore release keystore" dari 4 secret (Android) + job `windows` baru: build Windows di `windows-latest`, zip → `exambrow-vX-windows-x64.zip`, upload ke Release yang sama |
| 8 | `work.md` | M | Aturan user sesuai gambar + poin 14 + bagian ini |
| 9 | `SETUP.md` | M | Sesuaikan repo `Position116/exambrowser`, alur rilis via CI, syarat 4 secret, catatan uninstall 1x |
| — | `image.png` | untracked | Gambar aturan dari user, BUKAN bagian aplikasi (boleh hapus kapan saja) |

### Solusi edit jika error / ada perubahan

1. **`pubspec.yaml` — update tidak muncul di HP:** pastikan `versionName` DAN
   `+versionCode` keduanya naik (mis. `0.1.3+4`). VersionCode yang tidak naik =
   Android menganggapnya bukan update. Edit langsung angkanya, lalu
   `flutter pub get`.
2. **`settings_screen.dart` — footer tidak center / overflow:** `Row` harus pakai
   `mainAxisAlignment: MainAxisAlignment.center`. Parent `Column` memakai
   `crossAxisAlignment.stretch` sehingga Row otomatis selebar layar → jangan
   bungkus dengan `Expanded`. Cek: `flutter analyze && flutter test`.
3. **`build.gradle.kts` — `Unresolved reference 'util'`:** jangan tulis
   `java.util.Properties()` di dalam blok `android {}`. Solusi: tambah
   `import java.util.Properties` di atas file, deklarasikan `val keyPropsFile`
   dan `val keyProps` di top-level (sebelum blok `android {}`).
4. **`build.gradle.kts` — `Keystore file '.../app/app/exambrow-release.jks' not found`:**
   `file()` di dalam blok `android {}` relatif terhadap folder `android/app`.
   Solusi: isi `storeFile=exambrow-release.jks` (tanpa awalan `app/`) — di
   `key.properties` lokal DAN di step CI `release.yml`.
5. **`key.properties` hilang (clone baru / ganti laptop):** build tetap jalan
   (fallback debug) tapi tanda tangan beda → JANGAN rilis dari mesin itu.
   Solusi: copy `exambrow-release.jks` + `key.properties` dari laptop utama
   (via USB, jangan via email/chat), atau generate ulang + isi ulang secret
   (konsekuensi: user uninstall 1x lagi).
6. **Keystore hilang/rusak TANPA backup:** tidak ada solusi edit — semua update
   gagal timpa selamanya. Satu-satunya jalan: generate key baru + user uninstall
   manual. Pencegahan: backup `.jks` di 2 tempat (laptop + flashdisk).
7. **Keystore tidak sengaja ter-commit (repo public!):** key dianggap bocor.
   Solusi: `git rm --cached android/app/*.jks`, commit, generate keystore BARU,
   update secret, user uninstall 1x lagi.
8. **CI gagal di step restore (`base64: invalid input` / secret kosong):**
   4 secret belum diisi. Solusi: GitHub Settings > Secrets > Actions, isi
   `ANDROID_KEYSTORE_BASE64` (satu baris! Windows: `certutil -encode` lalu
   gabung barisnya), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`,
   `ANDROID_KEY_ALIAS`. Lalu re-run job yang gagal (tidak perlu push baru).
9. **Installer HP tetap minta uninstall setelah v0.1.3:** normal untuk 1x
   transisi (debug → key baru). Solusi: uninstall manual 1x. Kalau MASIH minta
   uninstall di update BERIKUTNYA (v0.1.4+), berarti CI menandatangani dengan
   key berbeda → cek secret CI vs key lokal (bandingkan SHA-256:
   `keytool -list -keystore android\app\exambrow-release.jks`).

## 10. Checklist Backup Keystore (`exambrow-release.jks`)

> Keystore hilang = semua update SELAMANYA gagal timpa (harus uninstall + key
> baru — lihat §9 poin 5-7). Backup WAJIB ada di minimal 2 tempat.
> Dibuat 28 Sep 2026.
>
> ✅ STATUS: TUNTAS (28 Sep 2026) — keystore aman di 3 lokasi berbeda media:
> laptop (aktif) + disk D: + OneDrive cloud + bonus secret GitHub. Flashdisk
> fisik = opsional (Windows tidak mendeteksi flashdisk saat itu).

### File yang di-backup (2 file, satu paket — JANGAN dipisah)
| File | Isi | Ukuran |
|---|---|---|
| `android/app/exambrow-release.jks` | keystore PKCS12, alias `exambrow`, valid 30 thn | 2,7 KB |
| `android/key.properties` | password store & key (rahasia) | 122 B |

Fingerprint pembanding (SHA-256 harus SAMA di semua salinan):
`C4:EB:1A:EB:2A:76:CA:E0:4B:BE:DF:2C:42:56:1B:5E:F9:01:A9:5B:94:A6:CF:2F:A2:AC:9A:C7:F8:12:25:94`

### Langkah backup
- [ ] 1. Colok flashdisk → catat huruf drive (contoh di bawah pakai `E:`)
       *(OPSIONAL — Windows tidak mendeteksi flashdisk, 28 Sep 2026)*
- [ ] 2. Copy kedua file (terminal Git Bash):
       `mkdir -p /e/BackupExamBrow && cp "android/app/exambrow-release.jks" android/key.properties /e/BackupExamBrow/`
       *(terlaksana versi D:: `cp ... /d/BackupExamBrow/` — ✅)*
- [ ] 3. Verifikasi salinan di flashdisk:
       `"/c/tools/jdk-17.0.20.1+1/bin/keytool" -list -keystore /e/BackupExamBrow/exambrow-release.jks`
       → SHA-256 harus cocok dengan fingerprint di atas
       *(terlaksana di D: & OneDrive — ✅ SHA-256 identik `f25be0ea...d98ebcf`)*
- [x] 4. Uji restore: copy balik dari backup ke folder sementara → jalankan
       keytool lagi → hasil cocok → hapus folder sementara *(✅ dari D:,
       fingerprint `C4:EB:...:25:94` cocok)*
- [ ] 5. Label fisik flashdisk: "EXAMBROW KEY — JANGAN HILANG (valid 30 thn)"
       *(OPSIONAL — ikut langkah 1)*
- [x] 6. Lokasi ke-2 (cloud pribadi): ✅ SELESAI via OneDrive — kedua file di
       `%USERPROFILE%\OneDrive\Backup\ExamBrow`, SHA-256 identik, OneDrive.exe
       aktif (sync otomatis). User verifikasi icon ✓ hijau / cek di onedrive.com.
       Zip berpassword dilewati (folder pribadi + file kecil); boleh menyusul.
- [ ] 7. Catat kedua password (store & key dari key.properties) di password
       manager / catatan fisik aman. JANGAN kirim via email/chat (§9 poin 5).
       *(dikerjakan user sendiri — file key.properties ikut ter-backup, tapi
       hafalkan/catat password-nya juga)*
- [x] 8. Isi register backup di bawah. *(✅)*

### Register backup
| Tanggal | Lokasi | SHA-256 diverifikasi | Catatan |
|---|---|---|---|
| 28 Sep 2026 | `D:\BackupExamBrow` | ✅ file + uji restore lolos | INTERIM — masih disk yang sama, BUKAN backup offline; flashdisk/cloud masih wajib |
| 28 Sep 2026 | OneDrive: `Backup/ExamBrow` | ✅ SHA-256 identik (f25be0ea...d98ebcf) | Otomatis sync ke cloud (OneDrive.exe aktif); user cek icon ✓ hijau di File Explorer saat online |
| (belum) | Flashdisk | — | Flashdisk tidak terdeteksi Windows (coba port/PC lain); opsional karena sudah ada D: + cloud |

Catatan proses backup D: (28 Sep 2026): SHA-256 sumber vs salinan identik
(`f25be0ea...d98ebcf`), keytool baca salinan → fingerprint `C4:EB:...:25:94`
cocok, uji restore (copy balik + baca + hapus folder tes) lolos. Flashdisk
hari itu TIDAK terdeteksi Windows sama sekali (Get-Disk hanya 1 disk NVMe) —
coba lagi flashdisk/port lain; alternatif: upload cloud langsung.

### Redundansi yang sudah ada (bonus — BUKAN pengganti backup fisik)
- GitHub Actions secret `ANDROID_KEYSTORE_BASE64` = salinan terenkripsi di
  GitHub (di luar kendali penuh user; jangan jadi satu-satunya).
- Laptop utama `D:\Project Web\ExamBrow\android\app\` = salinan aktif.
- ✅ STATUS 28 Sep 2026: backup offline-tipe-cloud TERCAPAI (OneDrive sync
  otomatis + salinan di D: + secret GitHub = 3 lokasi berbeda media). Backup
  flashdisk fisik tetap disarankan untuk antisipasi internet/laptop hilang,
  tapi bukan lagi bloker kritikal.

### Aturan penting
- Lakukan backup SEKARANG — keystore TIDAK bisa diregenerasi.
- Ganti laptop / clone baru: copy dari backup, JANGAN generate key baru.
- Cek ulang salinan tiap ±6 bulan (flashdisk bisa rusak; format exFAT agar
  terbaca di Windows & Mac).

## 11. Panduan EDIT OFFLINE (tanpa internet)

> Dibuat 28 Sep 2026 sesuai permintaan user. Semua toolchain sudah LOKAL
> (Flutter C:\src\flutter, JDK, Android SDK, nuget) + cache pub/gradle/nuget
> terisi dari build-build sebelumnya → edit + build offline JALAN.
> Yang butuh internet HANYA: tambah dependency baru, push/rilis ke GitHub.

### 11.1 Peta file yang biasa diedit
| Mau mengubah apa? | File | Bagian |
|---|---|---|
| PIN keluar pengawas | `lib/exam_screen.dart` | konstanta `kSupervisorPin` (baris atas) |
| Header "Exam Browser" | `lib/settings_screen.dart` | `AppBar(title: ...)` |
| Footer "© Ronald Aveiro" | `lib/settings_screen.dart` | `Row` di bawah tombol |
| Teks/warna bar status | `lib/device_status_bar.dart` | `_resolveNetwork()` + `build()` |
| Aturan whitelist host | `lib/exam_screen.dart` | `shouldOverrideUrlLoading` |
| Masa tenggang logout layar mati (5 dtk) | `lib/exam_screen.dart` | konstanta `_screenOffGraceSeconds` (poin 17) |
| Nilai yang dikunci saat ujian Windows | `windows/runner/kiosk_hardening.cpp` | konstanta `kDisableTaskMgr` / `kNoWinKeys` (poin 18) |
| Teks kartu status kiosk Android | `lib/settings_screen.dart` | blok `if (_isDeviceOwner != null)` |
| Blokir copy-paste (JS) | `lib/exam_screen.dart` | `_blockClipboardJs` |
| Ambang RAM 3584 MB | `lib/main.dart` | `DeviceGate` / `_BlockedSpecScreen` |
| Repo auto-update | `lib/update_service.dart` | `kUpdateRepo` |
| Versi aplikasi | `pubspec.yaml` | `version: X.Y.Z+N` (N WAJIB naik tiap rilis) |
| Nama app Android | `android/app/src/main/AndroidManifest.xml` | `android:label` |
| Icon app | `assets/icon/*.png` → `dart run flutter_launcher_icons` |

### 11.2 Alur edit offline (WAJIB urut)
```bash
export PATH="/c/src/flutter/bin:/c/tools/nuget:$PATH"
cd "/d/Project Web/ExamBrow"

# 1. Buka & edit file (editor bebas: VS Code/IntelliJ/Notepad++)

# 2. Cek sehat (offline OK):
flutter analyze          # harus 0 issue
flutter test             # harus lulus

# 3. Uji di Windows (offline OK):
taskkill //IM exam_brow.exe //F   # WAJIB — app jalan = file terkunci (lihat §5 poin 16)
flutter build windows --release
cd build/windows/x64/runner/Release && cmd //c start "" exam_brow.exe

# 4. Build APK (offline OK, cache gradle sudah ada):
cd "/d/Project Web/ExamBrow"
flutter build apk --release --split-per-abi
# hasil: build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

### 11.3 Install APK ke HP tanpa internet
1. Copy `app-arm64-v8a-release.apk` ke HP (kabel USB / share lokal apa pun)
2. Di HP: buka file APK → izinkan "install aplikasi tidak dikenal" bila diminta
3. Syarat BISA timpa langsung: `version:` di pubspec sudah NAIK, dan APK
   ditandatangani keystore permanen (build dari laptop ini dengan
   `android/key.properties` ada — lihat §9 poin 5)
4. Verifikasi versi: Settings HP → Apps → ExamBrow

### 11.4 Yang TIDAK BISA dilakukan offline (butuh internet)
- `flutter pub add ...` / ganti dependency di pubspec (pub get butuh jaringan;
  dependency yang SUDAH ada tetap aman karena ada cache)
- Push commit/tag ke GitHub → CI build → HP lain auto-update
- Update service di app: offline = cek update gagal = app jalan normal
  (fail-open, by design)

### 11.5 Saat kembali online (setelah edit offline)
```bash
cd "/d/Project Web/ExamBrow"
git add -A && git status --short        # cek dulu apa yang berubah
git commit -m "deskripsi perubahan"
git push origin main
# Untuk rilis ke semua HP: naikkan version di pubspec DULU sebelum commit, lalu:
git tag vX.Y.Z && git push origin vX.Y.Z   # CI build + rilis otomatis
```
Jangan lupa: kalau dependency baru ditambah saat offline akan gagal —
tunda sampai online.
