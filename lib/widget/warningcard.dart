import 'package:farmflow/model/machine/component_type_extension.dart';
import 'package:flutter/material.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/maintenance_item.dart';
import 'package:farmflow/model/machine/warning_message.dart';

class WarningCard extends StatelessWidget {
  final MaintenanceItem item;
  final EquipmentStatus status;
  final int totalHours;

  const WarningCard({
    super.key,
    required this.item,
    required this.status,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(context, status);
    final message = warningMessageFor(
      item: item,
      status: status,
      totalHours: totalHours,
      now: DateTime.now(),
    );

    return Card(
      color: style.bg,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.warning, color: style.icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${item.type.label}：$message',
                style: TextStyle(
                  color: style.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningStyle {
  final Color bg, icon, text;
  const _WarningStyle(this.bg, this.icon, this.text);
}

_WarningStyle _styleFor(BuildContext context, EquipmentStatus status) {
  final cs = Theme.of(context).colorScheme;
  switch (status) {
    case EquipmentStatus.critical:
      return _WarningStyle(
        cs.errorContainer.withValues(alpha: .25),
        cs.error,
        cs.error,
      );
    case EquipmentStatus.warning:
      return _WarningStyle(
        Colors.amber[100]!, //背景色
        Colors.amber[800]!, //アイコン色
        Colors.black, //テキスト色
      );
    default:
      return _WarningStyle(
        cs.surfaceContainer,
        cs.outline,
        cs.onSurfaceVariant,
      );
  }
}
