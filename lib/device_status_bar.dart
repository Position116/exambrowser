import 'dart:async';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, PlatformException;

/// Channel info perangkat Android (getTotalRamMb, implementasi di
/// MainActivity.kt — dibagikan dengan gate RAM di main.dart).
const MethodChannel _deviceInfoChannel = MethodChannel('exam_brow/device_info');

/// Bar status di bagian bawah layar ujian.
///
/// Menampilkan (kiri ke kanan):
/// 1. Status jaringan REALTIME dengan warna: hijau (WiFi/Ethernet),
///    oranye (seluler), merah (offline), abu (belum diketahui).
/// 2. Nama perangkat (mis. "vivo 1918" / nama komputer Windows).
/// 3. Versi OS (mis. "Android 13" / "Windows 11 Pro").
/// 4. Total RAM (mis. "3,8 GB") — hanya Android (via MethodChannel);
///    di platform lain segmen ini disembunyikan.
///
/// Semua info bersifat best-effort: jika pembacaan gagal, segmen
/// terkait disembunyikan dan aplikasi tetap jalan (fail-open,
/// sesuai filosofi project).
class DeviceStatusBar extends StatefulWidget {
  const DeviceStatusBar({super.key});

  @override
  State<DeviceStatusBar> createState() => _DeviceStatusBarState();
}

class _DeviceStatusBarState extends State<DeviceStatusBar> {
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  List<ConnectivityResult>? _connectivity;
  String? _deviceName;
  String? _osVersion;
  int? _totalRamMb;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    unawaited(_connSub?.cancel());
    super.dispose();
  }

  /// Subscribe dulu ke stream, baru cek kondisi awal — supaya tidak ada
  /// perubahan yang terlewat di antara keduanya.
  Future<void> _initConnectivity() async {
    try {
      final connectivity = Connectivity();
      _connSub = connectivity.onConnectivityChanged.listen((results) {
        if (mounted) setState(() => _connectivity = results);
      });
      final results = await connectivity.checkConnectivity();
      if (mounted) setState(() => _connectivity = results);
    } catch (_) {
      // Gagal membaca jaringan: tampilkan sebagai tidak diketahui (abu),
      // jangan sampai crash layar ujian.
      if (mounted) setState(() => _connectivity = null);
    }
  }

  Future<void> _loadDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        var name = info.model;
        if (!name.toLowerCase().contains(info.manufacturer.toLowerCase())) {
          name = '${info.manufacturer} $name';
        }
        if (!mounted) return;
        setState(() {
          _deviceName = name;
          _osVersion = 'Android ${info.version.release}';
        });
      } else if (Platform.isWindows) {
        final info = await DeviceInfoPlugin().windowsInfo;
        if (!mounted) return;
        setState(() {
          _deviceName = info.computerName;
          _osVersion = info.productName;
        });
      } else if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        if (!mounted) return;
        setState(() {
          _deviceName = info.utsname.machine;
          _osVersion = '${info.systemName} ${info.systemVersion}';
        });
      }
    } catch (_) {
      // Info perangkat gagal: segmen disembunyikan, aplikasi tetap jalan.
    }

    // RAM hanya tersedia di Android (MethodChannel native).
    if (!Platform.isAndroid) return;
    try {
      final ramMb = await _deviceInfoChannel.invokeMethod<int>('getTotalRamMb');
      if (mounted && ramMb != null) setState(() => _totalRamMb = ramMb);
    } on PlatformException {
      // Abaikan: segmen RAM disembunyikan.
    } on MissingPluginException {
      // Implementasi native tidak ada (mis. hot restart).
    }
  }

  ({Color color, IconData icon, String label}) _resolveNetwork() {
    final results = _connectivity;
    if (results == null) {
      return (color: Colors.grey, icon: Icons.help_outline, label: 'Jaringan?');
    }
    if (results.contains(ConnectivityResult.wifi)) {
      return (color: Colors.green, icon: Icons.wifi, label: 'Online - WiFi');
    }
    if (results.contains(ConnectivityResult.ethernet)) {
      return (
        color: Colors.green,
        icon: Icons.lan,
        label: 'Online - Ethernet',
      );
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return (
        color: Colors.orange,
        icon: Icons.signal_cellular_alt,
        label: 'Online - Seluler',
      );
    }
    if (results.any((r) =>
        r == ConnectivityResult.vpn ||
        r == ConnectivityResult.bluetooth ||
        r == ConnectivityResult.other)) {
      return (
        color: Colors.blue,
        icon: Icons.device_hub,
        label: 'Online',
      );
    }
    return (color: Colors.red, icon: Icons.wifi_off, label: 'Offline');
  }

  String _formatRam(int ramMb) {
    final gb = ramMb / 1024;
    return 'RAM ${gb.toStringAsFixed(1).replaceAll('.', ',')} GB';
  }

  @override
  Widget build(BuildContext context) {
    final net = _resolveNetwork();
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: net.color.withValues(alpha: 1),
          fontWeight: FontWeight.w600,
        );
    final dimStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: net.color.withValues(alpha: 0.85));

    return Material(
      color: net.color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Wrap(
          spacing: 10,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(net.icon, size: 15, color: net.color),
            Text(net.label, style: textStyle),
            if (_deviceName != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.devices_other, size: 13, color: net.color),
                const SizedBox(width: 3),
                Text(_deviceName!, style: dimStyle),
              ]),
            if (_osVersion != null) Text(_osVersion!, style: dimStyle),
            if (_totalRamMb != null)
              Text(_formatRam(_totalRamMb!), style: dimStyle),
          ],
        ),
      ),
    );
  }
}
