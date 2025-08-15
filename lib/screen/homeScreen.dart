import 'package:flutter/material.dart';
import '../model/machine.dart';
import '../model/machine/equipment.dart';
import '../model/machine/equipment_status.dart';
import '../data/tractor_dummy.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedFilterIndex = 0;
  int selectedNavIndex = 0;

  final List<String> filterLabels = ['全て', '良好', '要確認', '整備必要'];
  final MaintenanceRules rules = const MaintenanceRules();

  // 画像に合わせてダミーデータを拡張
  late List<Machine> machines;

  @override
  void initState() {
    super.initState();
    machines = [
      ...dummyMachines,
      Machine.createTractor(
        id: 'TRACTOR-004',
        name: 'No4',
        modelName: 'SL500',
        totalHours: 1850,
      ),
      Machine.createTractor(
        id: 'TRACTOR-005',
        name: 'No5',
        modelName: 'SL500',
        totalHours: 1850,
      ),
      Machine.createTractor(
        id: 'TRACTOR-006',
        name: 'No6',
        modelName: 'SL550',
        totalHours: 1850,
      ),
      Machine.createTractor(
        id: 'TRACTOR-007',
        name: 'No7',
        modelName: 'MR700',
        totalHours: 1850,
      ),
      Machine.createTractor(
        id: 'TRACTOR-008',
        name: 'No8',
        modelName: 'SL600',
        totalHours: 1850,
      ),
    ];
  }

  List<Machine> get filteredMachines {
    if (selectedFilterIndex == 0) return machines; // 全て
    
    return machines.where((machine) {
      final status = machine.overallStatus(rules);
      switch (selectedFilterIndex) {
        case 1: // 良好
          return status == EquipmentStatus.good;
        case 2: // 要確認
          return status == EquipmentStatus.warning;
        case 3: // 整備必要
          return status == EquipmentStatus.critical;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'トラクター管理',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // フィルターボタン
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: List.generate(filterLabels.length, (index) {
                final isSelected = selectedFilterIndex == index;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < filterLabels.length - 1 ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFilterIndex = index;
                        });
                      },
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFF4A90E2) 
                              : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            filterLabels[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black54,
                              fontSize: 14,
                              fontWeight: isSelected 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // トラクターリスト
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredMachines.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTractorCard(filteredMachines[index]),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedNavIndex,
        onTap: (index) {
          setState(() {
            selectedNavIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '一覧',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'その他',
          ),
        ],
      ),
    );
  }

  Widget _buildTractorCard(Machine machine) {
    final status = machine.overallStatus(rules);
    final statusData = _getStatusData(status);
    
    return GestureDetector(
      onTap: () {
        // 詳細画面への遷移を実装予定
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (context) => MachineDetailScreen(machine: machine),
        // ));
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        return {
          'color': Colors.green,
          'text': '良好',
        };