import 'package:farmflow/model/machine.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/precheckrecord.dart';
import 'package:farmflow/model/machine/maintenance_item.dart';
import 'package:farmflow/model/precheck_item.dart'; // CheckStatus
import 'package:farmflow/model/machine/component_type_extension.dart';

//machineデータの取得・更新の抽象化
abstract class MachineRepository {
  Future<List<Machine>> fetchAllMachines();
  Future<void> updateMachine(Machine machine);
  Future<void> savePreCheckRecord(PreCheckRecord record);
}

///ダミー実装(後でAPI実装にさしかえ)
class MachineRepositoryImpl implements MachineRepository {
  //初期データを外から注入できるようにする
  MachineRepositoryImpl({required List<Machine> initial})
    : _machines = List.of(initial);

  List<Machine> _machines;

  @override
  // 全件取得(擬似的に遅延を入れる)
  Future<List<Machine>> fetchAllMachines() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.of(_machines);
  }

  @override
  // 更新はIDで特定して上書き
  Future<void> updateMachine(Machine machine) async {
    final index = _machines.indexWhere((m) => m.id == machine.id);
    if (index != -1) {
      _machines[index] = machine;
    } else {
      //新規追加もできるように
      _machines.add(machine);
    }
  }

  @override
  // 使用前点検記録の保存と、該当MachineのlastPreCheck更新
  Future<void> savePreCheckRecord(PreCheckRecord record) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _machines.indexWhere((m) => m.id == record.machineId);
    if (index == -1) return; //該当Machineなし
    final machine = _machines[index];

    // 1) lastPreCheckを更新
    var updatedMachine = machine.copyWith(lastPreCheck: record);

    // 2) PreCheck結果をMaintenanceItemに反映
    final updatedItems = _updateMaintenanceItemsWithPreCheck(
      updatedMachine.maintenanceItems,
      record,
    );

    // 3) 更新したMaintenanceItemsをセット
    _machines[index] = updatedMachine.copyWith(maintenanceItems: updatedItems);
  }

  ///PreCheckRecordの結果を、対応するMaintenanceItemに反映
  ///
  ///処理フロー:
  ///1.各MaintenanceItemのComponentTypeから対応するPreCheckItem.id群を取得
  ///2.PreCheckRecordからそれらのIDの結果を取得し、最悪値を判定
  ///3.LatestPreCheckStatusを更新
  List<MaintenanceItem> _updateMaintenanceItemsWithPreCheck(
    List<MaintenanceItem> items,
    PreCheckRecord record,
  ) {
    return items.map((item) {
      final ids = _precheckIdsByComponent[item.type];
      if (ids == null || ids.isEmpty) return item; // 対応するPreCheckItemなし

      final worst = _pickWorstCheckStatus(record.result, ids);
      if (worst == null) return item; // 該当IDなし

      return item.copyWith(latestPreCheckStatus: worst);
    }).toList();
  }

  /// ComponentType → PreCheckItem.id[] のマッピング
  /// !!! precheck_items_data.dart の id と一致させること !!!
  static const Map<ComponentType, List<String>> _precheckIdsByComponent = {
    ComponentType.engineOil: [
      'engine_oil_check', // 例：漏れ
      'engine_oil_level', // 例：量
    ],
    ComponentType.coolant: ['coolant_check'],
    ComponentType.grease: ['grease_check'],
    ComponentType.airFilter: ['air_filter_check'],
    ComponentType.hydraulicOil: ['hydraulic_oil_check'],
    ComponentType.fuelFilter: ['fuel_filter_check'],
    ComponentType.transmissionOil: ['transmission_oil_check'],
    ComponentType.tirePressure: ['tire_pressure_check'],
    ComponentType.brakeWire: ['brake_wire_check'],
    // 必要なら他も追加
  };

  ///指定ID群の中で、record.resultに存在するものだけを拾い、
  ///critical > warning > good の優先で"最悪”を返す。
  ///notChecked はスキップ。何も該当がなければnull.
  CheckStatus? _pickWorstCheckStatus(
    Map<String, CheckStatus> result,
    List<String> ids,
  ) {
    CheckStatus? worst;
    for (final id in ids) {
      final s = result[id];
      if (s == null || s == CheckStatus.notChecked) continue;
      if (worst == null || _sev(s) > _sev(worst)) {
        worst = s;
      }
    }
    return worst;
  }

  // CheckStatus の"深刻度"
  int _sev(CheckStatus status) {
    switch (status) {
      case CheckStatus.critical:
        return 2;
      case CheckStatus.warning:
        return 1;
      case CheckStatus.good:
        return 0;
      case CheckStatus.notChecked:
        return -1; // 比較対象外（スキップ前提）
    }
  }
}
