/**
 * MaintenanceItem
 * ----------------
 * 「特定の機体コンポーネント（例: エンジンオイル）」の“計画的メンテナンス状態”を表すモデル。
 *
 * ■ 責務（Single Responsibility）
 * - 時間/日数ベースの規則に基づき、現在の状態（EquipmentStatus）を評価する。
 * - 使用前点検（PreCheck）の最新結果を**読み取り**、時間/日数評価と合成（より深刻な方を採用）。
 *   ※ PreCheckの保存・初期化はRepository等、別レイヤで行う（ここでは書き込まない）。
 *
 * ■ 重要な前提（Invariants）
 * - mode==intervalBased の場合、recommendedIntervalHours は > 0。
 * - lastMaintenanceAtHour は 0 以上（負のアワーメータは不可）。
 * - latestPreCheckStatus は「当日などの最新結果」。null は「まだ記録なし」または「該当項目なし」。
 *
 * ■ 合成ポリシー（Safety First）
 * - final = max(timeBased, preCheck) で“安全側（厳しい側）”に倒す。
 * - notChecked / null はここでは「良」とみなす（未点検の警告は別ロジックで扱う）。
 *
 * ■ 単位（Units）
 * - Hours: int（アワーメータの整数時間）
 * - Days : int（差分日数）
 *
 * ■ よくある落とし穴
 * - latestPreCheckStatus を永続化する設計では、**日またぎのクリア戦略**が必須。
 *   例: アプリ起動時やPreCheck開始時に全項目をクリアする等。
 */
import 'package:farmflow/model/machine/equipment_status.dart';
// Domain enums/status
import 'package:farmflow/model/machine/maintenance_rules.dart';
// Rules for thresholding
import 'package:farmflow/model/precheck_item.dart';
// PreCheck (CheckStatus)

class MaintenanceItem {
  const MaintenanceItem({
    required this.id,
    required this.type,
    required this.name,
    required this.mode,
    this.recommendedIntervalHours,
    this.lastMaintenanceAtHour,
    this.lastInspectionDate,
    this.note,
    this.latestPreCheckStatus,
  }) : assert(
         mode != ComponentMode.intervalBased ||
             (recommendedIntervalHours ?? 0) > 0,
         'intervalBased なのに recommendedIntervalHours が未設定/0',
       ),
       assert(
         (lastMaintenanceAtHour ?? 0) >= 0,
         'lastMaintenanceAtHour は負にできません',
       );
  factory MaintenanceItem.fromJson(Map<String, dynamic> json) {
    const typeMap = <String, ComponentType>{
      'engineOil': ComponentType.engineOil,
      'coolant': ComponentType.coolant,
      'grease': ComponentType.grease,
      'airFilter': ComponentType.airFilter,
      'hydraulicOil': ComponentType.hydraulicOil,
      'fuelFilter': ComponentType.fuelFilter,
      'transmissionOil': ComponentType.transmissionOil,
      'tirePressure': ComponentType.tirePressure,
      'brakeWire': ComponentType.brakeWire,
    };

    const modeMap = <String, ComponentMode>{
      'intervalBased': ComponentMode.intervalBased,
      'inspectionOnly': ComponentMode.inspectionOnly,
    };

    const statusMap = <String, CheckStatus>{
      'notChecked': CheckStatus.notChecked,
      'good': CheckStatus.good,
      'critical': CheckStatus.critical,
      'warning': CheckStatus.warning,
    };

    String requireString(String key) {
      final v = json[key];
      if (v is String && v.isNotEmpty) return v;
      throw FormatException('$key is required but was $v');
    }

    int? asInt(dynamic v) => v == null ? null : (v as num).toInt();
    DateTime? asDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed;
      }
      throw FormatException('last_inspection_date has invalid format: $v');
    }

    final typeStr = requireString('type');
    final modeStr = requireString('mode');

    final type = typeMap[typeStr];
    if (type == null) {
      throw FormatException("Unknown type: '$typeStr");
    }
    final mode = modeMap[modeStr];
    if (mode == null) {
      throw FormatException("Unknown mode: '$modeStr");
    }

    final statusStr = json['latest_precheck_status'] as String?;
    final latestStatus = statusStr == null ? null : statusMap[statusStr];
    if (statusStr != null && latestStatus == null) {
      throw FormatException("Unknown latest_precheck_status: '$statusStr");
    }

    return MaintenanceItem(
      id: requireString('id'),
      type: type,
      name: requireString('name'),
      mode: mode,
      recommendedIntervalHours: asInt(json['recommended_interval_hours']),
      lastMaintenanceAtHour: asInt(json['last_maintenance_at_hour']),
      lastInspectionDate: asDate(json['last_inspection_date']),
      note: json['note'] as String?,
      latestPreCheckStatus: latestStatus,
    );
  }
  final String id;
  final ComponentType type;
  final String name;
  final ComponentMode mode;
  final int? recommendedIntervalHours;
  final int? lastMaintenanceAtHour;
  final DateTime? lastInspectionDate;
  final String? note;

  final CheckStatus? latestPreCheckStatus;

  ///
  EquipmentStatus evaluateStatus(
    int currentHour,
    MaintenanceRules rules, {
    DateTime? now,
  }) {
    final _now = now ?? DateTime.now();

    final timeBasedStatus = _evaluateTimeBasedStatus(currentHour, rules, _now);
    final preCheckStatus = _evaluatePreCheckStatus();

    return _maxStatus(timeBasedStatus, preCheckStatus);
  }


  ///
  /// - intervalBased:
  /// - inspectionOnly:
  ///
  EquipmentStatus _evaluateTimeBasedStatus(
    int currentHour,
    MaintenanceRules rules,
    DateTime now,
  ) {
    switch (mode) {
      case ComponentMode.intervalBased:
        final int total = recommendedIntervalHours ?? 0;
        if (total <= 0) return EquipmentStatus.good;

        final int used = (currentHour - (lastMaintenanceAtHour ?? 0)).clamp(
          0,
          0x7fffffff,
        );
        final int remaining = (total - used).clamp(0, total);
        final double remainingRatio = (remaining / total).clamp(0.0, 1.0);

        if (remainingRatio < rules.criticalThreshold) {
          return EquipmentStatus.critical;
        } else if (remainingRatio < rules.yellowThreshold) {
          return EquipmentStatus.warning;
        } else {
          return EquipmentStatus.good;
        }

      case ComponentMode.inspectionOnly:
        final last = lastInspectionDate;
        if (last == null) return EquipmentStatus.warning;
        final int days = _daysSince(last, now);
        if (days >= rules.inspectionMaxDaysCritical) {
          return EquipmentStatus.critical;
        } else if (days >= rules.inspectionMaxDaysWarning) {
          return EquipmentStatus.warning;
        } else {
          return EquipmentStatus.good;
        }
    }
  }

  ///
  EquipmentStatus _evaluatePreCheckStatus() {
    final s = latestPreCheckStatus;
    if (s == null) return EquipmentStatus.good;

    switch (s) {
      case CheckStatus.critical:
        return EquipmentStatus.critical;
      case CheckStatus.warning:
        return EquipmentStatus.warning;
      case CheckStatus.good:
        return EquipmentStatus.good;
      case CheckStatus.notChecked:
        return EquipmentStatus.good;
    }
  }

  static const _severity = {
    EquipmentStatus.good: 0,
    EquipmentStatus.warning: 1,
    EquipmentStatus.critical: 2,
  };

  EquipmentStatus _maxStatus(EquipmentStatus a, EquipmentStatus b) {
    final aa = _severity[a] ?? 0;
    final bb = _severity[b] ?? 0;
    return (aa >= bb) ? a : b;
  }


  int _daysSince(DateTime from, DateTime to) => to.difference(from).inDays;

  int remainingHours(int currentHour) {
    final int total = recommendedIntervalHours ?? 0;
    if (total <= 0) return 0;
    final int used = (currentHour - (lastMaintenanceAtHour ?? 0)).clamp(
      0,
      0x7fffffff,
    );
    return (total - used).clamp(0, total);
  }

  MaintenanceItem copyWith({
    String? id,
    ComponentType? type,
    String? name,
    ComponentMode? mode,
    int? recommendedIntervalHours,
    int? lastMaintenanceAtHour,
    DateTime? lastInspectionDate,
    String? note,
    CheckStatus? latestPreCheckStatus,
    bool clearLatestPreCheck = false,
  }) {
    return MaintenanceItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      recommendedIntervalHours:
          recommendedIntervalHours ?? this.recommendedIntervalHours,
      lastMaintenanceAtHour:
          lastMaintenanceAtHour ?? this.lastMaintenanceAtHour,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      note: note ?? this.note,
      latestPreCheckStatus:
          clearLatestPreCheck
              ? null
              : (latestPreCheckStatus ?? this.latestPreCheckStatus),
    );
  }
}

