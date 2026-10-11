// =============================================================================
// نَذْر - السجل الموقّع (hash chain)
// =============================================================================
// كل عملية تُسجَّل ببصمة مرتبطة بالسجل السابق.
// أي تعديل في المنتصف يكسر السلسلة — يمكن كشفه.

import 'dart:convert';

import 'package:crypto/crypto.dart';

class AuditEntry {
  final DateTime timestamp;
  final String action;
  final Map<String, dynamic> data;
  final String prevHash;
  final String hash;

  AuditEntry({
    required this.timestamp,
    required this.action,
    required this.data,
    required this.prevHash,
    required this.hash,
  });

  Map<String, dynamic> toJson() => {
        'ts': timestamp.toIso8601String(),
        'action': action,
        'data': data,
        'prev': prevHash,
        'hash': hash,
      };
}

/// سجل تدقيق بسلسلة hash — يكشف أي تعديل.
class AuditLog {
  final List<AuditEntry> _entries = [];
  String _lastHash = 'GENESIS';

  List<AuditEntry> get entries => List.unmodifiable(_entries);
  String get lastHash => _lastHash;
  int get length => _entries.length;
  bool get isEmpty => _entries.isEmpty;

  /// إضافة سجل جديد.
  void append(String action, Map<String, dynamic> data) {
    final ts = DateTime.now();
    final payload = jsonEncode({
      'ts': ts.toIso8601String(),
      'action': action,
      'data': data,
      'prev': _lastHash,
    });
    final hash = sha256.convert(utf8.encode(payload)).toString();
    _entries.add(AuditEntry(
      timestamp: ts,
      action: action,
      data: data,
      prevHash: _lastHash,
      hash: hash,
    ));
    _lastHash = hash;
  }

  /// التحقق من سلامة السلسلة.
  /// يعيد -1 إذا سليمة، وإلا مؤشر أول سجل مكسور.
  int verify() {
    var prev = 'GENESIS';
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (e.prevHash != prev) return i;
      final payload = jsonEncode({
        'ts': e.timestamp.toIso8601String(),
        'action': e.action,
        'data': e.data,
        'prev': e.prevHash,
      });
      final expected = sha256.convert(utf8.encode(payload)).toString();
      if (expected != e.hash) return i;
      prev = e.hash;
    }
    return -1;
  }

  /// تصدير السجل كاملًا JSON.
  Map<String, dynamic> exportJson() => {
        'count': _entries.length,
        'last_hash': _lastHash,
        'integrity': verify() == -1 ? 'VALID' : 'BROKEN',
        'entries': _entries.map((e) => e.toJson()).toList(),
      };

  /// مسح السجل.
  void clear() {
    _entries.clear();
    _lastHash = 'GENESIS';
  }
}