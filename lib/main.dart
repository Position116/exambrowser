import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, PlatformException;
import 'package:window_manager/window_manager.dart';

import 'settings_screen.dart';
import 'update_service.dart' show UpdateCheckResult, UpdateScreen, checkForUpdate;

/// window_manager hanya punya implementasi desktop (Windows/macOS/Linux).
/// Memanggilnya di Android/iOS melempar MissingPluginException
/// (penyebab layar putih saat buka aplikasi di Android).
final bool _isDesktop = !kIsWeb &&
    (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

/// Spesifikasi minimal Android: RAM 4GB.
/// Ambang batas 3,5GB karena HP berlabel 4GB umumnya terdeteksi ~3,5-3,8GB
/// (sebagian RAM dicadangkan sistem), jadi tidak boleh menuntut persis 4096MB.
const int _minRamMb = 3584;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_isDesktop) {
    await windowManager.ensureInitialized();
    // Judul & ukuran awal jendela (hanya berpengaruh di Windows).
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        title: 'ExamBrow',
        minimumSize: Size(800, 600),
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  runApp(const ExamBrowApp());
}

class ExamBrowApp extends StatelessWidget {
  const ExamBrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExamBrow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // Gerbang spesifikasi perangkat sebelum masuk ke aplikasi.
      home: const DeviceGate(),
    );
  }
}

/// Gerbang spesifikasi minimal: di Android, total RAM dicek lewat
/// MethodChannel ke MainActivity. Di bawah ambang batas -> layar blokir total.
class DeviceGate extends StatefulWidget {
  const DeviceGate({super.key});

  @override
  State<DeviceGate> createState() => _DeviceGateState();
}

class _DeviceGateState extends State<DeviceGate> {
  static const _channel = MethodChannel('exam_brow/device_info');

  // Hanya Android yang dicek runtime; desktop langsung lolos tanpa berkedip.
  bool _checking = Platform.isAndroid;
  String? _detectedRam;
  UpdateCheckResult? _update;

  @override
  void initState() {
    super.initState();
    if (_checking) _checkDeviceSpec();
  }

  Future<void> _checkDeviceSpec() async {
    int totalRamMb;
    try {
      totalRamMb = await _channel.invokeMethod<int>('getTotalRamMb') ?? 0;
    } on PlatformException {
      // Gagal membaca RAM: jangan blokir, biarkan aplikasi jalan.
      _done();
      return;
    } on MissingPluginException {
      _done();
      return;
    }

    if (totalRamMb < _minRamMb) {
      if (!mounted) return;
      setState(() {
        _detectedRam = '${(totalRamMb / 1024).toStringAsFixed(1)} GB';
        _checking = false;
      });
      return;
    }

    // Spesifikasi lolos -> cek pembaruan (Android saja).
    if (Platform.isAndroid) {
      final result = await checkForUpdate();
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _update = result;
          _checking = false;
        });
        return;
      }
    }
    _done();
  }

  void _done() {
    if (!mounted) return;
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_detectedRam != null) {
      return _BlockedSpecScreen(detectedRam: _detectedRam!);
    }
    if (_update != null) {
      // Ada versi lebih baru -> layar update wajib (tidak bisa ditutup).
      return UpdateScreen(result: _update!);
    }
    return const SettingsScreen();
  }
}

/// Layar blokir total untuk perangkat di bawah spesifikasi minimal.
class _BlockedSpecScreen extends StatelessWidget {
  const _BlockedSpecScreen({required this.detectedRam});

  final String detectedRam;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Perangkat Tidak Memenuhi Syarat',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'ExamBrow membutuhkan minimal Android 10 dan RAM 4GB.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'RAM terdeteksi: $detectedRam',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
