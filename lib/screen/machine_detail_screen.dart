import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:farmflow/application/machine_list_provider.dart';
import 'package:farmflow/model/machine.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/maintenance_item.dart';
import 'package:farmflow/model/machine/maintenance_rules.dart';
import 'package:farmflow/model/precheck_item.dart';
import 'package:farmflow/model/precheckrecord.dart';
import 'package:farmflow/screen/pre_check_screen.dart';
import 'package:farmflow/widget/maintenance_item_card.dart';
import 'package:farmflow/widget/warning_section.dart';

///
///
class MachineDetailScreen extends ConsumerWidget {
  final String machineId;

  const MachineDetailScreen({super.key, required this.machineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machines = ref.watch(machineListProvider);

    final machine = machines.firstWhere(
      (m) => m.id == machineId,
      orElse: () => throw Exception('Machine not found: $machineId'),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
        title: Text(
          machine.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (machine.lastPreCheck != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  '要点検 ${machine.lastPreCheck!.result.values.where((s) => s == CheckStatus.warning || s == CheckStatus.critical).length}件',
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () async {
                final record = await Navigator.push<PreCheckRecord>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PreWorkInspectionScreen(machine: machine),
                  ),
                );

                if (record != null) {
                  await ref
                      .read(machineListProvider.notifier)
                      .savePreCheckRecord(record);

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('点検結果を保存しました')));
                }
              },
              label: const Text(
                '使用開始',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              icon: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            WarningSection(machine: machine),
            const Padding(padding: EdgeInsets.all(16.0)),

            _buildDividerIfNeeded(machine),

            _buildSectionHeader('メンテナンス概要'),

            _buildMaintenanceList(context: context, ref: ref, machine: machine),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // ─────────────────────────────────────────

  ///
  Widget _buildDividerIfNeeded(Machine machine) {
    final hasWarnings = machine.maintenanceItems.any((item) {
      final status = item.evaluateStatus(
        machine.totalHours,
        const MaintenanceRules(),
      );
      return status != EquipmentStatus.good;
    });

    return hasWarnings
        ? const Divider(height: 1, color: Colors.grey)
        : const SizedBox.shrink();
  }

  // ─────────────────────────────────────────
  // ─────────────────────────────────────────

  ///
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // ─────────────────────────────────────────

  ///
  Widget _buildMaintenanceList({
    required BuildContext context,
    required WidgetRef ref,
    required Machine machine,
  }) {
    final items = machine.maintenanceItems;

    ///
    ///
    Future<void> handleLongPressExchange(MaintenanceItem item) async {
      if (item.mode != ComponentMode.intervalBased) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text('${item.name} の交換を記録'),
              content: Text(
                '現在のアワー値 ${machine.totalHours} h で\n'
                'この項目を「交換済み」として記録しますか？',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('記録する'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;
      try {
        await ref
            .read(machineListProvider.notifier)
            .recordExchange(machineId: machine.id, itemId: item.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item.name}を交換しました。',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '交換の記録に失敗しました: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onLongPress: () => handleLongPressExchange(item),
          child: MaintenanceItemCard(
            item: item,
            totalHours: machine.totalHours,
          ),
        );
      },
    );
  }
}
