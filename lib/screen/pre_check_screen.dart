import 'package:farmflow/model/precheckrecord.dart';
import 'package:flutter/material.dart';

import 'package:farmflow/model/precheck_item.dart';
import 'package:farmflow/model/machine.dart';
import 'package:farmflow/data/prechek_items_data.dart';
import 'package:farmflow/widget/pre_chek_item_card.dart';

class PreWorkInspectionScreen extends StatefulWidget {
  final Machine machine;

  const PreWorkInspectionScreen({super.key, required this.machine});

  @override
  State<PreWorkInspectionScreen> createState() => _PreWorkInspectionScreen();
}

class _PreWorkInspectionScreen extends State<PreWorkInspectionScreen> {
  Map<String, CheckStatus> _checkResults = {};
  @override
  void initState() {
    super.initState();
    _checkResults = {
      for (final item in PreCheckItemsData.items)
        item.id: CheckStatus.notChecked,
    };
  }

  void _updateItemStatus(String itemId, CheckStatus status) {
    setState(() {
      _checkResults[itemId] = status;
    });
  }

  void _onCompletePressed() {
    // ここでPreCheckRecordを作る!
    final record = PreCheckRecord(
      machineId: widget.machine.id,
      checkDate: DateTime.now(),
      result: _checkResults,
      totalHoursAtCheck: widget.machine.totalHours.toInt(),
    );
    Navigator.pop(context, record);
  }

  bool get _isAllItemsChecked {
    for (final status in _checkResults.values) {
      if (status == CheckStatus.notChecked) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使用前点検')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: PreCheckItemsData.items.length,
              itemBuilder: (context, index) {
                final item = PreCheckItemsData.items[index];
                return PreCheckItemCard(
                  item: item,
                  currentStatus:
                      _checkResults[item.id] ?? CheckStatus.notChecked,
                  onChanged: (status) => _updateItemStatus(item.id, status),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isAllItemsChecked ? () => _onCompletePressed() : null,
                child: const Text('点検終了'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
