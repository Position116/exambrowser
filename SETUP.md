# ExamBrow — Panduan Setup

Kiosk exam browser sederhana untuk Windows, Android, dan iOS.
Membuka server ujian yang sudah ada dalam mode terkunci (fullscreen, blokir
navigasi keluar, whitelist host server ujian).

## Struktur Project

```
ExamBrow/
├── lib/
│   ├── main.dart            # Entry point + gate spesifikasi + gate update
│   ├── settings_screen.dart # Input URL server ujian & PIN pengawas
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

1. Buat repo GitHub, misal `ronaldaveiro/exambrow` (bisa private/public).
2. Buka `lib/update_service.dart`, sesuaikan baris ini dengan repo kamu:
   ```dart
   const String kUpdateRepo = 'ronaldaveiro/exambrow';
   ```
3. Build ulang aplikasi.

Alur setiap rilis versi baru:

1. Naikkan versi di `pubspec.yaml`, contoh:
   ```yaml
   version: 1.0.1+2   # versionName+versionCode — keduanya harus naik
   ```
2. Build APK:
   ```
   flutter build apk --release --split-per-abi
   ```
3. Di GitHub repo → **Releases → Draft a new release**:
   - Tag: `v1.0.1` (harus sama dengan `versionName` di pubspec, boleh diawali `v`)
   - Judul bebas, mis. "Exam Browser 1.0.1"
   - Upload **`app-arm64-v8a-release.apk`** (dan `app-armeabi-v7a-release.apk` bila
     ada HP lama yang dipakai)
   - Publish release.
4. Selesai — HP yang membuka aplikasi akan diminta update otomatis.

Catatan:
- Jika cek update gagal (HP offline, internet lambat, atau limit API GitHub
  60 permintaan/jam), aplikasi **tetap bisa dipakai** — update dilewati.
- Saat dialog installer muncul, Android bisa meminta izin "Install aplikasi
  tidak dikenal" untuk ExamBrow sekali saja — centang izinkan.

## Catatan Penting

- **Mode kiosk di Windows** = fullscreen + selalu di atas + tombol close
  diblokir (harus PIN). Ini bukan penguncian setinggi Safe Exam Browser;
  siswa yang paham komputer masih bisa dengan task manager dsb. Untuk ujian
  resmi berskala besar, pertimbangkan tambahan kebijakan Windows
  (Assigned Access) atau pembatasan akun siswa.
- **PIN default** adalah `123456` — segera ganti di halaman pengaturan.
- **Whitelist URL**: webview hanya mengizinkan navigasi ke host server ujian
  yang diisi di halaman pengaturan.
- iOS/iPhone: fullscreen "benar-benar kiosk" di iOS dibatasi oleh Apple
  (Guided Access perangkat bisa jadi pelengkap).
