// =============================================================================
// نَذْر - بصمة HTTP (كشف الخادم والعنوان)
// =============================================================================
import 'dart:async';

import 'package:http/http.dart' as http;

import 'models.dart';

class HttpFingerprinter {
  /// فحص عنوان URL واستخراج المعلومات.
  Future<HttpInfo> probe(
    String url, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final sw = Stopwatch()..start();
    try {
      final client = http.Client();
      try {
        final uri = Uri.parse(url);
        final response = await client
            .get(uri, headers: {'User-Agent': 'Nazr-Recon/1.0'})
            .timeout(timeout);
        sw.stop();

        final title = _extractTitle(response.body);
        final server = response.headers['server'];

        return HttpInfo(
          url: url,
          status: response.statusCode,
          server: server,
          title: title,
          headers: Map<String, String>.from(response.headers),
          latency: sw.elapsed,
        );
      } finally {
        client.close();
      }
    } catch (e) {
      sw.stop();
      return HttpInfo(url: url, latency: sw.elapsed);
    }
  }

  /// فحص عدة عناوين دفعة واحدة.
  Future<List<HttpInfo>> probeMany(
    List<String> urls, {
    int concurrency = 10,
    Duration timeout = const Duration(seconds: 10),
    void Function(HttpInfo)? onResult,
    void Function(int done, int total)? onProgress,
  }) async {
    final all = <HttpInfo>[];
    var done = 0;

    for (var i = 0; i < urls.length; i += concurrency) {
      final batch = urls.skip(i).take(concurrency).toList();
      final results = await Future.wait(batch.map(
        (u) => probe(u, timeout: timeout),
      ));
      for (final r in results) {
        all.add(r);
        done++;
        onResult?.call(r);
        onProgress?.call(done, urls.length);
      }
    }

    return all;
  }

  /// استخراج عنوان الصفحة من HTML.
  static String? _extractTitle(String html) {
    try {
      final start = html.toLowerCase().indexOf('<title');
      if (start < 0) return null;
      final openEnd = html.indexOf('>', start);
      if (openEnd < 0) return null;
      final close = html.toLowerCase().indexOf('</title>', openEnd);
      if (close < 0) return null;

      var title = html.substring(openEnd + 1, close).trim();
      if (title.length > 200) title = '${title.substring(0, 200)}...';
      return title.isEmpty ? null : title;
    } catch (_) {
      return null;
    }
  }

  /// بناء قائمة عناوين URL للفحص بناءً على النطاقات الفرعية.
  static List<String> buildUrls(List<Subdomain> subs) {
    final urls = <String>[];
    for (final s in subs) {
      urls.add('http://${s.name}');
      urls.add('https://${s.name}');
    }
    return urls;
  }
}