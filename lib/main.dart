// =============================================================================
// نَذْر - نقطة الدخول الرئيسية
// =============================================================================
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/audit_log.dart';
import 'core/consent.dart';
import 'core/crypto.dart';
import 'core/key_vault.dart';
import 'core/strings_ar.dart';
import 'core/theme.dart';
import 'core/whitelist.dart';
import 'recon/recon_engine.dart';
import 'state/recon_controller.dart';
import 'ui/dashboard.dart';
import 'ui/onboarding.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NazrApp());
}

class NazrApp extends StatefulWidget {
  const NazrApp({super.key});

  @override
  State<NazrApp> createState() => _NazrAppState();
}

class _NazrAppState extends State<NazrApp> {
  static const _whitelistKey = 'nazr_whitelist_v1';

  bool _loading = true;
  bool _consentGiven = false;
  String? _error;

  ReconController? _controller;
  Whitelist? _whitelist;
  AuditLog? _audit;
  PhantomCipher? _cipher;
  HmacAuth? _hmac;

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    final given = await Consent.isGiven();
    if (given) {
      await _boot();
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptConsent() async {
    await Consent.give();
    if (mounted) {
      setState(() => _consentGiven = true);
    }
    await _boot();
  }

  Future<void> _boot() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // 1) المفاتيح
      final masterKey = await KeyVault.getOrCreateMasterKey();
      final hmacKey = await KeyVault.getOrCreateHmacKey();
      _cipher = PhantomCipher(masterKey);
      _hmac = HmacAuth(hmacKey);

      // 2) القائمة البيضاء (تُحمّل من التخزين المحلي)
      _whitelist = Whitelist();
      final prefs = await SharedPreferences.getInstance();
      final wl = prefs.getString(_whitelistKey);
      if (wl != null) {
        try {
          _whitelist!.loadFrom(jsonDecode(wl) as Map<String, dynamic>);
        } catch (_) {}
      }

      // 3) السجل الموقّع
      _audit = AuditLog();
      _audit!.append('app_boot', {
        'version': '1.0.0',
        'ts': DateTime.now().toIso8601String(),
      });

      // 4) المحرّك والمتحكم
      final engine = ReconEngine();
      _controller = ReconController(
        whitelist: _whitelist!,
        audit: _audit!,
        engine: engine,
      );

      _controller!.log('✓ تم تشغيل نَذْر');
      _controller!.log('  المفاتيح: محمّلة');
      _controller!.log(
        '  القائمة البيضاء: ${_whitelist!.domains.length + _whitelist!.cidrs.length} مدخل',
      );
    } catch (e, st) {
      _error = '$e\n\n$st';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _wipeKeys() async {
    await KeyVault.wipe();
    if (_controller != null) {
      _controller!.log('✓ مُسحت المفاتيح. أعد التشغيل لتوليد مفاتيح جديدة');
      _controller!.audit.append('wipe_keys', {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: S.appName,
      theme: AppTheme.dark,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    if (_loading) {
      return const _LoadingScreen();
    }

    if (!_consentGiven && _controller == null) {
      return OnboardingScreen(onAccept: _acceptConsent);
    }

    if (_error != null) {
      return _ErrorScreen(
        error: _error!,
        onRetry: _boot,
      );
    }

    if (_controller == null || _whitelist == null) {
      return OnboardingScreen(onAccept: _acceptConsent);
    }

    return Dashboard(
      controller: _controller!,
      whitelist: _whitelist!,
      onWipeKeys: _wipeKeys,
    );
  }
}

// =============================================================================
// شاشة التحميل
// =============================================================================
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryLight,
                  width: 2,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation(AppTheme.primaryLight),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              S.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'جاري التهيئة...',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// شاشة الخطأ
// =============================================================================
class _ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppTheme.danger,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                S.bootFailed,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.danger,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  error,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text(S.retry),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}