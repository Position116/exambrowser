import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, PlatformException, SystemChrome, SystemUiMode;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/// Channel kiosk mode Android (implementasi di MainActivity.kt).
const MethodChannel _kioskChannel = MethodChannel('exam_brow/kiosk');

/// window_manager hanya ada di desktop; panggilan di Android/iOS
/// akan melempar MissingPluginException (harus di-guard).
final bool _isDesktop = !kIsWeb &&
    (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, required this.url});

  final String url;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with WindowListener {
  late final Uri _examUri = Uri.parse(widget.url);

  /// JavaScript yang diinjeksi ke halaman ujian untuk memblokir copy-paste:
  /// larang seleksi teks, salin, potong, tempel, drag, dan menu klik-kanan.
  /// Di-subscribe pada fase capture supaya sebelum aksi handler situs.
  static const String _blockClipboardJs = r'''
(function() {
  if (window.__exambrowInstalled) return;
  window.__exambrowInstalled = true;
  var style = document.createElement('style');
  style.textContent =
    '*,*::before,*::after{-webkit-user-select:none!important;' +
    'user-select:none!important;-webkit-touch-callout:none!important;' +
    '-webkit-user-drag:none!important;}' +
    '::selection{background:transparent!important;}';
  document.addEventListener('DOMContentLoaded', function() {
    document.head.appendChild(style);
  });
  if (document.head) document.head.appendChild(style);
  ['copy', 'cut', 'paste', 'contextmenu', 'selectstart', 'dragstart']
    .forEach(function(type) {
      document.addEventListener(type, function(e) {
        e.preventDefault();
        return false;
      }, true);
    });
})();
''';

  @override
  void initState() {
    super.initState();
    if (_isDesktop) windowManager.addListener(this);
    _enterKiosk();
  }

  @override
  void dispose() {
    if (_isDesktop) windowManager.removeListener(this);
    super.dispose();
  }

  /// Mode kiosk:
  /// - Android: screen pinning (startLockTask, home/recents tidak bisa keluar),
  ///   layar selalu menyala (tidak sleep -> lock screen tidak muncul),
  ///   dan immersive mode (status bar & nav bar disembunyikan).
  /// - Desktop: fullscreen, selalu di atas, blokir tombol close.
  Future<void> _enterKiosk() async {
    if (Platform.isAndroid) {
      // Layar selalu menyala selama ujian + sembunyikan status/nav bar.
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      try {
        await _kioskChannel.invokeMethod('start');
      } on PlatformException {
        // Kiosk gagal aktif; aplikasi tetap jalan dengan whitelist webview.
      } on MissingPluginException {
        // Implementasi native tidak ada (mis. hot restart).
      }
      return;
    }
    if (!_isDesktop) return;
    await windowManager.setFullScreen(true);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setPreventClose(true);
  }

  Future<void> _exitKiosk() async {
    if (Platform.isAndroid) {
      try {
        await _kioskChannel.invokeMethod('stop');
      } on PlatformException {
        // Abaikan.
      } on MissingPluginException {
        // Abaikan.
      }
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      return;
    }
    if (!_isDesktop) return;
    await windowManager.setPreventClose(false);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setFullScreen(false);
  }

  /// Dipanggil saat tombol close jendela Windows ditekan.
  @override
  void onWindowClose() async {
    if (!_isDesktop) return;
    final ok = await _askPin();
    if (!ok || !mounted) return;
    await _exitKiosk();
    if (mounted) Navigator.of(context).pop();
  }

  /// Keluar via tombol kecil di pojok (jalan di semua platform).
  Future<void> _requestExit() async {
    final ok = await _askPin();
    if (!ok || !mounted) return;
    await _exitKiosk();
    if (mounted) Navigator.of(context).pop();
  }

  /// Minta PIN pengawas sebelum keluar dari mode ujian.
  Future<bool> _askPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('pin') ?? '123456';
    if (!mounted) return false;
    final pinController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar Mode Ujian'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Masukkan PIN pengawas',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final ok = pinController.text.trim() == savedPin;
              Navigator.of(dialogContext).pop(ok);
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    // Android: tombol back tidak bisa keluar tanpa PIN.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _requestExit();
      },
      child: Scaffold(
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                supportZoom: false,
                disableContextMenu: true,
                disableLongPressContextMenuOnLinks: true,
              ),
              // Blokir copy-paste & seleksi teks di dalam halaman ujian.
              // (Tombol/dropdown situs tetap berfungsi; hanya seleksi & clipboard
              // yang dimatikan. Keyboard tetap normal untuk menjawab soal.)
              onLoadStop: (controller, url) async {
                await controller.evaluateJavascript(
                  source: _blockClipboardJs,
                );
              },
              // Whitelist: hanya host server ujian yang boleh dibuka.
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final target = navigationAction.request.url;
                if (target == null || target.host != _examUri.host) {
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
            ),
            // Tombol keluar kecil di pojok kanan bawah (untuk pengawas).
            Positioned(
              right: 8,
              bottom: 8,
              child: Opacity(
                opacity: 0.35,
                child: IconButton(
                  tooltip: 'Keluar mode ujian',
                  icon: const Icon(Icons.lock_outline),
                  onPressed: _requestExit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
