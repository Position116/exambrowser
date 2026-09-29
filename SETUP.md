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

## Kiosk Penuh Android (Device Owner) — setara Safe Exam Browser

Secara default, penguncian Android memakai **screen pinning** (mode standar):
HOME/RECENTS terkunci selama ujian, tapi Android masih mengizinkan lepas pin
dengan gesture bawaan (mis. tahan Back + Recents di vivo). Untuk penguncian
**penuh** (tidak ada jalur keluar tanpa PIN, notifikasi & overlay aplikasi
lain hilang), aplikasi harus dijadikan **device owner** — cukup dilakukan
SEKALI per HP, via PC dengan adb.

Cara tahu app sudah device owner atau belum: buka ExamBrow → kartu status di
halaman pengaturan menampilkan "Kiosk penuh aktif (device owner)" atau
"Kiosk standar (screen pinning)" + perintah provisioning.

Langkah provisioning (sekali per HP):

1. HP harus **tanpa akun Google** (Settings → Accounts → hapus semua akun).
   Kalau pernah ada akun, biasanya perlu factory reset. Ini syarat Android,
   bukan batasan aplikasi.
2. Aktifkan **Developer Options** + **USB Debugging** di HP.
3. Sambungkan HP ke PC (install driver USB HP bila perlu), cek:
   ```
   adb devices
   ```
4. PASTIKAN ExamBrow sudah ter-install, lalu jalankan:
   ```
   adb shell dpm set-device-owner com.example.exam_brow/.ExamAdminReceiver
   ```
5. Buka ExamBrow di HP → kartu status berubah jadi "Kiosk penuh aktif".

Catatan:
- Setelah jadi device owner, app TIDAK BISA di-uninstall biasa (harus lewat
  app dulu atau `adb shell dpm remove-active-admin` + `adb uninstall`).
- Auto-update APK tetap jalan normal (device owner boleh update sendiri).
- Kalau provisioning gagal (HP tidak mau), app tetap jalan dengan pinning
  standar seperti dulu — tidak ada yang rusak.

## Hardening Windows Saat Ujian

Saat mode ujian di Windows, aplikasi otomatis:
- mengunci **Task Manager** (Ctrl+Shift+Esc tidak membuka apa pun),
- mematikan **tombol Win** dan shortcut-nya (Win+D, Win+R, Win+E, dst.),

via Registry HKCU (kebijakan yang sama dipakai Group Policy; tidak perlu
admin). Setelah ujian selesai (atau app ditutup), semuanya dikembalikan
otomatis persis seperti semula. Kalau app mati paksa di tengah ujian,
pembersihan otomatis dijalankan saat app dibuka lagi.

Yang tetap tidak bisa diblokir aplikasi manapun: **Ctrl+Alt+Del** (milik
Windows). Untuk lab ujian resmi, disarankan tambah **Assigned Access**
(Settings → Accounts → Other users → Set up a kiosk) dengan akun Windows
khusus ujian — kombinasi keduanya setara praktik Safe Exam Browser.

## Catatan Penting

- **Mode kiosk di Windows** = fullscreen + selalu di atas + tombol close
  diblokir (harus PIN) + Task Manager & tombol Win dikunci saat ujian
  (lihat bagian Hardening di atas). Sisa celah utama: Ctrl+Alt+Del —
  tutup dengan Assigned Access untuk lab resmi.
- **PIN keluar mode ujian** TETAP `123456` (ditentukan di `exam_screen.dart`,
  tidak bisa diubah dari aplikasi).
- **Whitelist URL**: webview hanya mengizinkan navigasi ke host server ujian
  yang diisi di halaman pengaturan.
- iOS/iPhone: fullscreen "benar-benar kiosk" di iOS dibatasi oleh Apple
  (Guided Access perangkat bisa jadi pelengkap).
