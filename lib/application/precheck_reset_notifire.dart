import 'package:farmflow/application/machine_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmflow/providers/repository_provider.dart';

final precheckResetterProvider = Provider<PrecheckResetter>(
  (ref) => PrecheckResetter(ref: ref),
);

class PrecheckResetter {
  PrecheckResetter({required this.ref});
  final Ref ref;

  static const String _kLastResetKey = 'precheck_last_reset_yyyy_mm_dd';

  Future<void> resetIfNewDate({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final _now = now ?? DateTime.now();
    final today = _yyyyMMdd(_now);
    final last = prefs.getString(_kLastResetKey);

    if (last == today) return;

    final machines = ref.read(machineListProvider);

    final repo = ref.read(machineRepositoryProvider);
    for (final m in machines) {
      final clearedItems =
          m.maintenanceItems
              .map((item) => item.copyWith(clearLatestPreCheck: true))
              .toList();
      final updatedMachine = m.copyWith(maintenanceItems: clearedItems);
      await repo.updateMachine(updatedMachine);
    }

    await prefs.setString(_kLastResetKey, today);
  }

  String _yyyyMMdd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
