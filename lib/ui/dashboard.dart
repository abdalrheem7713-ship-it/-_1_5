// =============================================================================
// نَذْر - الواجهة الرئيسية (Dashboard)
// =============================================================================
import 'package:flutter/material.dart';

import '../core/strings_ar.dart';
import '../core/theme.dart';
import '../core/whitelist.dart';
import '../state/recon_controller.dart';
import 'settings_tab.dart';
import 'targets_tab.dart';

class Dashboard extends StatefulWidget {
  final ReconController controller;
  final Whitelist whitelist;
  final VoidCallback? onWipeKeys;

  const Dashboard({
    super.key,
    required this.controller,
    required this.whitelist,
    this.onWipeKeys,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final ctrl = widget.controller;
          return Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ctrl.isScanning
                          ? AppTheme.warning
                          : AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    S.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ctrl.isScanning
                            ? AppTheme.warning.withOpacity(0.15)
                            : AppTheme.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ctrl.isScanning
                              ? AppTheme.warning
                              : AppTheme.success,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ctrl.isScanning
                                ? Icons.radar
                                : Icons.check_circle,
                            size: 12,
                            color: ctrl.isScanning
                                ? AppTheme.warning
                                : AppTheme.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ctrl.isScanning ? 'يفحص' : 'جاهز',
                            style: TextStyle(
                              fontSize: 10,
                              color: ctrl.isScanning
                                  ? AppTheme.warning
                                  : AppTheme.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              bottom: TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.gps_fixed, size: 18),
                    text: S.tabTargets,
                  ),
                  Tab(
                    icon: Icon(Icons.receipt_long, size: 18),
                    text: S.tabLog,
                  ),
                  Tab(
                    icon: Icon(Icons.settings, size: 18),
                    text: S.tabSettings,
                  ),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabs,
              children: [
                TargetsTab(controller: ctrl, whitelist: widget.whitelist),
                _LogTab(controller: ctrl),
                SettingsTab(
                  controller: ctrl,
                  whitelist: widget.whitelist,
                  onWipeKeys: widget.onWipeKeys,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// تبويب السجل
// =============================================================================
class _LogTab extends StatelessWidget {
  final ReconController controller;
  const _LogTab({required this.controller});

  Color _colorFor(String line) {
    if (line.contains('⛔') || line.contains('✗') || line.contains('⚠')) {
      return AppTheme.danger;
    }
    if (line.contains('✓') || line.contains('اكتمل')) {
      return AppTheme.success;
    }
    if (line.contains('🔍') || line.contains('↳')) {
      return AppTheme.primaryLight;
    }
    return AppTheme.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    if (controller.logs.isEmpty) {
      return const Center(
        child: Text(
          S.logEmpty,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: controller.logs.length,
            itemBuilder: (context, i) {
              final line = controller.logs[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: _colorFor(line),
                    height: 1.4,
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          color: AppTheme.surface,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text(S.clearLogs),
                  onPressed: controller.clearLogs,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}