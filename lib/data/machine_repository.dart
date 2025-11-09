import 'package:farmflow/data/tractor_dummy.dart';
import 'package:farmflow/model/machine.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/maintenance_item.dart';
import 'package:farmflow/model/precheck_item.dart';
import 'package:farmflow/model/precheckrecord.dart';

/// 機械データの永続化に関するリポジトリ境界です。
abstract class MachineRepository {
  /// すべての利用可能な機械を返します。
  Future<List<Machine>> fetchAllMachines();

  /// 指定された機械データを保存します（[Machine.id] によるアップサート）。
  Future<void> updateMachine(Machine machine);

  /// 点検記録を保存し、対応する機械の状態を更新します。
  Future<void> savePreCheckRecord(PreCheckRecord record);

  /// 特定のメンテナンス項目に対する作業を記録します。
  /// lastMaintenanceAtHour を [currentHour] に更新し、直近の点検状態をクリアします。
  Future<void> recordMaintenance({
    required String machineId,
    required String itemId,
    required int currentHour,
  });
}

/// ダミーデータを使用したシンプルなインメモリリポジトリです。
class MachineRepositoryImpl implements MachineRepository {
  MachineRepositoryImpl({List<Machine>? initial})
    : _machines = List<Machine>.from(initial ?? dummyMachines);

  final List<Machine> _machines;
  final List<PreCheckRecord> _preCheckHistory = [];

  static const Map<ComponentType, String> _componentToPreCheckId = {
    ComponentType.engineOil: 'engin_oil_check',
    ComponentType.coolant: 'coolant_check',
    ComponentType.grease: 'grease_check',
    ComponentType.airFilter: 'air_filter_check',
    ComponentType.tirePressure: 'tire',
    ComponentType.transmissionOil: 'gir_oil',
  };

  @override
  Future<List<Machine>> fetchAllMachines() async {
    return List<Machine>.unmodifiable(_machines);
  }

  @override
  Future<void> updateMachine(Machine machine) async {
    final index = _machines.indexWhere((m) => m.id == machine.id);
    if (index >= 0) {
      _machines[index] = machine;
    } else {
      _machines.add(machine);
    }
  }

  @override
  Future<void> savePreCheckRecord(PreCheckRecord record) async {
    final index = _machines.indexWhere((m) => m.id == record.machineId);
    if (index == -1) {
      throw StateError('Machine ${record.machineId} not found');
    }

    _preCheckHistory.add(record);
    final machine = _machines[index];

    final updatedItems = machine.maintenanceItems
        .map((item) => _applyPreCheck(item, record.result))
        .toList(growable: false);

    _machines[index] = machine.copyWith(
      maintenanceItems: updatedItems,
      lastPreCheck: record,
    );
  }

  @override
  Future<void> recordMaintenance({
    required String machineId,
    required String itemId,
    required int currentHour,
  }) async {
    final machineIndex = _machines.indexWhere((m) => m.id == machineId);
    if (machineIndex == -1) {
      throw StateError('Machine $machineId not found');
    }

    final machine = _machines[machineIndex];
    final itemIndex = machine.maintenanceItems.indexWhere(
      (i) => i.id == itemId,
    );
    if (itemIndex == -1) {
      throw StateError('Maintenance item $itemId not found');
    }
    final item = machine.maintenanceItems[itemIndex];
    final updatedItems = item.resetInterval(currentHour: currentHour);
    _machines[machineIndex] = machine.replaceMaintenanceItem(updatedItems);
  }

  MaintenanceItem _applyPreCheck(
    MaintenanceItem item,
    Map<String, CheckStatus> result,
  ) {
    final key = _componentToPreCheckId[item.type];
    if (key == null) return item;

    final status = result[key];
    if (status == null || status == CheckStatus.notChecked) {
      return item;
    }

    return item.copyWith(latestPreCheckStatus: status);
  }

  /// デバッグやテスト目的で保存された履歴を公開します。
  List<PreCheckRecord> get preCheckHistory =>
      List<PreCheckRecord>.unmodifiable(_preCheckHistory);
}
