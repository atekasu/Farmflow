import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:flutter/material.dart';

import 'package:farmflow/data/tractor_dummy.dart';
import '../model/machine.dart';
import '../model/machine/maintenance_item.dart';

class MaintenanceItemList extends StatelessWidget {
  final Machine machine;
  const MaintenanceItemList({super.key, required this.machine});
  @override
  Widget build(BuildContext context) {
    final total = machine.totalHours;
    return SingleChildScrollView(
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
    // Build subtitle based on the maintenance mode
    late final Widget subtitle;
    switch (item.mode) {
      case ComponentMode.intervalBased:
        final interval = (item.recommendedIntervalHours ?? 0);
        final last = (item.lastMaintenanceAtHour ?? 0);
        final used = (totalHours - last);
        final remaining = (interval - used);
        subtitle = Text(
          '残り時間 ${(remaining).toInt()} 時間 / ${(interval).toInt()} 時間',
        );
        break;
      case ComponentMode.inspectionOnly:
        final lastDate =
            item.lastInspectionDate; // adjust type/formatting as needed
        subtitle = Text(lastDate != null ? '最終検査日: $lastDate' : '最終検査日: 未登録');
        break;
    }
    return Card(
      child: Row(
        children: [
          Icon(Icons.favorite, color: Colors.pink, size: 24.0),
          Padding(padding: const EdgeInsets.all(8.0)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(item.name, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              subtitle,
              // ここにゲージを追加予定
            ],
          ),
        ],
      ),
    );
  }
}
