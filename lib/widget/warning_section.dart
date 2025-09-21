import 'package:flutter/material.dart';

import '../model/machine.dart';
import '../model/machine/maintenance_item.dart';
import '../model/machine/equipment_status.dart';
import '../model/machine/maintenance_rules.dart';
import '../widget/warningcard.dart';

class WarningSection extends StatelessWidget {
  final Machine machine;
  const WarningSection({super.key, required this.machine});

  @override
  Widget build(BuildContext context) {
    final rules = const MaintenanceRules();

    final warningItemsWithStatus =
        machine.maintenanceItems
            .map(
              (item) => _ItemWithStatus(
                item: item,
                status: item.evaluateStatus(machine.totalHours, rules),
              ),
            )
            .where((pair) => pair.status != EquipmentStatus.good)
            .toList();
    if (warningItemsWithStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '注意事項',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        ...warningItemsWithStatus.map((pair) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: WarningCard(
              key: ValueKey(pair.item.id),
              item: pair.item,
              status: pair.status,
              totalHours: machine.totalHours.toInt(),
            ),
          );
        }),
      ],
    );
  }
}

class _ItemWithStatus {
  final MaintenanceItem item;
  final EquipmentStatus status;

  _ItemWithStatus({required this.item, required this.status});
}
