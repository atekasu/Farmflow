import 'package:flutter/material.dart';

import 'equipment_status.dart';

/// Convenience extensions for displaying ComponentType in the UI.
extension ComponentTypeX on ComponentType {
  /// Human-friendly label (JA)
  String get label {
    switch (this) {
      case ComponentType.engineOil:
        return 'エンジンオイル';
      case ComponentType.coolant:
        return 'クーラント';
      case ComponentType.grease:
        return 'グリス';
      case ComponentType.airFilter:
        return 'エアフィルタ';
      case ComponentType.hydraulicOil:
        return '油圧オイル';
      case ComponentType.fuelFilter:
        return '燃料フィルタ';
      case ComponentType.transmissionOil:
        return 'トランスミッションオイル';
      case ComponentType.tirePressure:
        return 'タイヤ空気圧';
      case ComponentType.brakeWire:
        return 'ブレーキワイヤー';
    }
  }

  /// Representative icon for the component type
  IconData get icon {
    switch (this) {
      case ComponentType.engineOil:
        return Icons.build; // generic maintenance
      case ComponentType.coolant:
        return Icons.opacity; // water drop
      case ComponentType.grease:
        return Icons.build_circle;
      case ComponentType.airFilter:
        return Icons.filter_alt;
      case ComponentType.hydraulicOil:
        return Icons.opacity;
      case ComponentType.fuelFilter:
        return Icons.local_gas_station; // fuel-related
      case ComponentType.transmissionOil:
        return Icons.settings;
      case ComponentType.tirePressure:
        return Icons.speed; // gauge-like
      case ComponentType.brakeWire:
        return Icons.construction;
    }
  }

  /// Color hint that can be used in UI
  Color get color {
    switch (this) {
      case ComponentType.engineOil:
        return Colors.amber.shade700;
      case ComponentType.coolant:
        return Colors.lightBlue;
      case ComponentType.grease:
        return Colors.orange;
      case ComponentType.airFilter:
        return Colors.green;
      case ComponentType.hydraulicOil:
        return Colors.blueGrey;
      case ComponentType.fuelFilter:
        return Colors.deepOrange;
      case ComponentType.transmissionOil:
        return Colors.indigo;
      case ComponentType.tirePressure:
        return Colors.teal;
      case ComponentType.brakeWire:
        return Colors.redAccent;
    }
  }
}