//============================================
//==============================================

extension MaintenanceItemJson on MaintenanceItem {
  static const Map<String, ComponentType> _typeMap = {
    'engineOil': ComponentType.engineOil,
    'coolant': ComponentType.coolant,
    'grease': ComponentType.grease,
    'airFilter': ComponentType.airFilter,
    'hydraulicOil': ComponentType.hydraulicOil,
    'fuelFilter': ComponentType.fuelFilter,
    'transmissionOil': ComponentType.transmissionOil,
    'tirePressure': ComponentType.tirePressure,
    'brakeWire': ComponentType.brakeWire,
  };

  static const Map<String, ComponentMode> _modeMap = {
    'intervalBased': ComponentMode.intervalBased,
    'inspectionOnly': ComponentMode.inspectionOnly,
  };

  static const Map<String, CheckStatus> _statusMap = {
    'notChecked': CheckStatus.notChecked,
    'good': CheckStatus.good,
    'critical': CheckStatus.critical,
    'warning': CheckStatus.warning,
  };
  //===========================================
  //===========================================

  static ComponentType _parseComponentType(String? str) {
    if (str == null) {
      throw FormatException('ComponentType is required but was null');
    }

    final result = _typeMap[str];

    if (result == null) {
      throw FormatException('Invalid ComponentType: $str');
    }

    return result;
  }

  static ComponentMode _parseComponentMode(String? str) {
    if (str == null) {
      throw const FormatException('ComponentMode is required but was null');
    }
    final result = _modeMap[str];

    if (result == null) {
      throw FormatException('Invalid ComponentMode:$str');
    }

    return result;
  }
}
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

///
extension MaintenanceItemOps on MaintenanceItem {
  ///
  ///
  ///
  /// ```dart
  /// final item = MaintenanceItem(lastMaintenanceAtHour: 1700);
  /// final updated = item.resetInterval(currentHour: 1880);
  /// // updated.lastMaintenanceAtHour == 1880
  /// // updated.latestPreCheckStatus == null
  /// ```
  MaintenanceItem resetInterval({required int currentHour}) {
    return copyWith(
      lastMaintenanceAtHour: currentHour,
      clearLatestPreCheck: true,
    );
  }
}
