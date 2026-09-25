import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// ============================================================
/// KONFIGURASI AUTO-UPDATE
///
/// Ganti dengan repo GitHub kamu (format: pemilik/repo), lalu
/// upload APK sebagai "Release" di repo tersebut (panduan lengkap
/// di SETUP.md bagian Auto-Update).
///
/// Selama repo belum ada / belum ada Release / perangkat offline,
/// cek update gagal dan aplikasi tetap berjalan normal (fail-open).
/// ============================================================
const String kUpdateRepo = 'ronaldaveiro/exambrow';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.newVersion,
    required this.apkUrl,
    required this.apkName,
  });

  final String currentVersion;
  final String newVersion;
  final String apkUrl;
  final String apkName;
}

/// Cek Release terbaru di GitHub.
/// Return null jika: tidak ada versi lebih baru, tidak ada asset APK,
/// atau cek gagal (offline / rate-limit / repo salah).
Future<UpdateCheckResult?> checkForUpdate() async {
  try {
    final pkg = await PackageInfo.fromPlatform();
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/vnd.github+json'},
      ),
    );
    final res = await dio
        .get<Map<String, dynamic>>('https://api.github.com/repos/$kUpdateRepo/releases/latest');
    final data = res.data;
    if (data == null) return null;

    final tag = (data['tag_name'] ?? '') as String;
    final newVersion = tag.replaceFirst(RegExp(r'^[vV]'), '');
    if (!_isNewer(newVersion, pkg.version)) return null;

    // Pilih asset APK: utamakan arm64-v8a, fallback asset .apk pertama.
    String? url;
    String? name;
    for (final asset in (data['assets'] as List? ?? const [])) {
      final map = asset as Map<String, dynamic>;
      final assetName = (map['name'] ?? '') as String;
      if (!assetName.endsWith('.apk')) continue;
      if (assetName.contains('arm64')) {
        url = map['browser_download_url'] as String?;
        name = assetName;
        break;
      }
      url ??= map['browser_download_url'] as String?;
      name ??= assetName;
    }
    if (url == null || name == null) return null;

    return UpdateCheckResult(
      currentVersion: pkg.version,
      newVersion: newVersion,
      apkUrl: url,
      apkName: name,
    );
  } catch (_) {
    return null; // fail-open: jangan blokir ujian karena cek update gagal
  }
}

/// Bandingkan versi semantik sederhana: "1.2.3" vs "1.10.0" dsb.
bool _isNewer(String candidate, String current) {
  List<int> parse(String v) => v
      .split(RegExp(r'[.+\-]'))
      .map((e) => int.tryParse(e) ?? 0)
      .toList();
  final a = parse(candidate);
  final b = parse(current);
  final n = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < n; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

/// Layar update WAJIB: muncul saat ada versi lebih baru di GitHub.
/// Tidak bisa ditutup — pengawas harus meng-install versi baru dulu.
/// Unduh otomatis, lalu buka installer Android. Setelah APK dibuka,
/// user tinggal menekan "Install" di dialog sistem.
class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key, required this.result});

  final UpdateCheckResult result;

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  double? _progress; // 0.0 - 1.0, null = belum mulai
  String? _error;
  String? _apkPath;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    setState(() {
      _progress = 0;
      _error = null;
      _apkPath = null;
    });
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${widget.result.apkName}';
      await Dio().download(
        widget.result.apkUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );
      _apkPath = path;
      await _openInstaller();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal mengunduh pembaruan. Periksa koneksi internet.';
          _progress = null;
        });
      }
    }
  }

  Future<void> _openInstaller() async {
    if (_apkPath == null) return;
    await OpenFilex.open(_apkPath!);
    // Installer ditutup tanpa install? Layar tetap di sini (wajib update),
    // tombol "Install Sekarang" bisa dipakai membuka installer lagi.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.system_update,
                  size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Pembaruan Tersedia',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Versi ${widget.result.newVersion} tersedia '
                '(terpasang: ${widget.result.currentVersion}).\n'
                'Aplikasi harus diperbarui sebelum digunakan.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _download,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ] else if (_apkPath != null) ...[
                const Text(
                  'Unduhan selesai. Buka file APK dan tekan "Install".',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _openInstaller,
                  icon: const Icon(Icons.install_mobile),
                  label: const Text('Install Sekarang'),
                ),
              ] else ...[
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
                Text(
                  _progress != null && _progress! > 0
                      ? 'Mengunduh... ${(_progress! * 100).toStringAsFixed(0)}%'
                      : 'Mengunduh...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
