import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:farmflow/data/machine_repository.dart';
import 'package:farmflow/model/machine.dart';
import 'package:farmflow/model/precheckrecord.dart';
import 'package:farmflow/providers/repository_provider.dart';

class MachineListNotifier extends StateNotifier<List<Machine>> {
  MachineListNotifier(this._repo) : super(const []) {
    _load();
  }

  final MachineRepository _repo;

  Future<void> _load() async {
    final machine = await _repo.fetchAllMachines();
    state = List<Machine>.from(machine);
  }

  Future<void> refresh() async {
    print('🔄 [Provider] refresh() start');
    final machines = await _repo.fetchAllMachines();
    print('☑︎ [Provider] fetched ${machines.length}');

    state = List<Machine>.from(machines);

    print('🔁 [Provider] state updated to ${state.length} machines');
  }

  ///
  ///
  /// Flow:
  Future<void> recordExchange({
    required String machineId,
    required String itemId,
  }) async {
    debugPrint('recordExchange: start machineId=$machineId itemId=$itemId');
    final machine = state.firstWhere((m) => m.id == machineId);
    final currentHour = machine.totalHours;

    await _repo.recordMaintenance(
      machineId: machineId,
      itemId: itemId,
      currentHour: currentHour,
    );

    debugPrint('🔁recordExchange calling refresh()');
    await refresh();
    debugPrint('☑︎ recordExchange done (after refresh)');
  }

  ///
  Future<void> savePreCheckRecord(PreCheckRecord record) async {
    await _repo.savePreCheckRecord(record);
    await refresh();
  }
}

///
///   final machines = ref.watch(machineListProvider);
///
///   ref.read(machineListProvider.notifier).recordExchange(...);
///   ref.read(machineListProvider.notifier).savePreCheckRecord(...);
final machineListProvider =
    StateNotifierProvider<MachineListNotifier, List<Machine>>((ref) {
      final repo = ref.read(machineRepositoryProvider);
      return MachineListNotifier(repo);
    });
