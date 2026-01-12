import 'package:farmflow/api/machine_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmflow/data/machine_repository.dart';
import 'package:farmflow/data/tractor_dummy.dart';

const bool _useApi = true;

final machineRepositoryProvider = Provider<MachineRepository>((ref) {
  print('🔧repository_provide:_useApi $_useApi');

  if (_useApi) {
    print('🔧repository_provide:AIP経由でデータ取得');
    final api = MachineApi(baseUrl: 'http://127.0.0.1:8000');
    return MachineRepositoryImpl(api: api, initial: dummyMachines);
  } else {
    print('🔧repository_provide:ダミーデータのみ使用');
    return MachineRepositoryImpl(api: null, initial: dummyMachines);
  }
});
