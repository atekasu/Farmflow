import 'package:farmflow/model/machine.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/maintenance_item.dart';
import 'package:farmflow/model/precheck_item.dart';

/// Factory responsible for building `Machine` aggregates with predefined parts.
class MachineFactory {
  const MachineFactory._();

  /// Create a tractor with the standard set of maintenance items.
  ///
  /// Callers can override defaults by passing maps keyed by [ComponentType].
  static Machine createTractor({
    required String id,
    required String name,
    required String modelName,
    required int totalHours,
    Map<ComponentType, int> recommendedIntervals = const {},
    Map<ComponentType, int> lastMaintenanceHours = const {},
    Map<ComponentType, DateTime> lastInspectionDates = const {},
    Map<ComponentType, CheckStatus> preCheckStatuses = const {},
  }) {
    final now = DateTime.now();

    int _recommendedInterval(ComponentType type, int fallback) =>
        recommendedIntervals[type] ?? fallback;

    int _lastMaintenanceHour(ComponentType type, int fallback) {
      final value = lastMaintenanceHours[type];
      if (value != null) {
        return value;
      }
      return fallback < 0 ? 0 : fallback;
    }

    DateTime _lastInspectionDate(ComponentType type, Duration fallback) {
      final value = lastInspectionDates[type];
      if (value != null) {
        return value;
      }
      return now.subtract(fallback);
    }

    CheckStatus? _latestPreCheckStatus(ComponentType type) =>
        preCheckStatuses[type];

    return Machine(
      id: id,
      name: name,
      modelName: modelName,
      totalHours: totalHours,
      maintenanceItems: [
        MaintenanceItem(
          id: '$id-engine-oil',
          type: ComponentType.engineOil,
          name: 'エンジンオイル',
          mode: ComponentMode.intervalBased,
          recommendedIntervalHours: _recommendedInterval(
            ComponentType.engineOil,
            200,
          ),
          lastMaintenanceAtHour: _lastMaintenanceHour(
            ComponentType.engineOil,
            0,
          ),
          latestPreCheckStatus: _latestPreCheckStatus(ComponentType.engineOil),
        ),
        MaintenanceItem(
          id: '$id-coolant',
          type: ComponentType.coolant,
          name: 'クーラント',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: _lastInspectionDate(
            ComponentType.coolant,
            const Duration(days: 30),
          ),
          latestPreCheckStatus: _latestPreCheckStatus(ComponentType.coolant),
        ),
        MaintenanceItem(
          id: '$id-grease',
          type: ComponentType.grease,
          name: 'グリス',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: _lastInspectionDate(
            ComponentType.grease,
            const Duration(days: 10),
          ),
          latestPreCheckStatus: _latestPreCheckStatus(ComponentType.grease),
        ),
        MaintenanceItem(
          id: '$id-air-filter',
          type: ComponentType.airFilter,
          name: 'エアフィルタ',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: _lastInspectionDate(
            ComponentType.airFilter,
            const Duration(days: 25),
          ),
          latestPreCheckStatus: _latestPreCheckStatus(ComponentType.airFilter),
        ),
        MaintenanceItem(
          id: '$id-hydraulic',
          type: ComponentType.hydraulicOil,
          name: '油圧オイル',
          mode: ComponentMode.intervalBased,
          recommendedIntervalHours: _recommendedInterval(
            ComponentType.hydraulicOil,
            400,
          ),
          lastMaintenanceAtHour: _lastMaintenanceHour(
            ComponentType.hydraulicOil,
            totalHours - 120,
          ),
          latestPreCheckStatus: _latestPreCheckStatus(
            ComponentType.hydraulicOil,
          ),
        ),
        MaintenanceItem(
          id: '$id-fuel-filter',
          type: ComponentType.fuelFilter,
          name: '燃料フィルタ',
          mode: ComponentMode.intervalBased,
          recommendedIntervalHours: _recommendedInterval(
            ComponentType.fuelFilter,
            400,
          ),
          lastMaintenanceAtHour: _lastMaintenanceHour(
            ComponentType.fuelFilter,
            totalHours - 120,
          ),
          latestPreCheckStatus: _latestPreCheckStatus(ComponentType.fuelFilter),
        ),
        MaintenanceItem(
          id: '$id-transmission-oil',
          type: ComponentType.transmissionOil,
          name: 'トランスミッションオイル',
          mode: ComponentMode.intervalBased,
          recommendedIntervalHours: _recommendedInterval(
            ComponentType.transmissionOil,
            600,
          ),
          lastMaintenanceAtHour: _lastMaintenanceHour(
            ComponentType.transmissionOil,
            totalHours - 200,
          ),
          latestPreCheckStatus: _latestPreCheckStatus(
            ComponentType.transmissionOil,
          ),
        ),
        MaintenanceItem(
          id: '$id-tire-pressure',
          type: ComponentType.tirePressure,
          name: 'タイヤ空気圧',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: _lastInspectionDate(
            ComponentType.tirePressure,
            const Duration(days: 15),
          ),
          latestPreCheckStatus: _latestPreCheckStatus(
            ComponentType.tirePressure,
          ),
        ),
      ],
    );
  }
}
