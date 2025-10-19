import 'package:farmflow/model/machine.dart';
import 'package:farmflow/model/machine/maintenance_item.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/precheck_item.dart'; // CheckStatus

/// Factory for constructing Machine instances with predefined items per model.
///
/// Phase 2 Design: Factory は「構造」のみを定義
/// - 項目の種類（エンジンオイル、クーラント等）
/// - 推奨間隔（200h, 400h 等）
/// - モード（intervalBased / inspectionOnly）
///
/// 値（lastMaintenanceAtHour 等）は外から注入する。
class MachineFactory {
  const MachineFactory._();

  /// トラクターを生成（標準的なメンテナンス項目付き）
  ///
  /// [lastMaintenanceHours]: 各項目の最終交換アワーを指定
  ///   例: {ComponentType.engineOil: 1700} → エンジンオイルを 1700h に交換済み
  ///
  /// [preCheckStatuses]: 各項目の PreCheck 状態を指定（オプション）
  ///   例: {ComponentType.engineOil: CheckStatus.warning}
  ///
  /// [recommendedIntervals]: intervalBased 項目ごとの推奨交換間隔。
  ///
  /// [lastInspectionDates]: inspectionOnly 項目の最終点検日。
  ///
  /// 指定されなかった項目は、デフォルト値を使用：
  /// - intervalBased: lastMaintenanceAtHour = 0（未交換）
  /// - latestPreCheckStatus = null
  static Machine createTractor({
    required String id,
    required String name,
    required String modelName,
    required int totalHours,
    required Map<ComponentType, int> recommendedIntervals,
    required Map<ComponentType, DateTime> lastInspectionDates,
    Map<ComponentType, int> lastMaintenanceHours = const {},
    Map<ComponentType, CheckStatus> preCheckStatuses = const {},
  }) {
    int _intervalFor(ComponentType type) {
      final value = recommendedIntervals[type];
      if (value == null) {
        throw ArgumentError.value(
          type,
          'type',
          'recommendedIntervals is missing key for $type',
        );
      }
      return value;
    }

    return Machine(
      id: id,
      name: name,
      modelName: modelName,
      totalHours: totalHours,
      maintenanceItems: [
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // intervalBased 項目（時間ベースで交換）
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        MaintenanceItem(
          id: '$id-engine-oil',
          type: ComponentType.engineOil,
          name: 'エンジンオイル',
          mode: ComponentMode.intervalBased,
          recommendedIntervalHours: _intervalFor(ComponentType.engineOil),
          lastMaintenanceAtHour:
              lastMaintenanceHours[ComponentType.engineOil] ?? 0,
          latestPreCheckStatus: preCheckStatuses[ComponentType.engineOil],
        ),
        MaintenanceItem(
          id: '$id-hydraulic',
          type: ComponentType.hydraulicOil,
          name: '油圧オイル',
          mode: ComponentMode.intervalBased,
          recommendedIntervalHours: _intervalFor(ComponentType.hydraulicOil),
          lastMaintenanceAtHour:
              lastMaintenanceHours[ComponentType.hydraulicOil] ?? 0,
          latestPreCheckStatus: preCheckStatuses[ComponentType.hydraulicOil],
        ),
        MaintenanceItem(
          id: '$id-fuel-filter',
          type: ComponentType.fuelFilter,
          name: '燃料フィルタ',
          mode: ComponentMode.intervalBased,
          recommendedIntervalHours: _intervalFor(ComponentType.fuelFilter),
          lastMaintenanceAtHour:
              lastMaintenanceHours[ComponentType.fuelFilter] ?? 0,
          latestPreCheckStatus: preCheckStatuses[ComponentType.fuelFilter],
        ),
        MaintenanceItem(
          id: '$id-transmission-oil',
          type: ComponentType.transmissionOil,
          name: 'トランスミッションオイル',
          mode: ComponentMode.intervalBased,
          recommendedIntervalHours: _intervalFor(ComponentType.transmissionOil),
          lastMaintenanceAtHour:
              lastMaintenanceHours[ComponentType.transmissionOil] ?? 0,
          latestPreCheckStatus: preCheckStatuses[ComponentType.transmissionOil],
        ),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // inspectionOnly 項目（目視点検のみ）
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        MaintenanceItem(
          id: '$id-coolant',
          type: ComponentType.coolant,
          name: 'クーラント',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: lastInspectionDates[ComponentType.coolant],
          latestPreCheckStatus: preCheckStatuses[ComponentType.coolant],
        ),
        MaintenanceItem(
          id: '$id-grease',
          type: ComponentType.grease,
          name: 'グリス',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: lastInspectionDates[ComponentType.grease],
          latestPreCheckStatus: preCheckStatuses[ComponentType.grease],
        ),
        MaintenanceItem(
          id: '$id-air-filter',
          type: ComponentType.airFilter,
          name: 'エアフィルタ',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: lastInspectionDates[ComponentType.airFilter],
          latestPreCheckStatus: preCheckStatuses[ComponentType.airFilter],
        ),
        MaintenanceItem(
          id: '$id-tire-pressure',
          type: ComponentType.tirePressure,
          name: 'タイヤ空気圧',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: lastInspectionDates[ComponentType.tirePressure],
          latestPreCheckStatus: preCheckStatuses[ComponentType.tirePressure],
        ),
        MaintenanceItem(
          id: '$id-brake-wire',
          type: ComponentType.brakeWire,
          name: 'ブレーキワイヤー',
          mode: ComponentMode.inspectionOnly,
          lastInspectionDate: lastInspectionDates[ComponentType.brakeWire],
          latestPreCheckStatus: preCheckStatuses[ComponentType.brakeWire],
        ),
      ],
    );
  }
}
