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

/// トラクターの詳細情報を表示する画面
///
/// 主な機能:
/// - メンテナンス項目の状態表示
/// - 警告・危険な項目のハイライト表示
/// - 使用開始時の点検実施
/// - メンテナンス項目の長押しで交換記録
///
/// 設計の特徴:
/// - ConsumerWidgetを使用し、Riverpodから最新データを常に取得
/// - machineIdを受け取り、画面内で最新のMachineオブジェクトを検索することで、
///   状態の同期問題を回避（オブジェクトではなくIDを渡す設計パターン）
class MachineDetailScreen extends ConsumerWidget {
  /// 表示対象のトラクターID
  final String machineId;

  const MachineDetailScreen({super.key, required this.machineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpodから最新のトラクター一覧を取得
    // ref.watchを使うことで、データが更新されたら自動的に再ビルドされる
    final machines = ref.watch(machineListProvider);

    // IDで該当のトラクターを検索
    // 重要: オブジェクトをそのまま渡すのではなくIDで検索することで、
    // 他の画面やプロバイダーでトラクターが更新された場合でも、
    // この画面では常に最新の状態を表示できる
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
          // 前回の点検で警告・危険な項目があれば件数を表示
          // ユーザーに注意を促すためのUI
          if (machine.lastPreCheck != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  '要点検 ${machine.lastPreCheck!.result.values.where((s) => s == CheckStatus.warning || s == CheckStatus.critical).length}件',
                ),
              ),
            ),
          // 使用開始ボタン（点検画面へ遷移）
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () async {
                // 点検画面へ遷移し、点検結果(PreCheckRecord)を受け取る
                // Navigator.pushの型パラメータで戻り値の型を指定
                final record = await Navigator.push<PreCheckRecord>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PreWorkInspectionScreen(machine: machine),
                  ),
                );

                // ユーザーが点検をキャンセルした場合はnullが返る
                if (record != null) {
                  // Riverpodのnotifierを通じて点検記録を保存
                  // read()を使うことで、一時的にプロバイダーの値を読み取る
                  await ref
                      .read(machineListProvider.notifier)
                      .savePreCheckRecord(record);

                  // 保存成功をユーザーに通知
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

  /// 警告がある場合のみ区切り線を表示する
  ///
  /// UIの視覚的な区切りとして、警告セクションとメンテナンス項目を分離する。
  /// 警告がない場合は不要な余白を作らないためSizedBox.shrinkを返す。
  Widget _buildDividerIfNeeded(Machine machine) {
    // メンテナンス項目の中に警告や危険状態のものがあるかチェック
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

  /// セクションの見出しを作成する
  ///
  /// 画面内の各セクション（警告、メンテナンス概要など）の
  /// 視覚的な区切りとタイトル表示を統一するためのヘルパー。
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

  /// メンテナンス項目のリストを構築
  ///
  /// 各項目は長押しで交換記録ができる。
  /// この機能により、ユーザーは別画面に遷移せずに
  /// 簡単にメンテナンス作業を記録できる。
  Widget _buildMaintenanceList({
    required BuildContext context,
    required WidgetRef ref,
    required Machine machine,
  }) {
    final items = machine.maintenanceItems;

    /// メンテナンス項目を長押しした時の交換記録処理
    ///
    /// UX設計の意図:
    /// - 誤操作を防ぐため、確認ダイアログを表示
    /// - 点検のみの項目（intervalBased以外）は交換記録できないよう制限
    /// - 現在のアワー値を表示し、記録内容をユーザーが確認できる
    ///
    /// データフロー:
    /// 1. ユーザーが長押し
    /// 2. 確認ダイアログ表示
    /// 3. OKならNotifierのrecordExchangeを呼び出し
    /// 4. Notifier -> Repository -> ドメインロジックと処理が流れる
    Future<void> handleLongPressExchange(MaintenanceItem item) async {
      // intervalBased（定期交換部品）以外は交換記録の対象外
      // 点検のみの項目などは交換という概念がないため
      if (item.mode != ComponentMode.intervalBased) return;

      // 確認ダイアログを表示し、ユーザーの意思を確認
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

      // キャンセルされた場合は何もしない
      if (confirmed != true) return;

      // Riverpodのnotifierを通じて交換記録を実行
      // データの流れ: Notifier -> Repository -> ドメインロジック（Machine拡張メソッド）
      await ref
          .read(machineListProvider.notifier)
          .recordExchange(machineId: machine.id, itemId: item.id);

      // 成功をユーザーに通知
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${item.name} を交換済みにしました')));
    }

    // メンテナンス項目のリストを構築
    return ListView.separated(
      // shrinkWrap: 親のスクロールビュー内で使用するため有効化
      shrinkWrap: true,
      // physics: 親のスクロールに任せるため、このListView自体のスクロールは無効化
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      // 各項目の間に8pxの余白を追加
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          // 長押しで交換記録ダイアログを表示
          // タップとは異なる操作にすることで、誤操作を防ぐ
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
