# ExamBrow — Daftar Sistem Ujian Online & Isi URL-nya

ExamBrow hanyalah "pembungkus" (kiosk browser). Halaman pengaturan hanya butuh
**URL host server ujian**. Berikut sistem yang umum dipakai sekolah di Indonesia
beserta contoh URL yang biasanya diisi.

> **Aturan penting:** isi **host-nya saja** (contoh: `ujian.sekolah.sch.id`).
> Tidak perlu `http://` — ExamBrow otomatis menambahkan `https://`.
> Jika server sekolah tidak punya HTTPS, tulis manual `http://...`.
> Semua navigasi ke host lain akan otomatis diblokir (whitelist).

## Contoh Sistem yang Umum Dipakai

| Sistem | Contoh URL yang diisi | Catatan |
|---|---|---|
| **ANBK (Kemendikbud)** | `https://jenjang-dikti.anbk.kemdikbud.go.id` atau URL yang diberikan penyelenggara ujian | ANBK punya browser keamanannya sendiri (APM / aplikasi ANBK). ExamBrow **tidak menggantikan APM ANBK** — hanya berguna untuk ujian internal sekolah. |
| **CBT sync (aplikasi lokal)** | `http://192.168.1.10:8080` atau IP server CBT di jaringan sekolah | Umumnya HTTP lokal tanpa HTTPS. Tulis manual awalan `http://`. Setiap klien harus satu jaringan dengan server. |
| **Rajanas / ANRO / CBTONLINE** | `cbt.namaschool.sch.id` | Biasanya subdomain khusus ujian. |
| **Google Form (ujian sederhana)** | `docs.google.com` | ⚠️ Host besar — semua halaman Google Docs/Form jadi boleh diakses. Kurang ketat; lebih aman pakai sistem CBT sendiri. |
| **Quizizz / Kahoot** | `quizizz.com` / `kahoot.it` | Untuk kuis/pemanasan, bukan ujian resmi. |
| **Moodle sekolah** | `elearning.sekolah.sch.id` | Mode "exam browser" Moodle perlu diaktifkan di server agar cocok dengan kiosk. |
| **Sekolah buat sendiri (LMS/CBT)** | `ujian.sekolah.sch.id` | Ikuti alamat yang dibuat panitia IT. |

## Tips Penyelenggara Ujian

1. **Uji dulu sebelum hari-H**: buka URL di Chrome biasa, pastikan halaman
   login siswa muncul. Baru masukkan URL itu ke ExamBrow.
2. **PIN pengawas**: ganti dari default `123456` sebelum ujian, dan samakan
   PIN di semua perangkat yang dipakai sesi itu.
3. **Jaringan**: untuk CBT lokal, pastikan semua perangkat terhubung ke Wi-Fi/
   LAN yang sama dengan server CBT.
4. **Satu server per sesi**: ExamBrow menyimpan 1 URL aktif. Jika ada 2
   server berbeda dalam satu hari, ganti URL di halaman pengaturan tiap sesi.
5. **Isi halaman berputar/refresh**: ExamBrow tetap membuka halaman yang sama
   saat koneksi putus — siswa cukup reload dari tombol situs ujian itu sendiri.

## Batasan Keamanan

Lihat catatan di `SETUP.md` — ExamBrow adalah kiosk level dasar. Untuk
ujian resmi berskala besar (terutama ANBK), tetap gunakan aplikasi resmi
dari penyelenggara ujian.
