// =============================================================================
// نَذْر - متحكم الحالة الرئيسي
// =============================================================================
import 'package:flutter/foundation.dart';

import '../core/audit_log.dart';
import '../core/whitelist.dart';
import '../recon/models.dart';
import '../recon/recon_engine.dart';

class ReconController extends ChangeNotifier {
  final Whitelist whitelist;
  final AuditLog audit;
  final ReconEngine engine;

  final List<Target> targets = [];
  final List<String> logs = [];

  bool _disposed = false;
  bool _stopRequested = false;

  Target? _activeTarget;
  Target? get activeTarget => _activeTarget;

  static const int _maxLogs = 500;

  ReconController({
    required this.whitelist,
    required this.audit,
    required this.engine,
  });

  // ---------- السجل ----------
  void _addLog(String msg) {
    if (_disposed) return;
    final t = DateTime.now().toIso8601String().substring(11, 19);
    logs.insert(0, '[$t] $msg');
    if (logs.length > _maxLogs) logs.removeLast();
    _safeNotify();
  }

  void log(String msg) => _addLog(msg);

  void clearLogs() {
    logs.clear();
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ---------- الأهداف ----------
  bool addTarget(String host, ScanType type) {
    final trimmed = host.trim();
    if (trimmed.isEmpty) return false;

    if (!whitelist.allows(trimmed)) {
      _addLog('⛔ محظور: $trimmed غير موجود في القائمة البيضاء');
      audit.append('blocked_target', {'host': trimmed});
      return false;
    }

    final exists = targets.any((t) => t.host == trimmed);
    if (exists) {
      _addLog('⚠ الهدف موجود مسبقًا: $trimmed');
      return false;
    }

    targets.add(Target(
      id: 'T${DateTime.now().microsecondsSinceEpoch}',
      host: trimmed,
      scanType: type,
    ));

    _addLog('✓ أُضيف الهدف: $trimmed');
    audit.append('add_target', {'host': trimmed, 'type': type.name});
    _safeNotify();
    return true;
  }

  void removeTarget(String id) {
    targets.removeWhere((t) => t.id == id);
    audit.append('remove_target', {'id': id});
    _safeNotify();
  }

  // ---------- الفحص ----------
  bool get isScanning => _activeTarget != null;

  Future<void> startScan(Target target) async {
    if (isScanning) {
      _addLog('⚠ يوجد فحص جارٍ بالفعل');
      return;
    }

    if (!whitelist.allows(target.host)) {
      target.status = TargetStatus.blocked;
      target.error = 'النطاق ليس في القائمة البيضاء';
      _addLog('⛔ رفض الفحص: ${target.host}');
      audit.append('blocked_scan', {'host': target.host});
      _safeNotify();
      return;
    }

    _activeTarget = target;
    _stopRequested = false;

    target.status = TargetStatus.scanning;
    target.progress = 0;
    target.error = null;
    target.subdomains.clear();
    target.ports.clear();
    target.http.clear();
    target.tls.clear();
    target.cves.clear();
    target.startedAt = DateTime.now();
    target.finishedAt = null;

    _addLog('🔍 بدء الفحص على ${target.host}');
    audit.append('scan_start', {
      'host': target.host,
      'type': target.scanType.name,
    });
    _safeNotify();

    try {
      await engine.runFullScan(
        host: target.host,
        shouldStop: () => _stopRequested,
        onEvent: (event) => _handleEvent(target, event),
      );

      target.finishedAt = DateTime.now();
      if (target.status == TargetStatus.scanning) {
        target.status = TargetStatus.up;
        target.progress = 1.0;
      }

      _addLog('✓ اكتمل الفحص على ${target.host}');
      audit.append('scan_done', {
        'host': target.host,
        'status': target.status.name,
        'subdomains': target.subdomains.length,
        'ports': target.openPorts,
        'cves': target.cves.length,
      });
    } catch (e) {
      target.status = TargetStatus.error;
      target.error = e.toString();
      _addLog('✗ خطأ في الفحص: $e');
      audit.append('scan_error', {
        'host': target.host,
        'error': e.toString(),
      });
    } finally {
      _activeTarget = null;
      _safeNotify();
    }
  }

  void stopScan() {
    if (!isScanning) return;
    _stopRequested = true;
    _addLog('⏹ طلب إيقاف الفحص...');
    if (_activeTarget != null) {
      _activeTarget!.status = TargetStatus.idle;
    }
    _safeNotify();
  }

  // ---------- معالجة الأحداث ----------
  void _handleEvent(Target target, ReconEvent event) {
    switch (event.type) {
      case ReconEventType.log:
        _addLog('[${target.host}] ${event.message}');
        break;

      case ReconEventType.progress:
        if (event.progress != null) {
          target.progress = event.progress!;
        }
        break;

      case ReconEventType.subdomain:
        final name = event.payload as String? ?? event.message;
        if (!target.subdomains.any((s) => s.name == name)) {
          target.subdomains.add(Subdomain(name: name, isAlive: true));
          _addLog('  ↳ نطاق فرعي: $name');
        }
        break;

      case ReconEventType.port:
        final payload = event.payload as Map?;
        if (payload != null) {
          final result = payload['result'] as PortResult?;
          if (result != null) {
            target.ports.add(result);
            _addLog('  ↳ منفذ: ${result.port} (${result.service})');
          }
        }
        break;

      case ReconEventType.http:
        final info = event.payload as HttpInfo?;
        if (info != null) {
          target.http.add(info);
          _addLog('  ↳ HTTP: ${info.url} → ${info.status}');
        }
        break;

      case ReconEventType.tls:
        final info = event.payload as TlsInfo?;
        if (info != null) {
          target.tls.add(info);
          _addLog('  ↳ TLS: ${info.host} → ${info.daysRemaining} يوم');
        }
        break;

      case ReconEventType.cve:
        final cve = event.payload as CveMatch?;
        if (cve != null) {
          target.cves.add(cve);
          _addLog('  ⚠ ${cve.id}: ${cve.name}');
        }
        break;

      case ReconEventType.tech:
        _addLog('  ↳ تقنية: ${event.message}');
        break;

      case ReconEventType.error:
        _addLog('  ✗ ${event.message}');
        break;

      case ReconEventType.done:
        _addLog('  ✓ ${event.message}');
        break;
    }
    _safeNotify();
  }

  // ---------- التصدير ----------
  Map<String, dynamic> exportJson() => {
        'version': '1.0.0',
        'exported_at': DateTime.now().toIso8601String(),
        'whitelist': whitelist.toJson(),
        'audit': audit.exportJson(),
        'targets': targets.map((t) => t.toJson()).toList(),
      };

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}