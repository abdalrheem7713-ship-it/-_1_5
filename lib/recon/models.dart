// =============================================================================
// نَذْر - نماذج البيانات
// =============================================================================

// ---------- حالات الهدف ----------
enum TargetStatus { idle, scanning, up, down, error, blocked }

// ---------- نوع الفحص ----------
enum ScanType {
  full,
  subdomain,
  dns,
  port,
  http,
  tls,
}

// ---------- حالات الخطورة ----------
enum Severity { critical, high, medium, low, info }

// =============================================================================
// النطاق الفرعي
// =============================================================================
class Subdomain {
  final String name;
  final List<String> ips;
  bool isAlive;
  int? httpStatus;
  String? server;
  Duration? latency;

  Subdomain({
    required this.name,
    List<String>? ips,
    this.isAlive = false,
    this.httpStatus,
    this.server,
    this.latency,
  }) : ips = ips ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'ips': ips,
        'alive': isAlive,
        'http_status': httpStatus,
        'server': server,
        'latency_ms': latency?.inMilliseconds,
      };
}

// =============================================================================
// المنفذ
// =============================================================================
class PortResult {
  final int port;
  final bool isOpen;
  final Duration? latency;
  final String? service;
  final String? banner;

  PortResult({
    required this.port,
    required this.isOpen,
    this.latency,
    this.service,
    this.banner,
  });

  Map<String, dynamic> toJson() => {
        'port': port,
        'open': isOpen,
        'latency_ms': latency?.inMilliseconds,
        'service': service,
        'banner': banner,
      };
}

// =============================================================================
// خدمة HTTP
// =============================================================================
class HttpInfo {
  final String url;
  final int? status;
  final String? server;
  final String? title;
  final List<String> technologies;
  final Map<String, String> headers;
  final Duration? latency;

  HttpInfo({
    required this.url,
    this.status,
    this.server,
    this.title,
    List<String>? technologies,
    Map<String, String>? headers,
    this.latency,
  })  : technologies = technologies ?? [],
        headers = headers ?? {};

  Map<String, dynamic> toJson() => {
        'url': url,
        'status': status,
        'server': server,
        'title': title,
        'technologies': technologies,
        'latency_ms': latency?.inMilliseconds,
      };
}

// =============================================================================
// شهادة TLS
// =============================================================================
class TlsInfo {
  final String host;
  final int port;
  final String? subject;
  final String? issuer;
  final DateTime? validFrom;
  final DateTime? validTo;
  final int? daysRemaining;
  final String? error;

  TlsInfo({
    required this.host,
    required this.port,
    this.subject,
    this.issuer,
    this.validFrom,
    this.validTo,
    this.daysRemaining,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'subject': subject,
        'issuer': issuer,
        'valid_from': validFrom?.toIso8601String(),
        'valid_to': validTo?.toIso8601String(),
        'days_remaining': daysRemaining,
        'error': error,
      };
}

// =============================================================================
// ثغرة
// =============================================================================
class CveMatch {
  final String id;
  final String name;
  final Severity severity;
  final double cvss;
  final String product;
  final String description;
  final String matchedOn;

  CveMatch({
    required this.id,
    required this.name,
    required this.severity,
    required this.cvss,
    required this.product,
    required this.description,
    required this.matchedOn,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'severity': severity.name,
        'cvss': cvss,
        'product': product,
        'description': description,
        'matched_on': matchedOn,
      };
}

// =============================================================================
// الهدف الرئيسي
// =============================================================================
class Target {
  final String id;
  final String host;
  ScanType scanType;
  TargetStatus status;
  double progress;
  String? error;

  List<Subdomain> subdomains;
  List<PortResult> ports;
  List<HttpInfo> http;
  List<TlsInfo> tls;
  List<CveMatch> cves;

  DateTime createdAt;
  DateTime? startedAt;
  DateTime? finishedAt;

  Duration? scheduleInterval;

  Target({
    required this.id,
    required this.host,
    required this.scanType,
    this.status = TargetStatus.idle,
    this.progress = 0,
    this.error,
    List<Subdomain>? subdomains,
    List<PortResult>? ports,
    List<HttpInfo>? http,
    List<TlsInfo>? tls,
    List<CveMatch>? cves,
    DateTime? createdAt,
    this.startedAt,
    this.finishedAt,
    this.scheduleInterval,
  })  : subdomains = subdomains ?? [],
        ports = ports ?? [],
        http = http ?? [],
        tls = tls ?? [],
        cves = cves ?? [],
        createdAt = createdAt ?? DateTime.now();

  Duration? get duration {
    if (startedAt == null || finishedAt == null) return null;
    return finishedAt!.difference(startedAt!);
  }

  bool get isScanning => status == TargetStatus.scanning;
  int get openPorts => ports.where((p) => p.isOpen).length;
  int get criticalCves =>
      cves.where((c) => c.severity == Severity.critical).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'host': host,
        'scan_type': scanType.name,
        'status': status.name,
        'progress': progress,
        'error': error,
        'subdomains': subdomains.map((s) => s.toJson()).toList(),
        'ports': ports.map((p) => p.toJson()).toList(),
        'http': http.map((h) => h.toJson()).toList(),
        'tls': tls.map((t) => t.toJson()).toList(),
        'cves': cves.map((c) => c.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'started_at': startedAt?.toIso8601String(),
        'finished_at': finishedAt?.toIso8601String(),
        'schedule_s': scheduleInterval?.inSeconds,
      };
}