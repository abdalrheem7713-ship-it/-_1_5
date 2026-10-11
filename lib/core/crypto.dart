// =============================================================================
// نَذْر - طبقة التشفير AES-256-GCM + HMAC-SHA256
// =============================================================================
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// تشفير متماثل AES-256-GCM مع بيانات مرتبطة (AAD).
class PhantomCipher {
  final Uint8List _secretKey;
  static final Random _rng = Random.secure();
  static const int _nonceLen = 12;
  static const int _tagLen = 16;

  /// بيانات مرتبطة تربط النص المشفر بسياقه.
  static final Uint8List _aad =
      Uint8List.fromList(utf8.encode('nazr/v1/ipc'));

  PhantomCipher(this._secretKey) {
    if (_secretKey.length != 32) {
      throw ArgumentError('المفتاح يجب أن يكون 32 بايت بالضبط.');
    }
  }

  /// توليد مفتاح رئيسي جديد عشوائي 256-bit.
  static Uint8List generateMasterKey() {
    final k = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      k[i] = _rng.nextInt(256);
    }
    return k;
  }

  /// تشفير نص عادي -> base64
  String encrypt(String text) {
    final nonce = _randomBytes(_nonceLen);
    final c = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(_secretKey), 128, nonce, _aad));
    final ct = c.process(Uint8List.fromList(utf8.encode(text)));
    final p = BytesBuilder()
      ..add(nonce)
      ..add(ct);
    return base64.encode(p.toBytes());
  }

  /// فك تشفير base64 -> نص عادي
  String decrypt(String b64) {
    final data = base64.decode(b64);
    if (data.length < _nonceLen + _tagLen) {
      throw const FormatException('حزمة تالفة أو مبتورة.');
    }
    final nonce = data.sublist(0, _nonceLen);
    final ct = data.sublist(_nonceLen);
    final c = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(_secretKey), 128, nonce, _aad));
    return utf8.decode(c.process(ct));
  }

  static Uint8List _randomBytes(int n) {
    final b = Uint8List(n);
    for (var i = 0; i < n; i++) {
      b[i] = _rng.nextInt(256);
    }
    return b;
  }
}

/// HMAC-SHA256 مع تحقق بزمن ثابت (constant-time).
class HmacAuth {
  final List<int> _secret;
  HmacAuth(this._secret);

  /// توقيع حمولة مع nonce اختياري.
  String sign(String payload, {String? nonce}) {
    final data = nonce == null ? payload : '$nonce|$payload';
    return Hmac(sha256, _secret).convert(utf8.encode(data)).toString();
  }

  /// التحقق من التوقيع بمقارنة ثابتة الزمن.
  bool verify(String payload, String sig, {String? nonce}) {
    final expected = sign(payload, nonce: nonce);
    if (expected.length != sig.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected.codeUnitAt(i) ^ sig.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// توليد nonce عشوائي آمن (لا يمكن التنبؤ به).
  static String secureNonce() {
    final rng = Random.secure();
    final bytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return base64Url.encode(bytes);
  }
}