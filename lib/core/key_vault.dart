// =============================================================================
// نَذْر - خزانة المفاتيح الآمنة (flutter_secure_storage)
// =============================================================================
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'crypto.dart';

/// خزانة المفاتيح - تستخدم Keychain (iOS) و Keystore (Android).
/// المفاتيح مشفّرة على مستوى النظام، لا يمكن قراءتها من APK.
class KeyVault {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _masterKey = 'nazr_master_v1';
  static const _hmacKey = 'nazr_hmac_v1';

  /// جلب أو إنشاء مفتاح التشفير الرئيسي (AES-256).
  static Future<Uint8List> getOrCreateMasterKey() => _getOrCreate(_masterKey);

  /// جلب أو إنشاء مفتاح HMAC (لتوقيع الرسائل).
  static Future<Uint8List> getOrCreateHmacKey() => _getOrCreate(_hmacKey);

  static Future<Uint8List> _getOrCreate(String slot) async {
    try {
      final stored = await _storage.read(key: slot);
      if (stored != null) {
        final d = base64.decode(stored);
        if (d.length == 32) return d;
      }
    } catch (_) {
      // في حال فشل القراءة، نولّد مفتاحًا جديدًا
    }
    final fresh = PhantomCipher.generateMasterKey();
    await _storage.write(key: slot, value: base64.encode(fresh));
    return fresh;
  }

  /// حذف كل المفاتيح (يُستخدم عند إعادة التهيئة).
  static Future<void> wipe() async {
    await _storage.delete(key: _masterKey);
    await _storage.delete(key: _hmacKey);
  }

  /// فحص وجود مفاتيح مخزّنة.
  static Future<bool> hasKeys() async {
    try {
      final m = await _storage.read(key: _masterKey);
      final h = await _storage.read(key: _hmacKey);
      return m != null && h != null;
    } catch (_) {
      return false;
    }
  }
}