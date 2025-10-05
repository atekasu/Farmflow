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
  Future<List<Machine>> fetchAllMachines() async {
    //擬似的に遅延を入れる
    await Future.delayed(const Duration(milliseconds: 300));
    return List.of(_machines);
  }

  @override
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
  Future<void> savePreCheckRecord(PreCheckRecord record) async {
    //ここでは特に何もしない
    await Future.delayed(const Duration(milliseconds: 100));
    //TODO:　PreCheckRecordを保存するロジックを実装
  }
}
