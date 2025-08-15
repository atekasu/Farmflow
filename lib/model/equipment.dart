import 'package:uuid/uuid.dart';
import 'maintenance_item.dart';

abstract class Equipment {
  static final Uuid _uuid = const Uuid();
  Equipment({
    String? id,
    required this.modelName,
    required this.hourMeter,
    required this.maintenanceItems,
  }) : id = id ?? _uuid.v4();
  final String id;
  final String modelName; // 機械のモデル名
  final double hourMeter; // アワーメーターの値（例: 120.5 = 120時間30分）
  final List<MaintenanceItem> maintenanceItems;
}
