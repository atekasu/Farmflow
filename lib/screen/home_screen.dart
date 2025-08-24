import 'package:farmflow/screen/machine_detail_screen.dart';
import 'package:flutter/material.dart';
import '../model/machine.dart';
import '../model/machine/maintenance_rules.dart';
import '../model/machine/equipment_status.dart';
import '../data/tractor_dummy.dart';
import '../widget/tractor_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedFilterIndex = 0;
  int selectedNavIndex = 0;

  final List<String> filterLabels = ['全て', '良好', '要確認', '整備必要'];
  final MaintenanceRules rules = const MaintenanceRules();

  List<Machine> get filteredMachines {
    if (selectedFilterIndex == 0) return dummyMachines; // 全て

    return dummyMachines.where((machine) {
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
                          color:
                              isSelected
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
                              fontWeight:
                                  isSelected
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
            child: TractorList(
              machines: filteredMachines,
              onSelect: (machine) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MachineDetailScreen(machine: machine),
                  ),
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
          // ナビゲーション処理はコメントアウト
          // setState(() {
          //   selectedNavIndex = index;
          // });
        },
        selectedItemColor: const Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '一覧'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'その他'),
        ],
      ),
    );
  }
}
