import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/machine.dart';
import '../model/machine/maintenance_rules.dart';
import '../application/machine_list_provider.dart';
import '../model/machine/equipment_status.dart';
import '../widget/tractor_list.dart';
import 'machine_detail_screen.dart';

///
///
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int selectedFilterIndex = 0;

  int selectedNavIndex = 0;

  final List<String> filterLabels = ['すべて', '良好', '要確認', '危険'];

  final MaintenanceRules rules = const MaintenanceRules();

  @override
  Widget build(BuildContext context) {
    final machines = ref.watch(machineListProvider);

    return Scaffold(
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
      body: _buildBody(machines),
    );
  }

  ///
  ///
  ///
  List<Machine> _filterMachine(List<Machine> w) {
    if (selectedFilterIndex == 0) {
      return w;
    }

    return w.where((machines) {
      final status = machines.overallStatus(rules);
      switch (selectedFilterIndex) {
        case 1:
          return status == EquipmentStatus.good;
        case 2:
          return status == EquipmentStatus.warning;
        case 3:
          return status == EquipmentStatus.critical;
        default:
          return true;
      }
    }).toList();
  }

  ///
  Widget _buildBody(List<Machine> machines) {
    final filteredMachines = _filterMachine(machines);
    return Column(
      children: [
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
                                ? const Color(0xFF4a90e2)
                                : Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          filterLabels[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black54,
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
        Expanded(
          child: TractorList(
            machines: filteredMachines,
            onSelect: (machine) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MachineDetailScreen(machineId: machine.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
