package com.example.exam_brow

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

/**
 * Receiver device admin (wajib ada agar `dpm set-device-owner` bisa
 * mempromosikan aplikasi menjadi device owner untuk Lock Task Mode penuh).
 * Tidak menambahkan perilaku apa pun di luar itu.
 */
class ExamAdminReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        // Tidak ada aksi khusus; kebijakan dipakai lewat DevicePolicyManager
        // langsung dari MainActivity.
    }
}
