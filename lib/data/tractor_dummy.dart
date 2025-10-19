// ↓↓↓ これを lib/data/tractor_dummy.dart に貼り付け ↓↓↓
// lib/data/tractor_dummy.dart
import 'package:farmflow/domain/machine_factory.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/precheck_item.dart';

/// Phase 2 Design: 多様なテストケースを明示的に定義
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
  // Pattern 2: ⚠️ 交換間近（warning）
  //
  // 設計意図:
  // - エンジンオイル: 1200 - 150 = 1050h に交換済み
  //   → used = 150h / interval = 200h → remaining = 50h (25%)
  // - 目標: threshold=0.3（30%）を下回る → warning
  // - 目標: threshold=0.2（20%）は上回る → critical にはならない
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
      coolant: 33, // warning 領域に入る日数
      grease: 12,
      airFilter: 29,
      tirePressure: 18,
      brakeWire: 48,
    ),
  ),

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Pattern 3: 🚨 交換時期（critical）
  //
  // 設計意図:
  // - エンジンオイル: 1880 - 180 = 1700h に交換済み
  //   → used = 180h / interval = 180h → remaining = 0h
  // - 目標: threshold=0.2（20%）を下回る → critical
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
      coolant: 62, // critical を再現
      grease: 17,
      airFilter: 35,
      tirePressure: 27,
      brakeWire: 70,
    ),
  ),

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Pattern 4: ⚠️ PreCheck 異常（時間は good）
  //
  // 設計意図:
  // - エンジンオイル: 時間的には余裕（約80% remaining）
  // - しかし PreCheck で warning 検出
  // - 結果: max(good, warning) = warning
  //
  // 学習ポイント:
  // - evaluateStatus は「時間」と「PreCheck」の厳しい方を採用
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MachineFactory.createTractor(
    id: 'TRACTOR-004',
    name: 'No.4',
    modelName: 'SL500',
    totalHours: 800,
    recommendedIntervals: _extendedIntervals,
    lastMaintenanceHours: {
      ComponentType.engineOil: 750, // used=50h (約80% remaining) → good
      ComponentType.hydraulicOil: 680, // used=120h (70% remaining) → good
      ComponentType.fuelFilter: 680, // used=120h (70% remaining) → good
      ComponentType.transmissionOil: 600, // used=200h (67% remaining) → good
    },
    preCheckStatuses: {
      ComponentType.engineOil: CheckStatus.warning, // ← PreCheck で異常検出
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
  // Pattern 5: 🚨 複合異常（時間 warning + PreCheck critical）
  //
  // 設計意図:
  // - エンジンオイル: 時間的に warning（27.5% remaining）
  // - PreCheck でも critical 検出
  // - 結果: max(warning, critical) = critical
  // - 油圧オイルも critical（17.5% remaining）
  //
  // 学習ポイント:
  // - 複数項目が同時に異常になるケース
  // - overallStatus は最悪値を採用
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
      ComponentType.engineOil: CheckStatus.critical, // ← 時間+PreCheck 両方異常
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
  // Pattern 6: 🆕 新品同様（ほぼ未使用）
  //
  // 設計意図:
  // - すべての項目が未交換（lastMaintenanceAtHour = 0）
  // - used = 50h / interval = 240h → remaining = 190h (約79%)
  // - すべて good 状態
  //
  // 学習ポイント:
  // - 新車の状態を表現
  // - Factory のデフォルト値（0）をそのまま使用
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MachineFactory.createTractor(
    id: 'TRACTOR-006',
    name: 'No.6',
    modelName: 'SL550',
    totalHours: 50,
    recommendedIntervals: _extendedIntervals,
    // lastMaintenanceHours を指定しない → すべて 0（未交換）
    lastInspectionDates: _inspectionDates(
      coolant: 3,
      grease: 2,
      airFilter: 4,
      tirePressure: 1,
      brakeWire: 7,
    ),
  ),
];
