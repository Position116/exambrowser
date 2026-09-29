package com.example.exam_brow

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.os.UserManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // Blokir screenshot & perekaman layar saat aplikasi di foreground
        // (layar jadi hitam jika ada yang mencoba screenshot).
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Channel cek spesifikasi minimal perangkat dari sisi Dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "exam_brow/device_info")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getTotalRamMb" -> {
                        val activityManager =
                            getSystemService(ACTIVITY_SERVICE) as ActivityManager
                        val memInfo = ActivityManager.MemoryInfo()
                        activityManager.getMemoryInfo(memInfo)
                        result.success((memInfo.totalMem / (1024L * 1024L)).toInt())
                    }
                    else -> result.notImplemented()
                }
            }

        // Channel kiosk mode (masuk/keluar mode ujian) dari sisi Dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "exam_brow/kiosk")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Cek apakah aplikasi adalah device owner (provisioned
                    // via `adb shell dpm set-device-owner`). Dipakai layar
                    // status provisioning di halaman pengaturan.
                    "isDeviceOwner" -> {
                        val dpm =
                            getSystemService(DEVICE_POLICY_SERVICE) as DevicePolicyManager
                        result.success(
                            dpm.isDeviceOwnerApp(packageName)
                        )
                    }
                    "start" -> {
                        // Layar tetap menyala selama ujian -> HP tidak sleep,
                        // lock screen tidak muncul di depan aplikasi.
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                        )
                        val dpm =
                            getSystemService(DEVICE_POLICY_SERVICE) as DevicePolicyManager
                        if (dpm.isDeviceOwnerApp(packageName)) {
                            // Lock Task Mode PENUH (device owner): home,
                            // recents, notifikasi, dan gesture keluar
                            // hilang — tidak ada jalur keluar tanpa PIN.
                            // Blokir juga overlay aplikasi lain (app
                            // pembantu curang, tombol asis, dsb).
                            dpm.setLockTaskPackages(
                                ComponentName(this, ExamAdminReceiver::class.java),
                                arrayOf(packageName)
                            )
                            dpm.addUserRestriction(
                                ComponentName(this, ExamAdminReceiver::class.java),
                                UserManager.DISALLOW_CREATE_WINDOWS
                            )
                            startLockTask()
                        } else {
                            // Belum device owner -> pinning standar
                            // (fallback; bisa lepas via gesture sistem).
                            startLockTask()
                        }
                        result.success(true)
                    }
                    "stop" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        val dpm =
                            getSystemService(DEVICE_POLICY_SERVICE) as DevicePolicyManager
                        if (dpm.isDeviceOwnerApp(packageName)) {
                            dpm.clearUserRestriction(
                                ComponentName(this, ExamAdminReceiver::class.java),
                                UserManager.DISALLOW_CREATE_WINDOWS
                            )
                        }
                        try {
                            stopLockTask()
                        } catch (e: Exception) {
                            // Tidak sedang pinned -> tidak apa-apa.
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
