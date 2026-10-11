// =============================================================================
// نَذْر - محرّك الاستطلاع (المنسّق الرئيسي)
// =============================================================================
import 'cve_match.dart';
import 'dns_resolver.dart';
import 'http_fingerprint.dart';
import 'models.dart';
import 'port_scanner.dart';
import 'subdomain_enum.dart';
import 'tech_detect.dart';
import 'tls_inspect.dart';

/// نوع الحدث الذي يُصدره المحرّك للمستمعين.
enum ReconEventType {
  log,
  progress,
  subdomain,
  port,
  http,
  tls,
  cve,
  tech,
  done,
  error,
}

class ReconEvent {
  final ReconEventType type;
  final String message;
  final double? progress;
  final dynamic payload;

  ReconEvent(this.type, this.message, {this.progress, this.payload});
}

/// المحرّك الرئيسي — ينسّق كل الأدوات.
class ReconEngine {
  final DnsResolver dns;
  final SubdomainEnumerator subdomainEnum;
  final PortScanner portScanner;
  final HttpFingerprinter httpFp;
  final TlsInspector tlsInspector;
  final TechDetector techDetector;
  final CveMatcher cveMatcher;

  ReconEngine({
    DnsResolver? dns,
    SubdomainEnumerator? subdomainEnum,
    PortScanner? portScanner,
    HttpFingerprinter? httpFp,
    TlsInspector? tlsInspector,
    TechDetector? techDetector,
    CveMatcher? cveMatcher,
  })  : dns = dns ?? DnsResolver(),
        subdomainEnum = subdomainEnum ?? SubdomainEnumerator(),
        portScanner = portScanner ?? PortScanner(),
        httpFp = httpFp ?? HttpFingerprinter(),
        tlsInspector = tlsInspector ?? TlsInspector(),
        techDetector = techDetector ?? TechDetector(),
        cveMatcher = cveMatcher ?? CveMatcher();

