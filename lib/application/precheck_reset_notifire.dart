import 'package:farmflow/application/machine_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmflow/providers/repository_provider.dart';

/// PreCheck の「日跨ぎで色が残る」問題を防ぐための一括クリア機構。
/// - アプリ起動時（または PreCheck 開始時）に「前回クリア日」と本日を比較し、
///   異なる場合は全 MaintenanceItem.latestPreCheckStatus を null にリセットする。
final precheckResetterProvider = Provider<PrecheckResetter>(
  (ref) => PrecheckResetter(ref: ref),
);

class PrecheckResetter {
  PrecheckResetter({required this.ref});
  final Ref ref;

  static const String _kLastResetKey = 'precheck_last_reset_yyyy_mm_dd';

  /// 日付が変わっていれば、全機体の latestPreCheckStatus を一括クリアする（冪等）。
  /// - クリア済みフラグは SharedPreferences の [_kLastResetKey] で管理。
  /// - 何度呼ばれても安全（同日なら何もしない）。
  Future<void> resetIfNewDate({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final _now = now ?? DateTime.now(); // タイムゾーンは端末準拠（Asia/Tokyo 想定）
    final today = _yyyyMMdd(_now);
    final last = prefs.getString(_kLastResetKey);

    if (last == today) return; // すでに本日クリア済み

    // 1) 全機体取得（同期で最新の state を読む）
    final machines = ref.read(machineListProvider);

    // 2) 各 MaintenanceItem を clearLatestPreCheck = true で保存
    final repo = ref.read(machineRepositoryProvider);
    for (final m in machines) {
      final clearedItems =
          m.maintenanceItems
              .map((item) => item.copyWith(clearLatestPreCheck: true))
              .toList();
      final updatedMachine = m.copyWith(maintenanceItems: clearedItems);
      await repo.updateMachine(updatedMachine);
    }

    // 3) 本日の日付を記録（同日中はもう一度クリアしない）
    await prefs.setString(_kLastResetKey, today);
  }

  String _yyyyMMdd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
