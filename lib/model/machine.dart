import 'package:farmflow/model/maintenance_item.dart';

class Machine {
  Machine({
    required this.id,
    required this.name,
    required this.modelName,
    required this.totalHours,
    required this.components,
  });
  final String id; // UUID
  final String name; // 機械の名前
  final String modelName; // 機械のモデル名
  final double totalHours; // アワーメーターの値（例:
  final List<MaintenanceComponent> componets; // メンテナンス項目のリスト

  EquipmentStatus overallStatus(MaintenanceRules) {
    var status = EquipmentStatus.good;
    for (final c in components) {
      final s = c.evaluteStatus(totalHours, rules);
      if (s == EquipmentStatus.critical) {
        final s = c.evaluateStatus(totalHours, rules);
        if (s == EquipmentStatus.critical) {
          return EquipmentStatus.critical; // 1つでもCriticalなら全体もCritical
        }
        if (s == EquipmentStatus.warning) worst = EquipmentStatus.warning;
      }
      return worst;
    }
  }
}
