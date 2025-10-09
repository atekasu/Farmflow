import 'package:farmflow/model/machine.dart';
import 'package:farmflow/model/precheckrecord.dart';

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
    : _machines = List.of(initial ?? const []);

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
    if (index != -1) {
      _machines[index] = _machines[index].copyWith(lastPreCheck: record);
    }
  }
}
