import 'package:farmflow/domain/machine_factory.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/precheck_item.dart';

DateTime _daysAgo(int days) => DateTime.now().subtract(Duration(days: days));

Map<ComponentType, DateTime> _inspectionDates({
  required int coolant,
  required int grease,
  required int airFilter,
  required int tirePressure,
  required int brakeWire,
}) {
  return {
    ComponentType.coolant: _daysAgo(coolant),
    ComponentType.grease: _daysAgo(grease),
    ComponentType.airFilter: _daysAgo(airFilter),
    ComponentType.tirePressure: _daysAgo(tirePressure),
    ComponentType.brakeWire: _daysAgo(brakeWire),
  };
}

const _standardIntervals = {
  ComponentType.engineOil: 200,
  ComponentType.hydraulicOil: 400,
  ComponentType.fuelFilter: 400,
  ComponentType.transmissionOil: 600,
};

const _extendedIntervals = {
  ComponentType.engineOil: 240,
  ComponentType.hydraulicOil: 450,
  ComponentType.fuelFilter: 480,
  ComponentType.transmissionOil: 650,
};

const _heavyDutyIntervals = {
  ComponentType.engineOil: 180,
  ComponentType.hydraulicOil: 360,
  ComponentType.fuelFilter: 360,
  ComponentType.transmissionOil: 550,
};

final dummyMachines = [
  MachineFactory.createTractor(
    id: 'TRACTOR-001',
    name: 'No.1',
    modelName: 'SL54',
    totalHours: 500,
    recommendedIntervals: _extendedIntervals,
    lastMaintenanceHours: {
      ComponentType.engineOil: 420,
      ComponentType.hydraulicOil: 380,
      ComponentType.fuelFilter: 380,
      ComponentType.transmissionOil: 300,
    },
    lastInspectionDates: _inspectionDates(
      coolant: 18,
      grease: 6,
      airFilter: 21,
      tirePressure: 8,
      brakeWire: 40,
    ),
  ),
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //
  //   → used = 150h / interval = 200h → remaining = 50h (25%)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MachineFactory.createTractor(
    id: 'TRACTOR-002',
    name: 'No.2',
    modelName: 'MR70',
    totalHours: 1200,
    recommendedIntervals: _standardIntervals,
    lastMaintenanceHours: {
      ComponentType.engineOil: 1050, // used=150h (25% remaining) → warning
      ComponentType.hydraulicOil: 1080, // used=120h (70% remaining) → good
      ComponentType.fuelFilter: 1080, // used=120h (70% remaining) → good
      ComponentType.transmissionOil: 1000, // used=200h (67% remaining) → good
    },
    lastInspectionDates: _inspectionDates(
      coolant: 33,
      grease: 12,
      airFilter: 29,
      tirePressure: 18,
      brakeWire: 48,
    ),
  ),

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //
  //   → used = 180h / interval = 180h → remaining = 0h
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MachineFactory.createTractor(
    id: 'TRACTOR-003',
    name: 'No.3',
    modelName: 'KL50',
    totalHours: 1880,
    recommendedIntervals: _heavyDutyIntervals,
    lastMaintenanceHours: {
      ComponentType.engineOil: 1700, // used=180h (0% remaining) → critical
      ComponentType.hydraulicOil: 1760, // used=120h (70% remaining) → good
      ComponentType.fuelFilter: 1760, // used=120h (70% remaining) → good
      ComponentType.transmissionOil: 1680, // used=200h (67% remaining) → good
    },
    lastInspectionDates: _inspectionDates(
      coolant: 62,
      grease: 17,
      airFilter: 35,
      tirePressure: 27,
      brakeWire: 70,
    ),
  ),

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //
  //
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MachineFactory.createTractor(
    id: 'TRACTOR-004',
    name: 'No.4',
    modelName: 'SL500',
    totalHours: 800,
    recommendedIntervals: _extendedIntervals,
    lastMaintenanceHours: {
      ComponentType.engineOil: 750,
      ComponentType.hydraulicOil: 680, // used=120h (70% remaining) → good
      ComponentType.fuelFilter: 680, // used=120h (70% remaining) → good
      ComponentType.transmissionOil: 600, // used=200h (67% remaining) → good
    },
    preCheckStatuses: {
      ComponentType.engineOil: CheckStatus.warning,
    },
    lastInspectionDates: _inspectionDates(
      coolant: 14,
      grease: 4,
      airFilter: 19,
      tirePressure: 7,
      brakeWire: 30,
    ),
  ),

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //
  //
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MachineFactory.createTractor(
    id: 'TRACTOR-005',
    name: 'No.5',
    modelName: 'SL500',
    totalHours: 2100,
    recommendedIntervals: _standardIntervals,
    lastMaintenanceHours: {
      ComponentType.engineOil: 1955, // used=145h (27.5% remaining) → warning
      ComponentType.hydraulicOil:
          1770, // used=330h (17.5% remaining) → critical
      ComponentType.fuelFilter: 1980, // used=120h (70% remaining) → good
      ComponentType.transmissionOil: 1900, // used=200h (67% remaining) → good
    },
    preCheckStatuses: {
      ComponentType.engineOil: CheckStatus.critical,
    },
    lastInspectionDates: _inspectionDates(
      coolant: 44,
      grease: 24,
      airFilter: 38,
      tirePressure: 32,
      brakeWire: 61,
    ),
  ),

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //
  //
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MachineFactory.createTractor(
    id: 'TRACTOR-006',
    name: 'No.6',
    modelName: 'SL550',
    totalHours: 50,
    recommendedIntervals: _extendedIntervals,
    lastInspectionDates: _inspectionDates(
      coolant: 3,
      grease: 2,
      airFilter: 4,
      tirePressure: 1,
      brakeWire: 7,
    ),
  ),
];
