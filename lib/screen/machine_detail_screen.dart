import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/maintenance_rules.dart';
import 'package:farmflow/widget/warning_section.dart';
import 'package:flutter/material.dart';
import '../model/machine.dart';
import '../widget/maintenance_item_card.dart';

class MachineDetailScreen extends StatefulWidget {
  final Machine machine;
  const MachineDetailScreen({super.key, required this.machine});

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.machine.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            //警告セクション
            WarningSection(machine: widget.machine),

            //警告があれば区切り線を入れる
            _buildDividerIfNeeded('警告'),

            //メンテナンス概要セクション
            _buildSectiontHeader('メンテナンス概要'),
            MaintenanceItemList(machine: widget.machine),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerIfNeeded(String title) {
    //警告項目チェック
    final hasWarnings = widget.machine.maintenanceItems.any((item) {
      final status = item.evaluateStatus(
        widget.machine.totalHours,
        const MaintenanceRules(),
      );
      return status != EquipmentStatus.good;
    });
    return hasWarnings
        ? const Divider(height: 1, color: Colors.grey)
        : const SizedBox.shrink();
  }
}

Widget _buildSectiontHeader(String title) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}
