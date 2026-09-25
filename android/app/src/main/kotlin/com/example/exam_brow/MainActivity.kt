package com.example.exam_brow

import android.app.ActivityManager
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
                    "start" -> {
                        // Layar tetap menyala selama ujian -> HP tidak sleep,
                        // lock screen tidak muncul di depan aplikasi.
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                        )
                        // Screen pinning: home/recents tidak bisa memindahkan
                        // aplikasi. (Bukan device owner, jadi Android memakai
                        // mode pinning standar milik sistem.)
                        startLockTask()
                        result.success(true)
                    }
                    "stop" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
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
