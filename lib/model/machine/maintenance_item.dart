import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/equipment.dart';

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

  final double? recommendedIntervalHours;
  final double? lastMaintenanceAtHour; // 最後のメンテナンス時間
  final DateTime? lastInspectionDate; // 最後の検査日
  final String? note; // メモ

  EquipmentStatus evaluateStatus(double currentHours, MaintenanceRules rules) {
    if (mode == ComponentMode.intervalBased) {
      if (recommendedIntervalHours == null || lastMaintenanceAtHour == null) {
        return EquipmentStatus.warning;
      }
      final used = currentHours - (lastMaintenanceAtHour ?? 0);
      final remain = 1 - (used / recommendedIntervalHours!);
      if (remain <= 0) return EquipmentStatus.critical;
      if (remain <= rules.yellowThreshold) return EquipmentStatus.warning;
      return EquipmentStatus.good;
    } else {
      if (lastInspectionDate == null) return EquipmentStatus.warning;
      final days = DateTime.now().difference(lastInspectionDate!).inDays;
      if (days > rules.inspectionMaxDaysCritical) {
        return EquipmentStatus.critical;
      }
      if (days > rules.inspectionMaxDaysWarning) {
        return EquipmentStatus.warning;
      }
      return EquipmentStatus.good;
    }
  }
}
