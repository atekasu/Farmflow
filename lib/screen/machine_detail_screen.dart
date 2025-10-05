import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/maintenance_rules.dart';
import 'package:farmflow/screen/pre_check_screen.dart';
import 'package:farmflow/widget/warning_section.dart';
import 'package:flutter/material.dart';
import '../model/machine.dart';
import '../widget/maintenance_item_card.dart';
import '../model/precheckrecord.dart';
import '../model/precheck_item.dart';

class MachineDetailScreen extends StatefulWidget {
  final Machine machine;
  const MachineDetailScreen({super.key, required this.machine});

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  late Machine _machine;
  @override
  void initState() {
    super.initState();
    _machine = widget.machine;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          _machine.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_machine.lastPreCheck != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  '要点検 ${_machine.lastPreCheck!.result.values.where((s) => s == CheckStatus.warning || s == CheckStatus.critical).length}件',
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () async {
                final record = await Navigator.push<PreCheckRecord>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PreWorkInspectionScreen(machine: _machine),
                  ),
                );
                if (record != null) {
                  setState(() {
                    _machine = _machine.copyWith(lastPreCheck: record);
                  });
                }
              },
              label: Text(
                '使用開始',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              icon: Icon(Icons.play_arrow, color: Colors.white, size: 28),
            ),
          ),
        ],
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            //警告セクション
            WarningSection(machine: _machine),
            Padding(padding: const EdgeInsets.all(16.0)),
            //警告があれば区切り線を入れる
            _buildDividerIfNeeded(),

            //メンテナンス概要セクション
            _buildSectiontHeader('メンテナンス概要'),
            MaintenanceItemList(machine: _machine),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerIfNeeded() {
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
