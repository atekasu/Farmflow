// lib/data/tractor_dummy.dart
import 'package:farmflow/model/machine.dart';
import 'package:farmflow/model/machine/equipment.dart'; // MaintenanceRules
import 'package:farmflow/model/machine/equipment_status.dart'; // enums
import 'package:farmflow/model/machine/maintenance_item.dart'; // MaintenanceItem

final dummyMachines = [
  createTractor(
    id: 'TRACTOR-001',
    name: 'No1',
    modelName: 'SL54',
    totalHours: 1880,
  ),
  createTractor(
    id: 'TRACTOR-002',
    name: 'No2',
    modelName: 'MR70',
    totalHours: 1850,
  ),
  createTractor(
    id: 'TRACTOR-003',
    name: 'No3',
    modelName: 'KL50',
    totalHours: 1700,
  ),
];
