import 'package:uuid/uuid.dart';

/// 全体状態で使う色区分
enum EquipmentStatus { good, warning, critical }

/// しきい値（割合ベース）。
/// - yellowThreshold: この割合以下で Warning（例: 0.2 = 残り20%）
/// - redThreshold   : この割合以下で Critical にしたい場合に設定（デフォは 0.0 = 期限切れのみ赤）
class MaintenanceRules {
  final double yellowThreshold;
  final double redThreshold;
  const MaintenanceRules({this.yellowThreshold = 0.2, this.redThreshold = 0.0});
}

class MaintenanceItem {
  // UUID 生成器（const コンストラクタではないので runtime 生成OK）
  static final Uuid _uuid = const Uuid();

  MaintenanceItem({
    String? id, // 未指定なら自動生成
    required this.name,
    required this.recommendedIntervalHours, // 推奨交換間隔[h]
    this.lastMaintenanceAtHour = 0.0,       // 最終交換時のアワーメータ[h]
    this.notes = '',
  }) : id = id ?? _uuid.v4();

  final String id;               // UUID
  final String name;             // 例: エンジンオイル
  final double recommendedIntervalHours; // 例: 200.0
  final double lastMaintenanceAtHour;    // 例: 120.5
  final String notes;

  /// 現在アワーから見た残り時間[h]
  double remainingHours(double currentHour) {
    final nextAt = lastMaintenanceAtHour + recommendedIntervalHours;
    return nextAt - currentHour;
  }

  /// 現在アワーとルールからステータスを判定
  EquipmentStatus statusAt(
    double currentHour, {
    MaintenanceRules rules = const MaintenanceRules(),
  }) {
    if (recommendedIntervalHours <= 0) return EquipmentStatus.good; // ガード

    final rem = remainingHours(currentHour);

    // 期限切れは即赤
    if (rem <= 0) return EquipmentStatus.critical;

    final ratio = rem / recommendedIntervalHours; // 残り割合(0.0~1.0)

    // 割合ベースでも赤を使いたい場合
    if (rules.redThreshold > 0 && ratio <= rules.redThreshold) {
      return EquipmentStatus.critical;
    }

    if (ratio <= rules.yellowThreshold) return EquipmentStatus.warning;
    return EquipmentStatus.good;
  }

  // Firestore 保存を見据えたシリアライズ
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'recommendedIntervalHours': recommendedIntervalHours,
        'lastMaintenanceAtHour': lastMaintenanceAtHour,
        'notes': notes,
      };

  factory MaintenanceItem.fromJson(Map<String, dynamic> j) => MaintenanceItem(
        id: j['id'] as String?,
        name: j['name'] as String,
        recommendedIntervalHours: (j['recommendedIntervalHours'] as num).toDouble(),
        lastMaintenanceAtHour: (j['lastMaintenanceAtHour'] as num?)?.toDouble() ?? 0.0,
        notes: j['notes'] as String? ?? '',
      );
}
