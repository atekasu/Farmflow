import 'package:flutter/material.dart';

import '../model/machine.dart';

class MaintenanceItemCard extends StatelessWidget {
  final Machine machine;
  const MaintenanceItemCard({super.key, required this.machine});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: machine.maintenanceItems.length,
      itemBuilder: (context, index) {
        final item = machine.maintenanceItems[index];
        return Card(child: ListTile(title: Text(item.name)));
      },
    );
  }
}
