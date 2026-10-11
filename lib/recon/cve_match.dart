// =============================================================================
// نَذْر - مطابقة CVE (كشف فقط — لا استغلال)
// =============================================================================
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

class CveMatcher {
  List<_CveSignature>? _signatures;

  /// تحميل قاعدة CVEs من assets.
  Future<List<_CveSignature>> _loadSignatures() async {
    if (_signatures != null) return _signatures!;
    try {
      final content = await rootBundle.loadString('assets/cves.json');
      final data = jsonDecode(content) as List;
      _signatures = data
          .map((e) => _CveSignature.fromJson(e as Map<String, dynamic>))
          .toList();
      return _signatures!;
    } catch (_) {
      return const [];
    }
  }

  /// مطابقة CVEs بناءً على الـ HTTP server header والتقنيات المكتشفة.
  Future<List<CveMatch>> match(
    List<HttpInfo> httpResults,
    List<String> detectedTech,
  ) async {
    final sigs = await _loadSignatures();
    final found = <String, CveMatch>{};

    // اجمع دلائل الإصدارات من headers + التقنيات
    final evidence = <String, String>{};

    for (final h in httpResults) {
      final server = h.server?.toLowerCase() ?? '';
      if (server.isNotEmpty) {
        evidence['server'] = server;
        _extractProductVersion(server, evidence);
      }
      for (final hHeader in h.headers.entries) {
        final key = hHeader.key.toLowerCase();
        final value = hHeader.value.toLowerCase();
        if (key == 'x-powered-by' || key == 'server') {
          _extractProductVersion(value, evidence);
        }
      }
    }

    for (final tech in detectedTech) {
      evidence[tech.toLowerCase()] = tech.toLowerCase();
    }

    // ابحث عن تطابق
    for (final sig in sigs) {
      final productKey = sig.product.toLowerCase();
      final hasProduct = evidence.keys.any(
        (k) => k.contains(productKey) || productKey.contains(k),
      );
      final hasTech = detectedTech.any(
        (t) => t.toLowerCase().contains(productKey),
      );

      if (hasProduct || hasTech) {
        final matchedOn = evidence[productKey] ??
            detectedTech.firstWhere(
              (t) => t.toLowerCase().contains(productKey),
              orElse: () => productKey,
            );

        found[sig.id] = CveMatch(
          id: sig.id,
          name: sig.name,
          severity: _parseSeverity(sig.severity),
          cvss: sig.cvss,
          product: sig.product,
          description: sig.description,
          matchedOn: matchedOn,
        );
      }
    }

    final list = found.values.toList()
      ..sort((a, b) => b.cvss.compareTo(a.cvss));
    return list;
  }

  /// استخراج "product/version" من نصوص مثل "Apache/2.4.49".
  static void _extractProductVersion(String text, Map<String, String> out) {
    try {
      final parts = text.split(' ');
      for (final p in parts) {
        final slash = p.indexOf('/');
        if (slash > 0) {
          final product = p.substring(0, slash).toLowerCase();
          final version = p.substring(slash + 1);
          if (product.isNotEmpty) {
            out[product] = version;
          }
        }
      }
    } catch (_) {}
  }

  static Severity _parseSeverity(String s) {
    switch (s.toLowerCase()) {
      case 'حرجة':
      case 'critical':
        return Severity.critical;
      case 'عالية':
      case 'high':
        return Severity.high;
      case 'متوسطة':
      case 'medium':
        return Severity.medium;
      case 'منخفضة':
      case 'low':
        return Severity.low;
      default:
        return Severity.info;
    }
  }
}

// =============================================================================
// التوقيع الداخلي
// =============================================================================
class _CveSignature {
  final String id;
  final String name;
  final String severity;
  final double cvss;
  final String product;
  final List<String> affected;
  final String description;

  _CveSignature({
    required this.id,
    required this.name,
    required this.severity,
    required this.cvss,
    required this.product,
    required this.affected,
    required this.description,
  });

  factory _CveSignature.fromJson(Map<String, dynamic> j) {
    return _CveSignature(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      severity: j['severity'] as String? ?? 'info',
      cvss: (j['cvss'] as num?)?.toDouble() ?? 0.0,
      product: j['product'] as String? ?? '',
      affected: (j['affected'] as List?)?.cast<String>() ?? const [],
      description: j['description'] as String? ?? '',
    );
  }
}