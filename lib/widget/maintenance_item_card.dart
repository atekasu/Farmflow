import 'package:flutter/material.dart';

import '../model/machine.dart';
import '../model/machine/maintenance_item.dart';
import '../model/machine/component_type_extension.dart'; // 追加！

class MaintenanceItemList extends StatelessWidget {
  final Machine machine;
  const MaintenanceItemList({super.key, required this.machine});
  @override
  Widget build(BuildContext context) {
    final total = machine.totalHours;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children:
            machine.maintenanceItems.map((item) {
              return MaintenanceItemCard(item: item, totalHours: total.toInt());
            }).toList(),
      ),
    );
  }
}

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
    final progress = _calculateProgress();
    final progressColor = _progressColor(progress);
    final subtitle = _buildSubtitle();

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
                    Text(
                      item.type.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  // ここからクラス内のメソッド
  bool get _hasInterval => item.recommendedIntervalHours != null;

  // 0.0~1.0(交換時期〜交換まで余裕)
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
      // 点検のみ項目
      final date = item.lastInspectionDate;
      if (date != null) {
        final formatted =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        return '最終点検日: $formatted';
      } else {
        return '最終検査日: 未記録';
      }
    }
  }

  Color _progressColor(double value) {
    if (value < 0.2) return Colors.red;
    if (value < 0.5) return Colors.yellow;
    return Colors.green;
  }
}
