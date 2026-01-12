import 'package:farmflow/model/machine/maintenance_item.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/maintenance_rules.dart';
import 'package:farmflow/model/precheckrecord.dart';

class Machine {
  Machine({
    required this.id,
    required this.name,
    required this.modelName,
    required this.totalHours,
    required this.maintenanceItems,
    this.lastPreCheck,
  });

  final String id;
  final String name;
  final String modelName;
  final int totalHours;
  final List<MaintenanceItem> maintenanceItems;
  final PreCheckRecord? lastPreCheck;

  factory Machine.fromJson(Map<String, dynamic> json) {
    // Support both backend snake_case and older camelCase payloads.
    final id = (json['id'] ?? json['machineId']) as String;
    final name = (json['name'] ?? json['machineName']) as String;

    final modelName = (json['model_name'] ?? json['modelName']) as String;
    final totalHours = (json['total_hours'] ?? json['totalHours']) as int;

    final itemsRaw = (json['maintenance_items'] ??
            json['maintenanceItems'] ??
            json['maintennace_item'])
        as List<dynamic>?;

    final maintenanceItems = (itemsRaw ?? const <dynamic>[])
        .map((e) => MaintenanceItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final lastPreCheckRaw =
        (json['last_precheck'] ?? json['lastPreCheck']) as Map<String, dynamic>?;

    return Machine(
      id: id,
      name: name,
      modelName: modelName,
      totalHours: totalHours,
      maintenanceItems: maintenanceItems,
      lastPreCheck:
          lastPreCheckRaw != null ? PreCheckRecord.fromJson(lastPreCheckRaw) : null,
    );
  }

  EquipmentStatus overallStatus(MaintenanceRules rules) {
    var worst = EquipmentStatus.good;
    for (final c in maintenanceItems) {
      final s = c.evaluateStatus(totalHours, rules);
      if (s == EquipmentStatus.critical) {
        return EquipmentStatus.critical;
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
    PreCheckRecord? lastPreCheck,
  }) {
    return Machine(
      id: id ?? this.id,
      name: name ?? this.name,
      modelName: modelName ?? this.modelName,
      totalHours: totalHours ?? this.totalHours,
      maintenanceItems: maintenanceItems ?? this.maintenanceItems,
      lastPreCheck: lastPreCheck ?? this.lastPreCheck,
    );
  }

  /// Replace (by id) a single maintenance item and return a new Machine instance.
  Machine replaceMaintenanceItem(MaintenanceItem updatedItem) {
    final next = maintenanceItems
        .map((it) => it.id == updatedItem.id ? updatedItem : it)
        .toList();
    return copyWith(maintenanceItems: next);
  }
}

extension MachineOps on Machine {}
