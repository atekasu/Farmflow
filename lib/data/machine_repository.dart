import 'package:farmflow/api/machine_api.dart';
import 'package:farmflow/data/tractor_dummy.dart';
import 'package:farmflow/model/machine.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/maintenance_item.dart';
import 'package:farmflow/model/precheck_item.dart';
import 'package:farmflow/model/precheckrecord.dart';

abstract class MachineRepository {
  Future<List<Machine>> fetchAllMachines();

  Future<void> updateMachine(Machine machine);

  Future<void> savePreCheckRecord(PreCheckRecord record);

  Future<void> recordMaintenance({
    required String machineId,
    required String itemId,
    required int currentHour,
  });
}

//=============================================
//==============================================
///
class MachineRepositoryImpl implements MachineRepository {
  MachineRepositoryImpl({MachineApi? api, List<Machine>? initial})
    : _api = api,
      _machines = List<Machine>.from(initial ?? dummyMachines);

  final MachineApi? _api;

  final List<Machine> _machines;

  final List<PreCheckRecord> _preCheckHistory = [];

  ///
  static const Map<ComponentType, String> _componentToPreCheckId = {
    ComponentType.engineOil: 'engin_oil_check',
    ComponentType.coolant: 'coolant_check',
    ComponentType.grease: 'grease_check',
    ComponentType.airFilter: 'air_filter_check',
    ComponentType.tirePressure: 'tire',
    ComponentType.transmissionOil: 'gir_oil',
  };

  ///==============================================
  ///===============================================

  @override
  Future<List<Machine>> fetchAllMachines() async {
    if (_api == null) {
      print('📝ダミーデータを使用');
      return List<Machine>.unmodifiable(_machines);
    }
    try {
      print('🌐APIから機械データを取得中...');
      final machines = await _api.fetchMachines();

      print('✅APIからの取得成功: ${machines.length} 台の機械を取得');
      _machines.clear();
      _machines.addAll(machines);

      return List<Machine>.unmodifiable(machines);
    } catch (e) {
      //
      print('⚠️APIからの取得失敗: $e');
      print('⚠️ダミーデータにフォールバック');

      return List<Machine>.unmodifiable(_machines);
    }
  }

  //=============================================
  ///=============================================
  @override
  Future<void> updateMachine(Machine machine) async {
    final index = _machines.indexWhere((m) => m.id == machine.id);
    if (index >= 0) {
      _machines[index] = machine;
    } else {
      _machines.add(machine);
    }

  }

  // =============================================
  //============================================

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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @override
  Future<void> recordMaintenance({
    required String machineId,
    required String itemId,
    required int currentHour,
  }) async {
    if (_api != null) {
      try {
        print(
          '🌏APIへメンテ交換を送信中... machineId=$machineId itemId=$itemId hour=$currentHour',
        );

        final res = await _api!.recordMaintenance(
          machineId: machineId,
          itemId: itemId,
          currentHour: currentHour,
        );

        print('☑︎APIメンテナンス交換 成功: $res');

        _applyLocalMaintenanceUpdate(
          machineId: machineId,
          itemId: itemId,
          currentHour: currentHour,
        );

        return;
      } catch (e) {
        print('⚠️APIメンテ交換 失敗: $e → ローカル更新にフォールバック');
        _applyLocalMaintenanceUpdate(
          machineId: machineId,
          itemId: itemId,
          currentHour: currentHour,
        );
        return;
      }
    }

    _applyLocalMaintenanceUpdate(
      machineId: machineId,
      itemId: itemId,
      currentHour: currentHour,
    );
  }

  void _applyLocalMaintenanceUpdate({
    required String machineId,
    required String itemId,
    required int currentHour,
  }) {
    final machineIndex = _machines.indexWhere((m) => m.id == machineId);
    if (machineIndex == -1) {
      throw StateError('machine $machineId not found');
    }
    final machine = _machines[machineIndex];
    final itemIndex = machine.maintenanceItems.indexWhere(
      (i) => i.id == itemId,
    );
    if (itemIndex == -1) {
      throw StateError('Maintenance item $itemId not found');
    }

    final item = machine.maintenanceItems[itemIndex];
    final updatedItem = item.resetInterval(currentHour: currentHour);

    _machines[machineIndex] = machine.replaceMaintenanceItem(updatedItem);
  }

  @override
  //========================
  //========================
  ///
  ///
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

  List<PreCheckRecord> get preCheckHistory =>
      List<PreCheckRecord>.unmodifiable(_preCheckHistory);
}
