import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:farmflow/model/precheck_item.dart';

class PreCheckItemCard extends StatelessWidget {
  final PreCheckItem item;
  final CheckStatus currentStatus;
  final ValueChanged<CheckStatus> onChanged;
  const PreCheckItemCard({
    super.key,
    required this.item,
    required this.currentStatus,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(item.description),
            SizedBox(height: 12),

            _buildSegmentedButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedButton() {
    return SegmentedButton<CheckStatus>(
      segments: const <ButtonSegment<CheckStatus>>[
        ButtonSegment<CheckStatus>(
          value: CheckStatus.good,
          label: Text('問題なし'),
          icon: Icon(Icons.check_circle),
        ),
        ButtonSegment<CheckStatus>(
          value: CheckStatus.warning,
          label: Text('注意'),
          icon: Icon(Icons.warning),
        ),
        ButtonSegment<CheckStatus>(
          value: CheckStatus.critical,
          label: Text('要修理'),
          icon: Icon(Icons.error),
        ),
      ],
      selected: {currentStatus},
      onSelectionChanged: (Set<CheckStatus> selected) {
        onChanged(selected.first);
      },
    );
  }
}
