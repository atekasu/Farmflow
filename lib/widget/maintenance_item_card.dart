import 'package:flutter/material.dart';

import '../model/machine.dart';

class maintenanceItemCard extends StatelessWidget {
  final Machine machine;
  const maintenanceItemCard({Key? key, required this.machine})
    : super(key: key);
  @override
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: machine.components.length,
      itemBuilder: (context, index) {
        final item = machine.components[index];
        return Card(child: ListTile(title: Text(item.name)));
      },
    );
  }
}
