import 'package:flutter/material.dart';
import 'package:farmflow/model/machine.dart';
import 'package:farmflow/model/machine/maintenance_item.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/component_type_extension.dart';
import 'package:farmflow/model/prework_inspection.dart';
import 'package:farmflow/repository/inspection_repository.dart';

class PreWorkInspectionscreen extends StatefulWidget {
  const PreWorkInspectionscreen({super.key, required this.machine});
  final Machine machine;

  @override
  State<PreWorkInspectionscreen> createState() => _PreWorkInspectionscreenState();
}

class _PreWorkInspectionscreenState extends State<PreWorkInspectionscreen> {
  late final List<MaintenanceItem> _inspectionItems;
  final Map<String, bool> _okMap = {}; // itemId -> ok
  final Map<String, TextEditingController> _noteCtrls = {}; // itemId -> note ctrl
  final _repo = InMemoryInspectionRepository(); // replace with persistent repo later

  @override
  void initState() {
    super.initState();
    _inspectionItems = widget.machine.maintenanceItems
        .where((e) => e.mode == ComponentMode.inspectionOnly)
        .toList(growable: false);
    for (final item in _inspectionItems) {
      _okMap[item.id] = true; // default to OK
      _noteCtrls[item.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _noteCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.machine.name} 始業前点検'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '点検項目: ${_inspectionItems.length}件',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
                TextButton.icon(
                  onPressed: _markAllOk,
                  icon: const Icon(Icons.done_all),
                  label: const Text('全てOK'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _inspectionItems.length,
              itemBuilder: (context, index) {
                final item = _inspectionItems[index];
                final ok = _okMap[item.id] ?? true;
                final noteCtrl = _noteCtrls[item.id]!;
                return _InspectionItemTile(
                  item: item,
                  ok: ok,
                  noteController: noteCtrl,
                  onChangedOk: (v) => setState(() => _okMap[item.id] = v),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('保存して開始'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _markAllOk() {
    setState(() {
      for (final id in _okMap.keys) {
        _okMap[id] = true;
      }
    });
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final results = _inspectionItems.map((item) {
      final ok = _okMap[item.id] ?? true;
      final note = _noteCtrls[item.id]!.text.trim();
      return PreWorkInspectionItemResult(
        itemId: item.id,
        ok: ok,
        note: note.isEmpty ? null : note,
      );
    }).toList();

    // Save record (in-memory for now)
    final record = PreWorkInspectionRecord(
      machineId: widget.machine.id,
      timestamp: now,
      results: results,
    );
    await _repo.save(record);

    // Update Machine's inspection dates for OK items
    final updatedItems = widget.machine.maintenanceItems.map((m) {
      if (m.mode != ComponentMode.inspectionOnly) return m;
      final res = results.firstWhere((r) => r.itemId == m.id);
      if (res.ok) {
        return m.copyWith(lastInspectionDate: now, note: res.note);
      } else {
        // keep lastInspectionDate; attach note if provided
        return res.note != null ? m.copyWith(note: res.note) : m;
      }
    }).toList();

    final updated = Machine(
      id: widget.machine.id,
      name: widget.machine.name,
      modelName: widget.machine.modelName,
      totalHours: widget.machine.totalHours,
      maintenanceItems: updatedItems,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('点検を保存しました')),
    );

    Navigator.of(context).pop(updated);
  }
}

class _InspectionItemTile extends StatelessWidget {
  const _InspectionItemTile({
    required this.item,
    required this.ok,
    required this.noteController,
    required this.onChangedOk,
  });

  final MaintenanceItem item;
  final bool ok;
  final TextEditingController noteController;
  final ValueChanged<bool> onChangedOk;

  @override
  Widget build(BuildContext context) {
    final subtitle = _buildSubtitle(item);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: item.type.color.withOpacity(0.12),
                  child: Icon(item.type.icon, color: item.type.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.type.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: ok,
                  onChanged: onChangedOk,
                  activeColor: Colors.green,
                ),
                Text(
                  ok ? 'OK' : '注意',
                  style: TextStyle(
                    color: ok ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '備考・気づき(任意)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(MaintenanceItem item) {
    final last = item.lastInspectionDate;
    if (last == null) return '最終点検日: 未記録';
    final formatted =
        '${last.year}-${last.month.toString().padLeft(2, '0')}-${last.day.toString().padLeft(2, '0')}';
    return '最終点検日: $formatted';
  }
}
