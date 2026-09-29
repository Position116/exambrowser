#include "kiosk_hardening.h"

#include <string>
#include <windows.h>

namespace {

// Kebijakan sistem yang sama dipakai Group Policy / Assigned Access.
constexpr wchar_t kSystemKey[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\System";
constexpr wchar_t kExplorerKey[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer";
constexpr wchar_t kDisableTaskMgr[] = L"DisableTaskMgr";
constexpr wchar_t kNoWinKeys[] = L"NoWinKeys";
constexpr wchar_t kCleanupKey[] =
    L"Software\\ExamBrow\\KioskHardening";

// Pasang nilai DWORD registry; simpan nilai lama (jika ada) ke backup key.
void LockValue(HKEY root, const wchar_t* subkey, const wchar_t* value_name) {
  RegCreateKeyExW(root, subkey, 0, nullptr, 0, KEY_SET_VALUE | KEY_QUERY_VALUE,
                  nullptr, nullptr, nullptr);
  HKEY key;
  if (RegOpenKeyExW(root, subkey, 0, KEY_SET_VALUE | KEY_QUERY_VALUE, &key) !=
      ERROR_SUCCESS)
    return;
  DWORD old_value = 0;
  DWORD old_size = sizeof(old_value);
  DWORD exists = RegQueryValueExW(key, value_name, nullptr, nullptr,
                                  reinterpret_cast<BYTE*>(&old_value),
                                  &old_size) == ERROR_SUCCESS;
  HKEY backup;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kCleanupKey, 0, nullptr, 0,
                      KEY_SET_VALUE, nullptr, &backup, nullptr) ==
      ERROR_SUCCESS) {
    DWORD marker = exists ? 1 : 0;
    RegSetValueExW(backup, value_name, 0, REG_DWORD,
                   reinterpret_cast<const BYTE*>(&marker), sizeof(marker));
    if (exists) {
      RegSetValueExW(backup, (std::wstring(value_name) + L"_old").c_str(), 0,
                     REG_DWORD, reinterpret_cast<const BYTE*>(&old_value),
                     sizeof(old_value));
    }
    RegCloseKey(backup);
  }
  DWORD one = 1;
  RegSetValueExW(key, value_name, 0, REG_DWORD,
                 reinterpret_cast<const BYTE*>(&one), sizeof(one));
  RegCloseKey(key);
}

// Kembalikan nilai registry dari backup, lalu hapus backup.
void UnlockValue(HKEY root, const wchar_t* subkey, const wchar_t* value_name) {
  HKEY backup;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kCleanupKey, 0, KEY_QUERY_VALUE,
                    &backup) != ERROR_SUCCESS)
    return;
  DWORD marker = 0;
  DWORD size = sizeof(marker);
  bool had_backup =
      RegQueryValueExW(backup, value_name, nullptr, nullptr,
                       reinterpret_cast<BYTE*>(&marker), &size) == ERROR_SUCCESS;
  if (had_backup) {
    HKEY key;
    if (RegOpenKeyExW(root, subkey, 0, KEY_SET_VALUE, &key) == ERROR_SUCCESS) {
      if (marker) {
        DWORD old_value = 0;
        DWORD old_size = sizeof(old_value);
        if (RegQueryValueExW(backup, (std::wstring(value_name) + L"_old").c_str(),
                             nullptr, nullptr,
                             reinterpret_cast<BYTE*>(&old_value),
                             &old_size) == ERROR_SUCCESS) {
          RegSetValueExW(key, value_name, 0, REG_DWORD,
                         reinterpret_cast<const BYTE*>(&old_value),
                         sizeof(old_value));
        }
      } else {
        RegDeleteValueW(key, value_name);
      }
      RegCloseKey(key);
    }
    RegDeleteValueW(backup, value_name);
    RegDeleteValueW(backup, (std::wstring(value_name) + L"_old").c_str());
  }
  RegCloseKey(backup);
}

}  // namespace

namespace kiosk_hardening {

void Apply() {
  LockValue(HKEY_CURRENT_USER, kSystemKey, kDisableTaskMgr);
  LockValue(HKEY_CURRENT_USER, kExplorerKey, kNoWinKeys);
}

void Revert() {
  UnlockValue(HKEY_CURRENT_USER, kSystemKey, kDisableTaskMgr);
  UnlockValue(HKEY_CURRENT_USER, kExplorerKey, kNoWinKeys);
}

void CleanupOrphans() {
  // Jika tidak ada backup, tidak ada sisa lock — selesai.
  HKEY backup;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kCleanupKey, 0, KEY_QUERY_VALUE,
                    &backup) != ERROR_SUCCESS)
    return;
  RegCloseKey(backup);
  Revert();
}

}  // namespace kiosk_hardening
