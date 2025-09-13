// lib/data/tractor_dummy.dart
import 'package:farmflow/domain/machine_factory.dart';

final dummyMachines = [
  MachineFactory.createTractor(
    id: 'TRACTOR-001',
    name: 'No1',
    modelName: 'SL54',
    totalHours: 1880,
  ),
  MachineFactory.createTractor(
    id: 'TRACTOR-002',
    name: 'No2',
    modelName: 'MR70',
    totalHours: 1850,
  ),
  MachineFactory.createTractor(
    id: 'TRACTOR-003',
    name: 'No3',
    modelName: 'KL50',
    totalHours: 1700,
  ),
  MachineFactory.createTractor(
    id: 'TRACTOR-004',
    name: 'No4',
    modelName: 'SL500',
    totalHours: 1850,
  ),
  MachineFactory.createTractor(
    id: 'TRACTOR-005',
    name: 'No5',
    modelName: 'SL500',
    totalHours: 1850,
  ),
  MachineFactory.createTractor(
    id: 'TRACTOR-006',
    name: 'No6',
    modelName: 'SL550',
    totalHours: 1850,
  ),
  MachineFactory.createTractor(
    id: 'TRACTOR-007',
    name: 'No7',
    modelName: 'MR700',
    totalHours: 1850,
  ),
  MachineFactory.createTractor(
    id: 'TRACTOR-008',
    name: 'No8',
    modelName: 'SL600',
    totalHours: 1850,
  ),
];
