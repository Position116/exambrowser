import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, PlatformException;
import 'package:shared_preferences/shared_preferences.dart';

import 'device_status_bar.dart';
import 'exam_screen.dart';

/// Channel kiosk (dipakai untuk cek status device owner Android).
const MethodChannel _kioskChannel = MethodChannel('exam_brow/kiosk');

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _loading = true;

  /// null = sedang cek; true/false = status device owner (Android only).
  bool? _isDeviceOwner;

  @override
  void initState() {
    super.initState();
    _loadSaved();
    _checkDeviceOwner();
  }

  /// Cek apakah app sudah jadi device owner (Lock Task Mode penuh).
  /// Hanya relevan di Android; platform lain dibiarkan null (kartu
  /// tidak tampil).
  Future<void> _checkDeviceOwner() async {
    if (!Platform.isAndroid) return;
    bool owner = false;
    try {
      owner = await _kioskChannel.invokeMethod<bool>('isDeviceOwner') ?? false;
    } on PlatformException {
      owner = false;
    } on MissingPluginException {
      owner = false;
    }
    if (mounted) setState(() => _isDeviceOwner = owner);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _urlController.text = prefs.getString('server_url') ?? '';
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _startExam() async {
    var url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('URL server ujian belum diisi.');
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      _showError('URL tidak valid. Contoh: ujian.sekolah.sch.id');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExamScreen(url: url)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Browser'),
        centerTitle: true,
      ),
      // Bar status perangkat + jaringan realtime, tetap di bagian bawah
      // layar utama (sama seperti di layar ujian).
      bottomNavigationBar: const DeviceStatusBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL server ujian',
                    hintText: 'misal: ujian.sekolah.sch.id',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _startExam,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Mulai Ujian'),
                ),
                const SizedBox(height: 32),
                // Status kiosk Android: device owner (kiosk penuh) atau
                // pinning biasa + petunjuk provisioning via adb.
                if (_isDeviceOwner != null) ...[
                  Card(
                    color: _isDeviceOwner!
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.orange.withValues(alpha: 0.12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isDeviceOwner!
                                    ? Icons.verified_user
                                    : Icons.info_outline,
                                size: 18,
                                color: _isDeviceOwner!
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isDeviceOwner!
                                      ? 'Kiosk penuh aktif (device owner)'
                                      : 'Kiosk standar (screen pinning)',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          if (!_isDeviceOwner!) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Untuk penguncian penuh (tidak bisa keluar '
                              'tanpa PIN), jalankan sekali per HP lewat PC '
                              'dengan adb (HP tanpa akun Google):',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              'adb shell dpm set-device-owner '
                              'com.example.exam_brow/.ExamAdminReceiver',
                              style: Theme.of(context).textTheme.bodySmall!
                                  .copyWith(fontFamily: 'monospace'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copyright,
                      size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ronald Aveiro',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
