import 'package:flutter/material.dart';

import '../model/machine.dart';

class maintenanceItemCard extends StatelessWidget {
  final List<Machine> machine;
  const maintenanceItemCard({
    Key? key,
    required this.machine,
  }) : super(key: key);

  List<Widget> get _maintenanceItemList{
    return machine.component.map((component){

    })
  }
  @override
  Widget build(BuildContext context){

  }
}
