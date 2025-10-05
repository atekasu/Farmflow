import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmflow/model/machine.dart';
import 'package:farmflow/providers/repository_provider.dart';

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
}

///Machine一覧のProvider
final machineListProvider =
    AsyncNotifierProvider<MachineListNotifier, List<Machine>>(() {
      return MachineListNotifier();
    });
