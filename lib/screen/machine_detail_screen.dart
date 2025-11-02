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

class MachineDetailScreen extends ConsumerWidget {
  final String machineId;

  const MachineDetailScreen({super.key, required this.machineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Riverpod から最新の Machine 一覧を読む
    final machines = ref.watch(machineListProvider);

    // 2. この画面で表示したい Machine を ID で取り出す
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
                  // warning / critical の件数をチップで表示
                  '要点検 ${machine.lastPreCheck!.result.values.where((s) => s == CheckStatus.warning || s == CheckStatus.critical).length}件',
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () async {
                // 点検画面へ遷移し、点検結果(PreCheckRecord)を受け取る
                final record = await Navigator.push<PreCheckRecord>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PreWorkInspectionScreen(machine: machine),
                  ),
                );

                if (record != null) {
                  // Riverpod の Notifier に保存を依頼
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
            // 警告セクション
            WarningSection(machine: machine),
            const Padding(padding: EdgeInsets.all(16.0)),

            // 警告があれば区切り線を入れる
            _buildDividerIfNeeded(machine),

            // メンテナンス概要セクションタイトル
            _buildSectionHeader('メンテナンス概要'),

            // メンテナンス項目リスト（長押しで交換記録）
            _buildMaintenanceList(context: context, ref: ref, machine: machine),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 画面内だけで使うヘルパー: 区切り線
  // ─────────────────────────────────────────
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
  // 画面内だけで使うヘルパー: セクション見出し
  // ─────────────────────────────────────────
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
  // メンテナンス項目一覧 + 長押しで交換記録
  // ─────────────────────────────────────────
  Widget _buildMaintenanceList({
    required BuildContext context,
    required WidgetRef ref,
    required Machine machine,
  }) {
    final items = machine.maintenanceItems;
    const rules = MaintenanceRules();

    // 長押しで交換記録する処理
    Future<void> handleLongPressExchange(MaintenanceItem item) async {
      // intervalBased 以外（点検だけの項目など）は交換ボタンを出さない
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

      // Notifier -> Repository -> ドメイン拡張の流れで交換処理が走る
      await ref
          .read(machineListProvider.notifier)
          .recordExchange(machineId: machine.id, itemId: item.id);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${item.name} を交換済みにしました')));
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
