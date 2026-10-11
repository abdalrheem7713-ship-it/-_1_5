// =============================================================================
// نَذْر - تبويب الأهداف
// =============================================================================
import 'package:flutter/material.dart';

import '../core/strings_ar.dart';
import '../core/theme.dart';
import '../core/whitelist.dart';
import '../recon/models.dart';
import '../state/recon_controller.dart';

class TargetsTab extends StatelessWidget {
  final ReconController controller;
  final Whitelist whitelist;

  const TargetsTab({
    super.key,
    required this.controller,
    required this.whitelist,
  });

  Color _statusColor(TargetStatus s) {
    switch (s) {
      case TargetStatus.up:
        return AppTheme.success;
      case TargetStatus.down:
        return AppTheme.warning;
      case TargetStatus.error:
        return AppTheme.danger;
      case TargetStatus.blocked:
        return AppTheme.purple;
      case TargetStatus.scanning:
        return AppTheme.primaryLight;
      case TargetStatus.idle:
        return AppTheme.textMuted;
    }
  }

  String _statusText(TargetStatus s) {
    switch (s) {
      case TargetStatus.up:
        return S.statusUp;
      case TargetStatus.down:
        return S.statusDown;
      case TargetStatus.error:
        return S.statusError;
      case TargetStatus.blocked:
        return S.statusBlocked;
      case TargetStatus.scanning:
        return S.statusScanning;
      case TargetStatus.idle:
        return S.statusIdle;
    }
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final hostC = TextEditingController();
    ScanType type = ScanType.full;
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text(S.addTarget),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: hostC,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: S.hostLabel,
                    hintText: 'example.com',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<ScanType>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: S.scanType,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ScanType.full,
                      child: Text(S.scanFull),
                    ),
                    DropdownMenuItem(
                      value: ScanType.subdomain,
                      child: Text(S.scanSubdomain),
                    ),
                    DropdownMenuItem(
                      value: ScanType.dns,
                      child: Text(S.scanDns),
                    ),
                    DropdownMenuItem(
                      value: ScanType.port,
                      child: Text(S.scanPort),
                    ),
                    DropdownMenuItem(
                      value: ScanType.http,
                      child: Text(S.scanHttp),
                    ),
                    DropdownMenuItem(
                      value: ScanType.tls,
                      child: Text(S.scanTls),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setSt(() => type = v);
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    whitelist.isEmpty
                        ? '⚠ القائمة البيضاء فارغة — أضف نطاقًا من الإعدادات أولًا'
                        : 'القائمة البيضاء: ${whitelist.domains.length + whitelist.cidrs.length} مدخل',
                    style: TextStyle(
                      fontSize: 11,
                      color: whitelist.isEmpty
                          ? AppTheme.warning
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(S.cancel),
            ),
            TextButton(
              onPressed: () {
                final h = hostC.text.trim();
                if (h.isEmpty) {
                  setSt(() => error = 'أدخل اسم النطاق');
                  return;
                }
                if (!whitelist.allows(h)) {
                  setSt(() =>
                      error = 'النطاق غير موجود في القائمة البيضاء');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text(
                S.add,
                style: TextStyle(color: AppTheme.success),
              ),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      controller.addTarget(hostC.text.trim(), type);
    }
  }

  Widget _buildTargetCard(BuildContext context, Target t) {
    final color = _statusColor(t.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconForStatus(t.status),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.host,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_scanTypeName(t.scanType)} • ${_statusText(t.status)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (t.status != TargetStatus.scanning)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                    onPressed: () => controller.removeTarget(t.id),
                  ),
              ],
            ),
            if (t.status == TargetStatus.scanning) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: t.progress,
                  backgroundColor: AppTheme.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryLight),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(t.progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
            if (t.status != TargetStatus.idle &&
                t.status != TargetStatus.scanning) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (t.subdomains.isNotEmpty)
                    _StatChip(
                      icon: Icons.dns_outlined,
                      label: '${t.subdomains.length} نطاق فرعي',
                      color: AppTheme.primaryLight,
                    ),
                  if (t.ports.isNotEmpty)
                    _StatChip(
                      icon: Icons.settings_ethernet,
                      label: '${t.openPorts} منفذ مفتوح',
                      color: AppTheme.cyan,
                    ),
                  if (t.http.isNotEmpty)
                    _StatChip(
                      icon: Icons.http,
                      label: '${t.http.length} خدمة HTTP',
                      color: AppTheme.success,
                    ),
                  if (t.tls.isNotEmpty)
                    _StatChip(
                      icon: Icons.lock_outline,
                      label: '${t.tls.length} شهادة',
                      color: AppTheme.purple,
                    ),
                  if (t.cves.isNotEmpty)
                    _StatChip(
                      icon: Icons.warning_amber,
                      label: '${t.cves.length} ثغرة',
                      color: t.criticalCves > 0
                          ? AppTheme.danger
                          : AppTheme.warning,
                    ),
                ],
              ),
            ],
            if (t.error != null) ...[
              const SizedBox(height: 10),
              Text(
                '⚠ ${t.error}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.danger,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.status == TargetStatus.scanning
                          ? AppTheme.danger
                          : AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: Icon(
                      t.status == TargetStatus.scanning
                          ? Icons.stop
                          : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(
                      t.status == TargetStatus.scanning ? S.stop : S.run,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: t.status == TargetStatus.scanning
                        ? controller.stopScan
                        : (controller.isScanning
                            ? null
                            : () => controller.startScan(t)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForStatus(TargetStatus s) {
    switch (s) {
      case TargetStatus.up:
        return Icons.check_circle;
      case TargetStatus.down:
        return Icons.remove_circle;
      case TargetStatus.error:
        return Icons.error_outline;
      case TargetStatus.blocked:
        return Icons.block;
      case TargetStatus.scanning:
        return Icons.radar;
      case TargetStatus.idle:
        return Icons.circle_outlined;
    }
  }

  String _scanTypeName(ScanType t) {
    switch (t) {
      case ScanType.full:
        return S.scanFull;
      case ScanType.subdomain:
        return S.scanSubdomain;
      case ScanType.dns:
        return S.scanDns;
      case ScanType.port:
        return S.scanPort;
      case ScanType.http:
        return S.scanHttp;
      case ScanType.tls:
        return S.scanTls;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller.targets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(
                  Icons.gps_off,
                  size: 36,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                S.noTargetsYet,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text(S.addTarget),
                onPressed: () => _showAddDialog(context),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          itemCount: controller.targets.length,
          itemBuilder: (context, i) =>
              _buildTargetCard(context, controller.targets[i]),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: FloatingActionButton.extended(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add),
            label: const Text(S.addTarget),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}