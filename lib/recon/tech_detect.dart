// =============================================================================
// نَذْر - كشف التقنيات (Wappalyzer-style)
// =============================================================================
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

class TechDetector {
  List<_TechSignature>? _signatures;

  /// تحميل التوقيعات من assets.
  Future<List<_TechSignature>> _loadSignatures() async {
    if (_signatures != null) return _signatures!;
    try {
      final content = await rootBundle.loadString('assets/technologies.json');
      final data = jsonDecode(content) as List;
      _signatures = data
          .map((e) => _TechSignature.fromJson(e as Map<String, dynamic>))
          .toList();
      return _signatures!;
    } catch (_) {
      return const [];
    }
  }

  /// كشف التقنيات من استجابة HTTP.
  Future<List<String>> detect(HttpInfo info) async {
    final signatures = await _loadSignatures();
    final found = <String>{};
    final body = ''; // لا نحتفظ بـ body في HttpInfo حاليًا

    for (final sig in signatures) {
      if (_matches(sig, info, body)) {
        found.add(sig.name);
      }
    }

    return found.toList()..sort();
  }

  bool _matches(_TechSignature sig, HttpInfo info, String body) {
    // 1) HTTP headers
    for (final entry in sig.headers.entries) {
      final headerName = entry.key.toLowerCase();
      final pattern = entry.value;
      for (final h in info.headers.entries) {
        if (h.key.toLowerCase() == headerName) {
          if (pattern.isEmpty || h.value.contains(pattern)) return true;
        }
      }
    }

    // 2) HTML content
    if (body.isNotEmpty) {
      for (final snippet in sig.html) {
        if (body.contains(snippet)) return true;
      }
    }

    // 3) Title
    if (info.title != null) {
      for (final snippet in sig.html) {
        if (info.title!.contains(snippet)) return true;
      }
    }

    return false;
  }

  /// كشف جماعي على قائمة.
  Future<Map<String, List<String>>> detectMany(
    List<HttpInfo> infos, {
    void Function(String host, List<String> techs)? onResult,
  }) async {
    final result = <String, List<String>>{};
    for (final info in infos) {
      final techs = await detect(info);
      if (techs.isNotEmpty) {
        result[info.url] = techs;
        onResult?.call(info.url, techs);
      }
    }
    return result;
  }
}

// =============================================================================
// التوقيع الداخلي
// =============================================================================
class _TechSignature {
  final String name;
  final List<String> categories;
  final Map<String, String> headers;
  final List<String> html;

  _TechSignature({
    required this.name,
    required this.categories,
    required this.headers,
    required this.html,
  });

  factory _TechSignature.fromJson(Map<String, dynamic> j) {
    return _TechSignature(
      name: j['name'] as String? ?? '',
      categories: (j['cats'] as List?)?.cast<String>() ?? const [],
      headers: (j['headers'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v.toString())) ??
          const {},
      html: (j['html'] as List?)?.cast<String>() ?? const [],
    );
  }
}