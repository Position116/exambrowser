#ifndef RUNNER_KIOSK_HARDENING_H_
#define RUNNER_KIOSK_HARDENING_H_

// Hardening kiosk Windows via Registry HKCU (tanpa perlu admin):
// - DisableTaskMgr : Task Manager tidak bisa dibuka saat ujian.
// - NoWinKeys      : tombol Win + shortcut (Win+D, Win+R, dst.) dimatikan.
// Nilai lama disimpan & dikembalikan persis saat kiosk berakhir.
// Marker "ExamBrowKioskLock" dipakai untuk membersihkan sisa lock jika
// aplikasi mati paksa/crash di tengah ujian (self-heal saat start).

namespace kiosk_hardening {

// Aktifkan pembatasan (dipanggil saat masuk mode ujian).
void Apply();

// Kembalikan registry ke kondisi sebelum Apply() (saat keluar mode ujian).
void Revert();

// Hapus sisa pembatasan dari sesi yang crash (dipanggil saat app start).
void CleanupOrphans();

}  // namespace kiosk_hardening

#endif  // RUNNER_KIOSK_HARDENING_H_
