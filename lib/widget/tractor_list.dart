import 'package:flutter/material.dart';
import '../model/machine.dart';
import '../model/machine/equipment.dart';
import '../model/machine/equipment_status.dart';

class TractorList extends StatelessWidget {
  final List<Machine> machines;
  final Function(Machine)? onTractorTap;

  const TractorList({super.key, required this.machines, this.onTractorTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: machines.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TractorCard(machine: machines[index], onTap: onTractorTap),
        );
      },
    );
  }
}

class TractorCard extends StatelessWidget {
  final Machine machine;
  final Function(Machine)? onTap;

  const TractorCard({Key? key, required this.machine, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rules = const MaintenanceRules();
    final status = machine.overallStatus(rules);
    final statusData = _getStatusData(status);

    return GestureDetector(
      onTap: () {
        // 画面遷移の処理はコメントアウト
        // if (onTap != null) {
        //   onTap!(machine);
        // }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 上部: 機械名、モデル名、ステータス
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machine.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          machine.modelName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ステータスインジケーター
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusData['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusData['text'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 下部: 走行時間
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '走行時間',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${machine.totalHours.toInt()}h',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusData(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.good:
        return {'color': Colors.green, 'text': '良好'};
      case EquipmentStatus.warning:
        return {'color': Colors.orange, 'text': '要確認'};
      case EquipmentStatus.critical:
        return {'color': Colors.red, 'text': '整備必要'};
    }
  }
}
