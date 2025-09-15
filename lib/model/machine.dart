import 'package:farmflow/model/machine/maintenance_item.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/maintenance_rules.dart';

class Machine {
  Machine({
    required this.id,
    required this.name,
    required this.modelName,
    required this.totalHours,
    required this.maintenanceItems,
  });

  final String id; // UUIDなど
  final String name; // 機械の名前
  final String modelName; // 機械のモデル名
  final int totalHours; // アワーメーターの値
  final List<MaintenanceItem> maintenanceItems; // メンテナンス項目のリスト

  // Factory constructors moved to domain/MachineFactory for separation of concerns.

  /// 個々のメンテ項目の状態から全体の状態を集約する
  EquipmentStatus overallStatus(MaintenanceRules rules) {
    var worst = EquipmentStatus.good;
    for (final c in maintenanceItems) {
      final s = c.evaluateStatus(totalHours, rules);
      if (s == EquipmentStatus.critical) {
        return EquipmentStatus.critical; // 1つでもcriticalなら即critical
      }
      if (s == EquipmentStatus.warning) {
        worst = EquipmentStatus.warning;
      }
    }
    return worst;
  }

  Machine copyWith({
    String? id,
    String? name,
    String? modelName,
    int? totalHours,
    List<MaintenanceItem>? maintenanceItems,
  }) {
    return Machine(
      id: id ?? this.id,
      name: name ?? this.name,
      modelName: modelName ?? this.modelName,
      totalHours: totalHours ?? this.totalHours,
      maintenanceItems: maintenanceItems ?? this.maintenanceItems,
    );
  }
}
