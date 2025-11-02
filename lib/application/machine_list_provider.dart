import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmflow/data/machine_repository.dart';
import 'package:farmflow/model/machine.dart';
import 'package:farmflow/model/precheckrecord.dart';
import 'package:farmflow/providers/repository_provider.dart';

/// Machine一覧を管理する StateNotifier。
/// 画面側は machineListProvider を watch/read するだけで、
/// - 一覧の取得
/// - 交換の記録
/// - 始業前点検の保存
/// をすべて扱える。
class MachineListNotifier extends StateNotifier<List<Machine>> {
  MachineListNotifier(this._repo) : super(const []) {
    _load();
  }

  final MachineRepository _repo;

  /// 起動時・初期化時にダミーデータ等を読み込み
  Future<void> _load() async {
    state = await _repo.fetchAllMachines();
  }

  /// 外から明示的に最新データを再取得したいとき
  Future<void> refresh() async {
    state = await _repo.fetchAllMachines();
  }

  /// 長押しで「交換済み」と記録するときに呼ばれる。
  ///
  /// - [machineId]: どの機体か
  /// - [itemId]: どのメンテ項目か (例 'TRACTOR-003-engine-oil')
  ///
  /// Flow:
  ///   1. 現在の totalHours を state から取り出す
  ///   2. Repository に交換記録させる (lastMaintenanceAtHour を更新して latestPreCheckStatus を消す)
  ///   3. 最新状態を再ロードして state を更新する
  Future<void> recordExchange({
    required String machineId,
    required String itemId,
  }) async {
    // 現在の機体情報を state から探す（totalHours のため）
    final machine = state.firstWhere((m) => m.id == machineId);
    final currentHour = machine.totalHours;

    // Repository に処理を依頼
    await _repo.recordMaintenance(
      machineId: machineId,
      itemId: itemId,
      currentHour: currentHour,
    );

    // UIへ最新状態を反映
    await refresh();
  }

  /// 始業前点検(PreCheck) の結果を保存するときに呼ぶ。
  ///
  /// - [record]: PreWorkInspectionScreen から返ってきた点検結果
  /// - Repository 側で:
  ///     - machine.lastPreCheck を更新
  ///     - maintenanceItems の latestPreCheckStatus を更新
  ///   → そのあと state をリロードして UI も更新
  Future<void> savePreCheckRecord(PreCheckRecord record) async {
    await _repo.savePreCheckRecord(record);
    await refresh();
  }
}

/// Riverpod Provider 定義。
///
/// 画面では:
///   final machines = ref.watch(machineListProvider);
/// で機械一覧を購読できる。
///
/// 書き込み系(交換記録/点検保存など)は:
///   ref.read(machineListProvider.notifier).recordExchange(...);
///   ref.read(machineListProvider.notifier).savePreCheckRecord(...);
final machineListProvider =
    StateNotifierProvider<MachineListNotifier, List<Machine>>((ref) {
      final repo = ref.read(machineRepositoryProvider);
      return MachineListNotifier(repo);
    });
