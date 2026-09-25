# ExamBrow — Panduan Setup

Kiosk exam browser sederhana untuk Windows, Android, dan iOS.
Membuka server ujian yang sudah ada dalam mode terkunci (fullscreen, blokir
navigasi keluar, whitelist host server ujian).

## Struktur Project

```
ExamBrow/
├── lib/
│   ├── main.dart            # Entry point + gate spesifikasi + gate update
│   ├── settings_screen.dart # Input URL server ujian (saja, tanpa PIN)
│   ├── exam_screen.dart     # Webview kiosk + PIN keluar
│   └── update_service.dart  # Cek/unduh update via GitHub Releases
├── test/widget_test.dart
└── pubspec.yaml
```

## Langkah 1 — Install Prasyarat (Windows)

1. **Git for Windows** (butuh untuk Flutter):
   ```
   winget install --id Git.Git --exact --source winget
   ```

2. **Flutter SDK**:
   - Download: https://docs.flutter.dev/get-started/install/windows
   - Ekstrak misalnya ke `C:\src\flutter`
   - Tambahkan `C:\src\flutter\bin` ke PATH

3. **Visual Studio 2022** dengan workload **"Desktop development with C++"**
   (wajib untuk build Windows).

4. Verifikasi:
   ```
   flutter doctor
   ```

## Langkah 2 — Generate File Platform & Ambil Dependencies

Buka terminal baru di folder project:

```
cd "D:\Project Web\ExamBrow"
flutter create --platforms=windows,android,ios .
flutter pub get
```

> `flutter create .` akan menambahkan folder `windows/`, `android/`, `ios/`
> tanpa menimpa kode yang sudah ada di `lib/`.

## Langkah 3 — Jalankan

**Windows:**
```
flutter run -d windows
```

**Android** (perangkat terhubung / emulator):
```
flutter run -d android
```

**iOS** (butuh Mac dengan Xcode):
```
flutter run -d ios
```

## Langkah 4 — Build Release

```
flutter build windows
flutter build apk --release
flutter build ipa   # butuh Mac + Xcode + akun developer Apple
```

## Spesifikasi Minimal (Android)

- **Android 10 (API 29) ke atas** — HP di bawah ini tidak bisa meng-install APK.
- **RAM 4GB** — dicek saat aplikasi dibuka; perangkat di bawah 3,5 GB terdeteksi
  akan diblokir (HP berlabel 4GB umumnya terdeteksi 3,5–3,8 GB, itu masih lolos).
- **Install APK yang sesuai arsitektur HP** (hasil `flutter build apk --release --split-per-abi`):
  - HP modern (termasuk vivo 1918): `app-arm64-v8a-release.apk` (~18 MB)
  - HP lama 32-bit: `app-armeabi-v7a-release.apk` (~16 MB)
  - File `app-release.apk` (fat, ~50 MB) hanya cadangan — semua arsitektur sekaligus.

## Auto-Update (Android) — via GitHub Releases

Aplikasi memeriksa update **setiap kali dibuka**. Jika di GitHub ada Release dengan
versi lebih baru, aplikasi otomatis mengunduh APK dan memunculkan installer Android.
Update bersifat **wajib**: layar update tidak bisa ditutup sampai versi baru ter-install.

Persiapan sekali saja:

1. Repo GitHub: `Position116/exambrowser` (sesuai `kUpdateRepo` di
   `lib/update_service.dart`). Kalau repo diganti, ubah baris itu + build ulang.
2. Signing permanen (supaya update bisa menimpa langsung tanpa uninstall):
   keystore ada di `android/app/exambrow-release.jks` + kredensial di
   `android/key.properties` (keduanya TIDAK di-commit). Backup keduanya!
3. Isi 4 secret di GitHub repo → Settings > Secrets > Actions (wajib,
   kalau tidak build CI gagal):
   `ANDROID_KEYSTORE_BASE64` (isi base64 SATU BARIS dari file `.jks`),
   `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`.

Alur setiap rilis versi baru (otomatis via CI):

1. Naikkan versi di `pubspec.yaml`, contoh:
   ```yaml
   version: 0.1.3+4   # versionName+versionCode — keduanya harus naik
   ```
2. Commit, buat tag, push:
   ```
   git commit -am "Rilis 0.1.3"
   git tag v0.1.3
   git push origin main --tags
   ```
3. GitHub Actions otomatis build APK split-per-abi + menerbitkan Release
   (`exambrow-v0.1.3-arm64-v8a.apk` dsb).
4. Selesai — HP yang membuka aplikasi akan diminta update otomatis.

Catatan:
- Jika cek update gagal (HP offline, internet lambat, atau limit API GitHub
  60 permintaan/jam), aplikasi **tetap bisa dipakai** — update dilewati.
- Saat dialog installer muncul, Android bisa meminta izin "Install aplikasi
  tidak dikenal" untuk ExamBrow sekali saja — centang izinkan.
- PENTING: install lama yang ditandatangani debug key (v0.1.0–v0.1.2) wajib
  di-uninstall manual SATU KALI saat pindah ke versi keystore baru (v0.1.3+).
  Setelah itu update berikutnya bisa menimpa langsung.

## Catatan Penting

- **Mode kiosk di Windows** = fullscreen + selalu di atas + tombol close
  diblokir (harus PIN). Ini bukan penguncian setinggi Safe Exam Browser;
  siswa yang paham komputer masih bisa dengan task manager dsb. Untuk ujian
  resmi berskala besar, pertimbangkan tambahan kebijakan Windows
  (Assigned Access) atau pembatasan akun siswa.
- **PIN keluar mode ujian** TETAP `123456` (ditentukan di `exam_screen.dart`,
  tidak bisa diubah dari aplikasi).
- **Whitelist URL**: webview hanya mengizinkan navigasi ke host server ujian
  yang diisi di halaman pengaturan.
- iOS/iPhone: fullscreen "benar-benar kiosk" di iOS dibatasi oleh Apple
  (Guided Access perangkat bisa jadi pelengkap).
