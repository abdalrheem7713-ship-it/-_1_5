// =============================================================================
// نَذْر - تتبّع الموافقة القانونية
// =============================================================================
// تُحفظ محليًا في shared_preferences.
// يُطلب من المستخدم الموافقة مرة واحدة عند أول تشغيل.

import 'package:shared_preferences/shared_preferences.dart';

class Consent {
  static const _key = 'nazr_consent_v1';
  static const _acceptedAtKey = 'nazr_consent_at_v1';

  /// هل وافق المستخدم من قبل؟
  static Future<bool> isGiven() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  /// حفظ الموافقة.
  static Future<void> give() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    await prefs.setString(
      _acceptedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// إلغاء الموافقة (يُستخدم عند مسح المفاتيح).
  static Future<void> revoke() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_acceptedAtKey);
  }

  /// وقت الموافقة (للسجل القانوني).
  static Future<String?> acceptedAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_acceptedAtKey);
  }
}