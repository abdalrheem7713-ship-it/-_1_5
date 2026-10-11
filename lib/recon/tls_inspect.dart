// =============================================================================
// نَذْر - فحص شهادات TLS/SSL
// =============================================================================
import 'dart:async';
import 'dart:io';

import 'models.dart';

class TlsInspector {
  /// فحص شهادة TLS لموقع معين.
  Future<TlsInfo> inspect(
    String host, {
    int port = 443,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    SecureSocket? socket;
    try {
      final ctx = SecurityContext.defaultContext;
      socket = await SecureSocket.connect(
        host,
        port,
        context: ctx,
        timeout: timeout,
        onBadCertificate: (_) => true, // نقبل الشهادات المنتهية للفحص
      );

      final cert = socket.peerCertificate;
      socket.destroy();

      if (cert == null) {
        return TlsInfo(host: host, port: port, error: 'لا توجد شهادة');
      }

      final validFrom = cert.startValidity;
      final validTo = cert.endValidity;
      final days = validTo.difference(DateTime.now()).inDays;

      return TlsInfo(
        host: host,
        port: port,
        subject: _cleanDN(cert.subject),
        issuer: _cleanDN(cert.issuer),
        validFrom: validFrom,
        validTo: validTo,
        daysRemaining: days,
      );
    } catch (e) {
      socket?.destroy();
      return TlsInfo(host: host, port: port, error: e.toString());
    }
  }

  /// فحص عدة مضيفين.
  Future<List<TlsInfo>> inspectMany(
    List<String> hosts, {
    int port = 443,
    int concurrency = 5,
    void Function(TlsInfo)? onResult,
    void Function(int done, int total)? onProgress,
  }) async {
    final all = <TlsInfo>[];
    var done = 0;

    for (var i = 0; i < hosts.length; i += concurrency) {
      final batch = hosts.skip(i).take(concurrency).toList();
      final results = await Future.wait(batch.map(
        (h) => inspect(h, port: port),
      ));
      for (final r in results) {
        all.add(r);
        done++;
        onResult?.call(r);
        onProgress?.call(done, hosts.length);
      }
    }

    return all;
  }

  /// تنظيف Distinguished Name: مثال "CN=example.com, O=Example Inc".
  static String _cleanDN(String dn) {
    try {
      final parts = dn.split(',');
      final cleaned = <String>[];
      for (final p in parts) {
        final t = p.trim();
        if (t.isEmpty) continue;
        cleaned.add(t);
        if (cleaned.length >= 3) break;
      }
      return cleaned.join(', ');
    } catch (_) {
      return dn;
    }
  }
}