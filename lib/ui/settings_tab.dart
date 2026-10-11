// =============================================================================
// نَذْر - تبويب الإعدادات (القائمة البيضاء + السجل الموقّع + منطقة الخطر)
// =============================================================================
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/strings_ar.dart';
import '../core/theme.dart';
import '../core/whitelist.dart';
import '../state/recon_controller.dart';

class SettingsTab extends StatefulWidget {
  final ReconController controller;
  final Whitelist whitelist;
  final VoidCallback? onWipeKeys;

  const SettingsTab({
    super.key,
    required this.controller,
    required this.whitelist,
    this.onWipeKeys,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  static const _whitelistKey = 'nazr_whitelist_v1';

  Future<void> _saveWhitelist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _whitelistKey,
      jsonEncode(widget.whitelist.toJson()),
    );
  }

  Future<void> _addDomain() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.addDomain),
        content: TextField(
          controller: c,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(hintText: S.domainHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(S.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              S.add,
              style: TextStyle(color: AppTheme.success),
            ),
          ),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      widget.whitelist.addDomain(c.text.trim());
      await _saveWhitelist();
      setState(() {});
    }
  }

  Future<void> _addCidr() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.addCidr),
        content: TextField(
          controller: c,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(hintText: S.cidrHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(S.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              S.add,
              style: TextStyle(color: AppTheme.success),
            ),
          ),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      widget.whitelist.addCidr(c.text.trim());
      await _saveWhitelist();
      setState(() {});
    }
  }

  Future<void> _exportJson() async {
    try {
      final jsonStr = const JsonEncoder.withIndent('  ')
          .convert(widget.controller.exportJson());
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File('${dir.path}/nazr_report_$ts.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'نَذْر - تقرير الفحص',
      );
      widget.controller.log('✓ صُدّر التقرير: ${file.path}');
    } catch (e) {
      widget.controller.log('✗ فشل التصدير: $e');
    }
  }

  Future<void> _exportAudit() async {
    try {
      final jsonStr = const JsonEncoder.withIndent('  ')
          .convert(widget.controller.audit.exportJson());
      await Clipboard.setData(ClipboardData(text: jsonStr));
      widget.controller.log('✓ نُسخ السجل الموقّع للحافظة');
    } catch (e) {
      widget.controller.log('✗ فشل نسخ السجل: $e');
    }
  }

  Future<void> _confirmWipe() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          S.wipeKeys,
          style: TextStyle(color: AppTheme.danger),
        ),
        content: const Text(S.wipeKeysConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(S.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              S.delete,
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      widget.onWipeKeys?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final audit = widget.controller.audit;
    final integrity = audit.verify();
    final integrityOk = integrity == -1;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sectionCard(
          icon: Icons.verified_user,
          iconColor: AppTheme.success,
          title: S.whitelistTitle,
          subtitle: S.whitelistDesc,
          children: [
            if (widget.whitelist.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  S.whitelistEmpty,
                  style: TextStyle(color: AppTheme.warning, fontSize: 12),
                ),
              ),
            ...widget.whitelist.domains.map((d) => _listItem(
                  icon: Icons.language,
                  iconColor: AppTheme.success,
                  text: d,
                  onDelete: () async {
                    widget.whitelist.removeDomain(d);
                    await _saveWhitelist();
                    setState(() {});
                  },
                )),
            ...widget.whitelist.cidrs.map((c) => _listItem(
                  icon: Icons.hub,
                  iconColor: AppTheme.primaryLight,
                  text: c,
                  onDelete: () async {
                    widget.whitelist.removeCidr(c);
                    await _saveWhitelist();
                    setState(() {});
                  },
                )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(S.addDomain),
                    onPressed: _addDomain,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(S.addCidr),
                    onPressed: _addCidr,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _sectionCard(
          icon: Icons.receipt_long,
          iconColor: AppTheme.primaryLight,
          title: S.auditTitle,
          subtitle: null,
          children: [
            Row(
              children: [
                Expanded(
                  child: _infoRow(
                    S.auditEntries,
                    '${audit.length}',
                    AppTheme.textPrimary,
                  ),
                ),
                Expanded(
                  child: _infoRow(
                    S.auditIntegrity,
                    integrityOk ? S.auditValid : '$S.auditBroken $integrity',
                    integrityOk ? AppTheme.success : AppTheme.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Text(
                    '${S.auditLastHash}: ',
                    style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                  Expanded(
                    child: Text(
                      audit.lastHash.length > 16
                          ? '${audit.lastHash.substring(0, 16)}...'
                          : audit.lastHash,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text(S.exportAudit),
                onPressed: _exportAudit,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _sectionCard(
          icon: Icons.share,
          iconColor: AppTheme.cyan,
          title: S.exportJson,
          subtitle: 'حفظ التقرير الكامل ومشاركته',
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.file_download, size: 18),
                label: const Text(S.exportJson),
                onPressed: _exportJson,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.danger.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber, color: AppTheme.danger, size: 20),
                  SizedBox(width: 8),
                  Text(
                    S.dangerZone,
                    style: TextStyle(
                      color: AppTheme.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                  ),
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text(S.wipeKeys),
                  onPressed: _confirmWipe,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text(S.clearLogs),
                  onPressed: widget.controller.clearLogs,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'نَذْر ${S.appVersion}',
            style: TextStyle(fontSize: 11, color: AppTheme.textDim),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _listItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppTheme.textPrimary,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}