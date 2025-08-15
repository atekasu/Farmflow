import 'package:uuid/uuid.dart';
import 'model/machine.dart';
import 'model/maintenance_component.dart';
import 'model/status.dart';

final _uuid = Uuid();

final rules = MaintenanceRules(); // 既定の閾値のままでOK

Machine makeTractorSL54(String name, double hours) {
  return Machine(
    name: name,
    modelName: 'SL54',
    totalHours: hours,
    components: [
      MaintenanceComponent(
        type: ComponentType.engineOil,
        name: 'エンジンオイル',
        mode: ComponentMode.intervalBased,
        recommendedIntervalHours: 200,
        lastMaintenanceAtHour: hours - 80, // 「交換から80h経過」の例
      ),
      MaintenanceComponent(
        type: ComponentType.hydraulicOil,
        name: '油圧オイル',
        mode: ComponentMode.intervalBased,
        recommendedIntervalHours: 400,
        lastMaintenanceAtHour: hours - 120,
      ),
      MaintenanceComponent(
        type: ComponentType.airFilter,
        name: 'エアフィルタ',
        mode: ComponentMode.inspectionOnly,
        lastInspectionDate: DateTime.now().subtract(const Duration(days: 25)),
      ),
    ],
  );
}

final dummyMachines = [
  makeTractorSL54('No1', 1880),
  makeTractorSL54('No2', 1850),
  makeTractorSL54('No3', 1700),
];
