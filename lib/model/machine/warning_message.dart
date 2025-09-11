import 'package:flutter/material.dart';

import '../../model/machine/equipment_status.dart';
import '../../model/machine/maintenance_item.dart';

String warningMessageFor({
  required MaintenanceItem item,
  required EquipmentStatus status,
  required int totalHours,
  required DateTime now,
}) {
  switch (item.mode) {
    case ComponentMode.intervalBased:
      final interval = item.recommendedIntervalHours!;
      final last = item.lastMaintenanceAtHour ?? 0;
      final used = (totalHours - last).clamp(0, interval);
      final remain = (interval - used).clamp(0, interval);
      return status == EquipmentStatus.critical
          ? '交換時期です。残り${remain}h'
          : '交換が近づいています。残り${remain}h';
    case ComponentMode.inspectionOnly:
      final date = item.lastInspectionDate;
      if (date == null) return '点検記録がありません';
      final days = now.difference(date).inDays;
      return status == EquipmentStatus.critical
          ? '点検時期です。前回点検から${days}日'
          : '点検が近づいています。前回点検から${days}日';
  }
}