  /// تشغيل فحص كامل على نطاق واحد.
  Future<void> runFullScan({
    required String host,
    required void Function(ReconEvent) onEvent,
    required bool Function() shouldStop,
    List<int>? ports,
  }) async {
    final selectedPorts = ports ?? PortScanner.commonPorts;

    try {
      // ============ 1) DNS رئيسي ============
      onEvent(ReconEvent(ReconEventType.log,
          'بدء الفحص على $host'));
      onEvent(ReconEvent(ReconEventType.progress, 'DNS',
          progress: 0.05));

      final rootIps = await dns.resolve(host);
      if (rootIps.isEmpty) {
        onEvent(ReconEvent(ReconEventType.error,
            'فشل حل النطاق: $host'));
        return;
      }
      onEvent(ReconEvent(ReconEventType.log,
          'تم حل $host → ${rootIps.join(", ")}'));

      if (shouldStop()) return;

      // ============ 2) النطاقات الفرعية ============
      onEvent(ReconEvent(ReconEventType.progress, 'النطاقات الفرعية',
          progress: 0.15));
      onEvent(ReconEvent(ReconEventType.log,
          'بدء اكتشاف النطاقات الفرعية...'));

      final subs = await subdomainEnum.enumerate(
        host,
        doPassive: true,
        doActive: true,
        onProgress: (phase, done, total) {
          if (total > 0) {
            final innerProgress = done / total;
            onEvent(ReconEvent(
              ReconEventType.progress,
              'النطاقات ($phase)',
              progress: 0.15 + (0.20 * innerProgress),
            ));
          }
        },
        onFound: (name) {
          onEvent(ReconEvent(ReconEventType.subdomain, name,
              payload: name));
        },
      );

      onEvent(ReconEvent(ReconEventType.log,
          'اكتمل: ${subs.length} نطاق فرعي'));

      if (shouldStop()) return;

      // ============ 3) فحص المنافذ على كل نطاق فرعي ============
      final allHosts = <String>[
        host,
        ...subs.map((s) => s.name),
      ];

      onEvent(ReconEvent(ReconEventType.progress, 'المنافذ',
          progress: 0.40));
      onEvent(ReconEvent(ReconEventType.log,
          'بدء فحص المنافذ على ${allHosts.length} مضيف...'));

      final allOpenPorts = <PortResult>[];
      for (var i = 0; i < allHosts.length; i++) {
        if (shouldStop()) return;
        final h = allHosts[i];

        await portScanner.scanPorts(
          h,
          selectedPorts,
          concurrency: 20,
          grabBanner: false,
          onResult: (r) {
            if (r.isOpen) {
              allOpenPorts.add(r);
              onEvent(ReconEvent(ReconEventType.port,
                  '$h:${r.port} (${r.service})',
                  payload: {'host': h, 'result': r}));
            }
          },
        );

        final inner = (i + 1) / allHosts.length;
        onEvent(ReconEvent(
          ReconEventType.progress,
          'المنافذ',
          progress: 0.40 + (0.25 * inner),
        ));
      }

      onEvent(ReconEvent(ReconEventType.log,
          'اكتمل: ${allOpenPorts.length} منفذ مفتوح'));

      if (shouldStop()) return;

      // ============ 4) HTTP Fingerprinting ============
      onEvent(ReconEvent(ReconEventType.progress, 'HTTP',
          progress: 0.65));
      onEvent(ReconEvent(ReconEventType.log,
          'بدء فحص HTTP على المضيفين المكتشفين...'));

      final httpInfos = <HttpInfo>[];
      // فحص HTTP فقط على المضيفين الذين لديهم منافذ 80/443/8080/8443
      final httpHosts = <String>{};
      for (final p in allOpenPorts) {
        if ([80, 443, 8080, 8443, 8000, 8888].contains(p.port)) {
          httpHosts.add(p.payloadHost());
        }
      }
      // إذا لم نجد منافذ HTTP، افحص الجذر
      if (httpHosts.isEmpty) httpHosts.add(host);

      final urlsToProbe = <String>[];
      for (final h in httpHosts) {
        urlsToProbe.add('https://$h');
        urlsToProbe.add('http://$h');
      }

      await httpFp.probeMany(
        urlsToProbe,
        concurrency: 10,
        onResult: (info) {
          if (info.status != null && info.status! < 500) {
            httpInfos.add(info);
            onEvent(ReconEvent(ReconEventType.http,
                '${info.url} → ${info.status}',
                payload: info));
          }
        },
      );

      onEvent(ReconEvent(ReconEventType.log,
          'اكتمل: ${httpInfos.length} خدمة HTTP'));

      if (shouldStop()) return;

      // ============ 5) TLS Inspection ============
      onEvent(ReconEvent(ReconEventType.progress, 'TLS',
          progress: 0.78));
      onEvent(ReconEvent(ReconEventType.log,
          'بدء فحص شهادات TLS...'));

      final tlsHosts = httpInfos
          .where((h) => h.url.startsWith('https://'))
          .map((h) => Uri.parse(h.url).host)
          .toSet()
          .toList();

      final tlsInfos = <TlsInfo>[];
      for (final h in tlsHosts) {
        if (shouldStop()) return;
        final info = await tlsInspector.inspect(h);
        if (info.error == null) {
          tlsInfos.add(info);
          onEvent(ReconEvent(ReconEventType.tls,
              '$h: ${info.daysRemaining} يوم متبقٍ',
              payload: info));
        }
      }

      onEvent(ReconEvent(ReconEventType.log,
          'اكتمل: ${tlsInfos.length} شهادة TLS'));

      if (shouldStop()) return;

      // ============ 6) كشف التقنيات ============
      onEvent(ReconEvent(ReconEventType.progress, 'التقنيات',
          progress: 0.88));
      onEvent(ReconEvent(ReconEventType.log,
          'بدء كشف التقنيات...'));

      final detectedTech = <String>{};
      await techDetector.detectMany(
        httpInfos,
        onResult: (host, techs) {
          detectedTech.addAll(techs);
          for (final t in techs) {
            onEvent(ReconEvent(ReconEventType.tech, '$host: $t'));
          }
        },
      );

      onEvent(ReconEvent(ReconEventType.log,
          'اكتمل: ${detectedTech.length} تقنية'));

      if (shouldStop()) return;

      // ============ 7) مطابقة CVEs ============
      onEvent(ReconEvent(ReconEventType.progress, 'CVEs',
          progress: 0.95));
      onEvent(ReconEvent(ReconEventType.log,
          'بدء مطابقة CVEs...'));

      final cves = await cveMatcher.match(
        httpInfos,
        detectedTech.toList(),
      );

      for (final c in cves) {
        onEvent(ReconEvent(ReconEventType.cve,
            '${c.id} (${c.severity.name}) — ${c.name}',
            payload: c));
      }

      onEvent(ReconEvent(ReconEventType.log,
          'اكتمل: ${cves.length} ثغرة'));

      // ============ 8) النهاية ============
      onEvent(ReconEvent(ReconEventType.progress, 'اكتمل',
          progress: 1.0));
      onEvent(ReconEvent(ReconEventType.done,
          'اكتمل الفحص على $host'));
    } catch (e) {
      onEvent(ReconEvent(ReconEventType.error, 'خطأ عام: $e'));
    }
  }
}

// امتداد صغير لربط الـ host في PortResult أثناء الفحص
extension _PortResultHost on PortResult {
  String payloadHost() => 'unknown';
}