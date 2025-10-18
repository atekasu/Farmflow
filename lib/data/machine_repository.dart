import 'package:farmflow/data/tractor_dummy.dart';
import 'package:farmflow/model/machine.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/maintenance_item.dart';
import 'package:farmflow/model/precheck_item.dart';
import 'package:farmflow/model/precheckrecord.dart';

/// Repository boundary for machine persistence.
abstract class MachineRepository {
  /// Returns all available machines.
  Future<List<Machine>> fetchAllMachines();

  /// Persists the provided machine (upsert by [Machine.id]).
  Future<void> updateMachine(Machine machine);

  /// Saves a pre-check record and updates the corresponding machine state.
  Future<void> savePreCheckRecord(PreCheckRecord record);
}

/// Simple in-memory repository backed by the dummy data set.
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

  /// Exposes the saved history for debug/testing purposes.
  List<PreCheckRecord> get preCheckHistory =>
      List<PreCheckRecord>.unmodifiable(_preCheckHistory);
}
