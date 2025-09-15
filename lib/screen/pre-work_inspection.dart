import 'package:flutter/material.dart';
import 'package:farmflow/model/machine.dart';

class PreWorkInspectionScreen extends StatelessWidget {
  const PreWorkInspectionScreen({super.key, required this.machine});
  final Machine machine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(machine.name)));
  }
}
