// =============================================================================
// نَذْر - حلال أسماء النطاقات (DNS Resolver)
// =============================================================================
import 'dart:async';
import 'dart:io';

class DnsResolver {
  /// حل نطاق إلى قائمة عناوين IP.
  Future<List<String>> resolve(
    String host, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final addresses = await InternetAddress.lookup(host).timeout(timeout);
      final result = <String>[];
      for (final a in addresses) {
        result.add(a.address);
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  /// حل nطاق + فصل IPv4 عن IPv6.
  Future<DnsResult> resolveDetailed(
    String host, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final sw = Stopwatch()..start();
    try {
      final addresses = await InternetAddress.lookup(host).timeout(timeout);
      sw.stop();

      final v4 = <String>[];
      final v6 = <String>[];
      for (final a in addresses) {
        if (a.type == InternetAddressType.IPv4) {
          v4.add(a.address);
        } else if (a.type == InternetAddressType.IPv6) {
          v6.add(a.address);
        }
      }

      return DnsResult(
        host: host,
        ipv4: v4,
        ipv6: v6,
        latency: sw.elapsed,
      );
    } catch (e) {
      sw.stop();
      return DnsResult(
        host: host,
        ipv4: const [],
        ipv6: const [],
        latency: sw.elapsed,
        error: e.toString(),
      );
    }
  }

  /// حل عكسي (Reverse DNS): من IP إلى اسم النطاق.
  /// ملاحظة: في Dart الحديث، reverse() يعيد InternetAddress واحد.
  Future<List<String>> reverseLookup(
    String ip, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final addr = await InternetAddress(ip).reverse().timeout(timeout);
      if (addr.host.isNotEmpty) {
        return [addr.host];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// فحص سريع: هل النطاق موجود؟
  Future<bool> exists(String host) async {
    final ips = await resolve(host);
    return ips.isNotEmpty;
  }
}

// =============================================================================
// نتيجة حل DNS
// =============================================================================
class DnsResult {
  final String host;
  final List<String> ipv4;
  final List<String> ipv6;
  final Duration latency;
  final String? error;

  DnsResult({
    required this.host,
    required this.ipv4,
    required this.ipv6,
    required this.latency,
    this.error,
  });

  bool get success => error == null && (ipv4.isNotEmpty || ipv6.isNotEmpty);
  int get totalAddresses => ipv4.length + ipv6.length;

  @override
  String toString() {
    if (error != null) return '$host: خطأ - $error';
    if (ipv4.isEmpty && ipv6.isEmpty) return '$host: لا نتائج';
    return '$host: ${ipv4.length} IPv4, ${ipv6.length} IPv6';
  }
}