import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmflow/data/machine_repository.dart';
import 'package:farmflow/data/tractor_dummy.dart';

///Repositoryの依存注入ポイント
final machineRepositoryProvider = Provider<MachineRepository>((ref) {
  return MachineRepositoryImpl(initial: dummyMachines);
});
