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
  final double totalHours; // アワーメーターの値
  final List<MaintenanceItem> maintenanceItems; // メンテナンス項目のリスト

  factory Machine.createTractor({
    required String id,
    required String name,
    required String modelName,
    required double totalHours,
  }) {
    return Machine(
      id: id,
      name: name,
      modelName: modelName,
      totalHours: totalHours,
      maintenanceItems: [
        MaintenanceItem(
          id: '$id-engine-oil',
          type: ComponentType.engineOil,
          name: 'エンジンオイル',
          mode: ComponentMode.intervalBased,
          recommendedIntervalHours: 200,
          lastMaintenanceAtHour: totalHours - 80,
        ),
        MaintenanceItem(
          id: '$id-coolant',
          type: ComponentType.coolant,
          name: 'クーラント',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: DateTime.now().subtract(const Duration(days: 30)),
        ),
        MaintenanceItem(
          id: '$id-grease',
          type: ComponentType.grease,
          name: 'グリス',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: DateTime.now().subtract(const Duration(days: 10)),
        ),
        MaintenanceItem(
          id: '$id-air-filter',
          type: ComponentType.airFilter,
          name: 'エアフィルタ',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: DateTime.now().subtract(const Duration(days: 25)),
        ),
        MaintenanceItem(
          id: '$id-hydraulic',
          type: ComponentType.hydraulicOil,
          name: '油圧オイル',
          mode: ComponentMode.intervalBased,
          recommendedIntervalHours: 400,
          lastMaintenanceAtHour: totalHours - 120,
        ),
        MaintenanceItem(
          id: '$id-fuel-filter',
          type: ComponentType.fuelFilter,
          name: '燃料フィルタ',
          mode: ComponentMode.intervalBased,
          recommendedIntervalHours: 400,
          lastMaintenanceAtHour: totalHours - 120,
        ),
        MaintenanceItem(
          id: '$id-transmission-oil',
          type: ComponentType.transmissionOil,
          name: 'トランスミッションオイル',
          mode: ComponentMode.intervalBased,
          recommendedIntervalHours: 600,
          lastMaintenanceAtHour: totalHours - 200,
        ),
        MaintenanceItem(
          id: '$id-tire-pressure',
          type: ComponentType.tirePressure,
          name: 'タイヤ空気圧',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: DateTime.now().subtract(const Duration(days: 15)),
        ),
        MaintenanceItem(
          id: '$id-brake-wire',
          type: ComponentType.brakeWire,
          name: 'ブレーキワイヤー',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: DateTime.now().subtract(const Duration(days: 45)),
        ),
      ],
    );
  }

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
}
