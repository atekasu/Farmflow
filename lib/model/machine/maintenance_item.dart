import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/maintenance_rules.dart';

class MaintenanceItem {
  const MaintenanceItem({
    required this.id,
    required this.type,
    required this.name,
    required this.mode,
    this.recommendedIntervalHours,
    this.lastMaintenanceAtHour,
    this.lastInspectionDate,
    this.note,
  });

  final String id; // UUID
  final ComponentType type; // コンポーネントの種類
  final String name; // コンポーネントの名前
  final ComponentMode mode; // コンポーネントのモード（定期）

  final double? recommendedIntervalHours; // 推奨交換間隔（時間）
  final double? lastMaintenanceAtHour; // 最後のメンテナンス時間
  final DateTime? lastInspectionDate; // 最後の検査日
  final String? note; // メモ

  EquipmentStatus evaluateStatus(double currentHour, MaintenanceRules rules) {
    switch (mode) {
      case ComponentMode.intervalBased:
        final total = (recommendedIntervalHours ?? 0).toDouble();
        if (total <= 0) return EquipmentStatus.good; // 安全側
        final used = (currentHour - (lastMaintenanceAtHour ?? 0)).toDouble();
        final remaining = (total - used).clamp(0, total);
        final ratio = (remaining / total).clamp(0.0, 1.0);

        if (ratio < rules.criticalThreshold) {
          return EquipmentStatus.critical; // 交換
        } else if (ratio < rules.yellowThreshold) {
          return EquipmentStatus.warning; // そろそろ
        } else {
          return EquipmentStatus.good; // 良好
        }

      case ComponentMode.inspectionOnly:
        final last = lastInspectionDate;
        if (last == null) return EquipmentStatus.warning; // 未点検は少なくともyellow
        final days = DateTime.now().difference(last).inDays;
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
