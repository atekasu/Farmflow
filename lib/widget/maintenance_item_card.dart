import 'package:flutter/material.dart';

import '../model/machine.dart';
import '../model/machine/maintenance_item.dart';

class MaintenanceItemList extends StatelessWidget {
  final Machine machine;
  const MaintenanceItemList({super.key, required this.machine});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children:
            machine.maintenanceItems.map((item) {
              return MaintenanceItemCard(item: item);
            }).toList(),
      ),
    );
  }
}

class MaintenanceItemCard extends StatelessWidget {
  final MaintenanceItem item;

  const MaintenanceItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        children: [
          Icon(Icons.favorite, color: Colors.pink, size: 24.0),
          Padding(padding: const EdgeInsets.all(8.0)),
          Row(children: [Text(item.name, style: TextStyle(fontSize: 16))]),
        ],
      ),
    );
  }
}
