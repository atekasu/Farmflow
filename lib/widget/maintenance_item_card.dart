import 'package:flutter/material.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
// import '../model/machine.dart';

import '../model/machine/maintenance_item.dart';
import '../model/machine/maintenance_rules.dart';
import '../model/machine/component_type_extension.dart';

///
class MaintenanceItemCard extends StatelessWidget {
  final MaintenanceItem item;
  final int totalHours;

  const MaintenanceItemCard({
    super.key,
    required this.item,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) {
    const rules = MaintenanceRules();

    final status = item.evaluateStatus(totalHours, rules);

    final progress = _calculateProgress();

    final subtitle = _buildSubtitle();

    final progressColor = _progressColor(progress);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: item.type.color.withOpacity(0.1),
                child: Icon(item.type.icon, color: item.type.color),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.type.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        _buildStatusChip(status),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    if (_hasInterval) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasInterval => item.recommendedIntervalHours != null;

  double _calculateProgress() {
    if (!_hasInterval) return 1.0;

    final interval = item.recommendedIntervalHours!.toDouble();
    final last = (item.lastMaintenanceAtHour ?? 0).toDouble();
    final used = (totalHours - last).toDouble();
    final remain = (interval - used).clamp(0, interval);
    return remain / interval;
  }

  String _buildSubtitle() {
    if (_hasInterval) {
      final interval = item.recommendedIntervalHours!;
      final last = item.lastMaintenanceAtHour ?? 0;
      final used = (totalHours - last);
      final remain = (interval - used).clamp(0, interval);
      return '交換まで残り${remain}h / ${interval}h';
    } else {
      final date = item.lastInspectionDate;
      if (date != null) {
        final y = date.year.toString().padLeft(4, '0');
        final m = date.month.toString().padLeft(2, '0');
        final d = date.day.toString().padLeft(2, '0');
        return '最終点検日: $y-$m-$d';
      } else {
        return '最終点検日: 未記録';
      }
    }
  }

  Color _progressColor(double value) {
    if (value < 0.2) return Colors.red;
    if (value < 0.5) return Colors.yellow;
    return Colors.green;
  }

  Widget _buildStatusChip(EquipmentStatus status) {
    late final Color bg;
    late final String label;

    switch (status) {
      case EquipmentStatus.good:
        bg = Colors.green.shade100;
        label = '良好';
        break;
      case EquipmentStatus.warning:
        bg = Colors.orange.shade100;
        label = '注意';
        break;
      case EquipmentStatus.critical:
        bg = Colors.red.shade100;
        label = '危険';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
