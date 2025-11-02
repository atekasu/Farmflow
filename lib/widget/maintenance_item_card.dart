import 'package:flutter/material.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
// Machine は今このファイル内で直接は使っていないので削除してOK
// import '../model/machine.dart';

import '../model/machine/maintenance_item.dart';
import '../model/machine/maintenance_rules.dart';
import '../model/machine/component_type_extension.dart';

/// メンテナンス項目1個ぶんのカードUI
///
/// - item       : 例えば「エンジンオイル」などの1項目
/// - totalHours : この機体の現在のアワーメーター値
class MaintenanceItemCard extends StatelessWidget {
  final MaintenanceItem item;
  final int totalHours; // 選択中の機体の現在アワー

  const MaintenanceItemCard({
    super.key,
    required this.item,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) {
    // ドメインルール（交換間隔の判定ロジックなど）
    const rules = MaintenanceRules();

    // 現在ステータス (good / warning / critical / unknown)
    final status = item.evaluateStatus(totalHours, rules);

    // 進捗バー用 (0.0〜1.0, 1.0=余裕たっぷり)
    final progress = _calculateProgress();

    // サブタイトル用の表示テキスト
    final subtitle = _buildSubtitle();

    // 進捗バーの色
    final progressColor = _progressColor(progress);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左側のアイコンバッジ (エンジンオイルとかの種類に応じて色/アイコンを変える)
              CircleAvatar(
                radius: 20,
                backgroundColor: item.type.color.withOpacity(0.1),
                child: Icon(item.type.icon, color: item.type.color),
              ),
              const SizedBox(width: 12),

              // 右側の縦レイアウト
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル行（例: "エンジンオイル"）
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.type.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // ステータスチップ (良好/注意/危険など)
                        _buildStatusChip(status),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // 残り時間 or 最終点検日の説明
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    // intervalBased の項目だけ進捗バーを表示
                    if (_hasInterval) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// この項目が時間間隔で管理されるタイプか？
  /// (recommendedIntervalHours があれば true)
  bool get _hasInterval => item.recommendedIntervalHours != null;

  /// 交換インターバルの残り具合を0.0〜1.0で返す
  /// 1.0 = まだ余裕たっぷり, 0.0 = もう交換したい
  double _calculateProgress() {
    if (!_hasInterval) return 1.0;

    final interval = item.recommendedIntervalHours!.toDouble();
    final last = (item.lastMaintenanceAtHour ?? 0).toDouble();
    final used = (totalHours - last).toDouble(); // 交換から何時間使ったか
    final remain = (interval - used).clamp(0, interval); // 残り何時間余裕あるか
    return remain / interval;
  }

  /// サブテキスト（「交換まで残りxxh」or「最終点検日: yyyy-mm-dd」）
  String _buildSubtitle() {
    if (_hasInterval) {
      final interval = item.recommendedIntervalHours!;
      final last = item.lastMaintenanceAtHour ?? 0;
      final used = (totalHours - last);
      final remain = (interval - used).clamp(0, interval);
      return '交換まで残り${remain}h / ${interval}h';
    } else {
      // この項目は「点検のみ」のタイプ (intervalBasedじゃない)
      final date = item.lastInspectionDate;
      if (date != null) {
        final y = date.year.toString().padLeft(4, '0');
        final m = date.month.toString().padLeft(2, '0');
        final d = date.day.toString().padLeft(2, '0');
        return '最終点検日: $y-$m-$d';
      } else {
        return '最終点検日: 未記録';
      }
    }
  }

  /// 進捗バーの色 (残り少ないと赤、そこそこだと黄、余裕なら緑)
  Color _progressColor(double value) {
    if (value < 0.2) return Colors.red;
    if (value < 0.5) return Colors.yellow;
    return Colors.green;
  }

  /// 状態チップのUI ("良好" "注意" "危険" など)
  Widget _buildStatusChip(EquipmentStatus status) {
    // EquipmentStatus は item.evaluateStatus(...) の戻り値の型
    // 例: EquipmentStatus.good / warning / critical / unknown
    late final Color bg;
    late final String label;

    switch (status) {
      case EquipmentStatus.good:
        bg = Colors.green.shade100;
        label = '良好';
        break;
      case EquipmentStatus.warning:
        bg = Colors.orange.shade100;
        label = '注意';
        break;
      case EquipmentStatus.critical:
        bg = Colors.red.shade100;
        label = '危険';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
