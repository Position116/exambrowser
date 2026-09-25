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
| `lib/exam_screen.dart` | Webview kiosk: whitelist host, PopScope blokir back, WindowListener blokir close Windows, dialog PIN keluar, tombol gembok kecil pojok kanan-bawah (opacity 0.35), inject JS blokir copy-paste/seleksi teks (`_blockClipboardJs` via `onLoadStop`), kiosk Android (lihat bagian 5 poin 10) |
| `lib/update_service.dart` | Auto-update: cek GitHub Releases + layar update wajib (unduh APK + buka installer) |
| `test/widget_test.dart` | Test halaman pengaturan (LULUS) |
| `SETUP.md` | Panduan setup untuk user |
| `EXAM_SYSTEMS.md` | Katalog sistem ujian online (ANBK/CBT/Moodle dll) + cara isi URL whitelist |
| `windows/CMakeLists.txt` | +1 baris fix coroutine (lihat bagian 5) |
| `android/.../MainActivity.kt` | + FLAG_SECURE (blokir screenshot/rekaman layar) + MethodChannel `exam_brow/device_info` (getTotalRamMb) + MethodChannel `exam_brow/kiosk` (start/stop: FLAG_KEEP_SCREEN_ON + startLockTask/stopLockTask) |
| `tool/gen_icon.ps1` + `assets/icon/` | Generator icon (PowerShell System.Drawing) + PNG sumber icon |
| `windows/runner/resources/app_icon.ico` | Icon Windows (generate otomatis, JANGAN edit manual) |

### Dependencies (pubspec.yaml)
- `flutter_inappwebview: ^6.1.5` (webview; Windows pakai endorsed package `flutter_inappwebview_windows 0.6.0` + WebView2 + **butuh nuget.exe**)
- `window_manager: ^0.4.3`
- `shared_preferences: ^2.3.2`
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

## 4. Status Build (per 25 Sep 2026)

| Target | Status | Output |
|---|---|---|
| `flutter analyze` | ✅ 0 issue | — |
| `flutter test` | ✅ lulus | — |
| **Windows release** | ✅ BERHASIL ulang 25 Sep 2026 malam (v0.1.3: footer logo © + tanpa PIN depan) | `build\windows\x64\runner\Release\exam_brow.exe` |
| **Android APK release** | ✅ BERHASIL — fat 48.2 MB (3 ABI); **pakai versi split-per-abi**: arm64 17.9 MB (vivo 1918), armeabi-v7a 15.3 MB, x86_64 19.2 MB | `build\app\outputs\flutter-apk\app-<abi>-release.apk` |
| iOS | ⛔ TIDAK BISA dari Windows (butuh Mac+Xcode) | folder `ios/` sudah ada & siap |

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
    - Uji E2E auto-update PENDING: HP putus dari adb saat mau install APK
      dasar v0.1.1+2. Saat HP tersambung lagi: install arm64 v0.1.1 lokal →
      buka app → harus muncul layar update ke v0.1.2 → install → verifikasi
      dumpsys versionName=0.1.2.
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
    - ⚠️ WAJIB sebelum tag rilis berikutnya: isi 4 secret di
      GitHub Settings > Secrets > Actions, kalau tidak CI GAGAL di step restore.
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
      `aapt2 dump badging`). Status rilis v0.1.3: BELUM — tunggu secret diisi
      lalu commit → tag v0.1.3 → push.
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

- [~] Uji manual APK di HP ✅ SEBAGIAN (25 Sep 2026, vivo 1918 via adb): header/footer baru,
      gate RAM lolos (HP 4GB), kiosk PINNED, keep-screen-on + SECURE aktif di window flags,
      HOME & RECENTS diblokir saat kiosk. BELUM diuji user: login + navigation whitelist di
      situs ujian, keluar dengan PIN, screenshot (FLAG_SECURE), long-press teks.
      - Windows: jalankan `build\windows\x64\runner\Release\exam_brow.exe` — cek icon,
        fullscreen, whitelist, blokir copy, keluar PIN (belum diuji ulang)
      ⚠️ vivo 1918: BACK saat PINNED memicu gesture unpin bawaan (dialog konfirmasi vivo);
      perilaku unpin standar Android untuk pinning non-device-owner, bukan bug aplikasi.
- [x] Blokir copy-paste/screenshot ✅ (25 Sep 2026): JS inject di exam_screen + FLAG_SECURE Android
- [x] Icon aplikasi ✅ (25 Sep 2026): flutter_launcher_icons + assets/icon/
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

## 9. Register Perubahan (sesi 26 Sep 2026, BELUM di-commit) + Solusi Edit per File

Status: `M` = modified, `baru` = file baru. Cara cek: `git status --short`.

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
