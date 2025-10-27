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

  final String id; // UUIDなど
  final String name; // 機械の名前
  final String modelName; // 機械のモデル名
  final int totalHours; // アワーメーターの値
  final List<MaintenanceItem> maintenanceItems; // メンテナンス項目のリスト
  final PreCheckRecord? lastPreCheck; // 最新の使用前点検記録

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
}

///=============================================
///メンテナンス項目の置換機能
///=============================================
///
///Machineの拡張メソッド
extension MachineOps on Machine {
  ///maintenanceItemsの中から、指定されたitem を置換する
  ///
  ///[updated]: 更新後のMaintenanceItem
  ///
  ///動作:
  ///-idが一致する項目を探す
  ///-見つかったら置換
  ///-見つからなかったらmachineをそのまま返す(イミュータブル)
  ///
  Machine replaceMaintenanceItem(MaintenanceItem updated) {
    final index = maintenanceItems.indexWhere((item) => item.id == updated.id);

    // 見つからない場合は何もしない
    if (index < 0) return this;

    //新しいリストを作成(イミュータブル)
    final newItems = List<MaintenanceItem>.from(maintenanceItems);
    newItems[index] = updated;

    //新しいMachneを返す
    return copyWith(maintenanceItems: newItems);
  }
}
