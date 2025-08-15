enum EquipmentStatus { good, warning, critical }

class MaintenanceRules {
  final double yellowThereshold; //残りの割合がこの値以下の場合はyellow
  const MaintenanceRules({this.yellowThreshold = 0.2});
}

