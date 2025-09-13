import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/maintenance_rules.dart';

class MaintenanceItem {
  const MaintenanceItem({
    required this.id,
    required this.type,
    required this.name,
    required this.mode,
    this.recommendedIntervalHours, // 単位: 時間[h]
    this.lastMaintenanceAtHour, // 単位: 通算時間[h]
    this.lastInspectionDate,
    this.note,
  }) : assert(
         // 開発中に前提破りを早期検知：intervalBased なら推奨間隔は 0 より大
         mode != ComponentMode.intervalBased ||
             (recommendedIntervalHours ?? 0) > 0,
         'intervalBased なのに recommendedIntervalHours が未設定/0',
       ),
       assert(
         // 過去の交換時刻は負でない
         (lastMaintenanceAtHour ?? 0) >= 0,
         'lastMaintenanceAtHour は負にできません',
       );

  final String id; // UUID
  final ComponentType type; // コンポーネント種類
  final String name; // 名称
  final ComponentMode mode; // intervalBased / inspectionOnly

  final int? recommendedIntervalHours; // 推奨交換間隔[h]
  final int? lastMaintenanceAtHour; // 最終交換時点の通算時間[h]
  final DateTime? lastInspectionDate; // 最後の点検日
  final String? note; // 備考

  /// 状態判定（テスト容易化のため now を注入できる）
  EquipmentStatus evaluateStatus(
    int currentHour,
    MaintenanceRules rules, {
    DateTime? now,
  }) {
    final _now = now ?? DateTime.now();

    switch (mode) {
      case ComponentMode.intervalBased:
        {
          final int total = recommendedIntervalHours ?? 0;
          if (total <= 0) {
            // 安全側に倒す。ポリシー次第で critical にしてもよい
            return EquipmentStatus.good;
          }

          final int used = currentHour - (lastMaintenanceAtHour ?? 0);
          // clamp は num を返すので int にキャストする
          final int remaining = (total - used).clamp(0, total);

          // 比率は double で評価（/ は double を返す）
          final double remainingRatio = (remaining / total).clamp(0.0, 1.0);

          if (remainingRatio < rules.criticalThreshold) {
            return EquipmentStatus.critical;
          } else if (remainingRatio < rules.yellowThreshold) {
            return EquipmentStatus.warning;
          } else {
            return EquipmentStatus.good;
          }
        }

      case ComponentMode.inspectionOnly:
        {
          final last = lastInspectionDate;
          if (last == null) {
            // 未点検は最低でも yellow
            return EquipmentStatus.warning;
          }
          final int days = _daysSince(last, _now);
          if (days >= rules.inspectionMaxDaysCritical) {
            return EquipmentStatus.critical;
          } else if (days >= rules.inspectionMaxDaysWarning) {
            return EquipmentStatus.warning;
          } else {
            return EquipmentStatus.good;
          }
        }
    }
  }

  // ---- ヘルパ ----
  int _daysSince(DateTime from, DateTime to) => to.difference(from).inDays;

  /// 残り時間[h]を返す（UI等から再利用したい時用）
  int remainingHours(int currentHour) {
    final int total = recommendedIntervalHours ?? 0;
    if (total <= 0) return 0;
    final int used = currentHour - (lastMaintenanceAtHour ?? 0);
    return (total - used).clamp(0, total);
  }

  MaintenanceItem copyWith({
    String? id,
    ComponentType? type,
    String? name,
    ComponentMode? mode,
    int? recommendedIntervalHours,
    int? lastMaintenanceAtHour,
    DateTime? lastInspectionDate,
    String? note,
  }) {
    return MaintenanceItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      recommendedIntervalHours:
          recommendedIntervalHours ?? this.recommendedIntervalHours,
      lastMaintenanceAtHour:
          lastMaintenanceAtHour ?? this.lastMaintenanceAtHour,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      note: note ?? this.note,
    );
  }
}
