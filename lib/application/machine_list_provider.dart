import 'package:farmflow/data/machine_repository.dart';
import 'package:farmflow/model/precheckrecord.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmflow/model/machine.dart';
import 'package:farmflow/providers/repository_provider.dart';

///Machine一覧管理するStateNotfire
class MachineListNotfire extends StateNotifier<List<Machine>> {
  MachineListNotfire(this._repo) : super([]) {
    _load();
  }
  final MachineRepository _repo;

  Future<void> _load() async {
    state = await _repo.fetchAllMachines();
  }

  Future<void> refresh() async {
    state = await _repo.fetchAllMachines();
  }

  ///長押しで交換した時に呼ばれる関数
  Future<void> recordExchange({
    required String machineId,
    required String itemId,
  }) async {
    //現在の機体情報を探す
    final machine = state.firstWhere((m) => m.id == machineId);
    final currentHour = machine.totalHours;

    // Repository に処理を依頼
    await _repo.recordMaintenance(
      machineId: machineId,
      itemId: itemId,
      currentHour: currentHour,
    );
    //再読み込みしてUIに反映
    await refresh();
  }
}

/// Providerの定義
final machineListProvider =
    StateNotifierProvider<MachineListNotfire, List<Machine>>((ref) {
      final repo = ref.read(machineRepositoryProvider);
      return MachineListNotfire(repo);
    });

///Machine一覧の非同期状態を管理
class MachineListNotifier extends AsyncNotifier<List<Machine>> {
  @override
  Future<List<Machine>> build() async {
    final repository = ref.watch(machineRepositoryProvider);
    return await repository.fetchAllMachines();
  }

  ///手動リフレッシュ(プルリフレッシュ等で使用)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(machineRepositoryProvider);
      return await repository.fetchAllMachines();
    });
  }

  ///特定のMachineを更新
  Future<void> updateMachine(Machine machine) async {
    final repository = ref.read(machineRepositoryProvider);
    await repository.updateMachine(machine);

    //更新後にリスト全体をリフレッシュ
    await refresh();
  }

  ///セーブ用
  Future<void> savePreCheckResult(
    String _machineId,
    PreCheckRecord record,
  ) async {
    final repo = ref.read(machineRepositoryProvider);
    await repo.savePreCheckRecord(record);
    await refresh();
  }
}

///Machine一覧のProvider
final machineListAsyncProvider =
    AsyncNotifierProvider<MachineListNotifier, List<Machine>>(() {
      return MachineListNotifier();
    });
