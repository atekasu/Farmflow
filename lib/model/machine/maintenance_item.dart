/**
 * MaintenanceItem
 * ----------------
 * 「特定の機体コンポーネント（例: エンジンオイル）」の“計画的メンテナンス状態”を表すモデル。
 *
 * ■ 責務（Single Responsibility）
 * - 時間/日数ベースの規則に基づき、現在の状態（EquipmentStatus）を評価する。
 * - 使用前点検（PreCheck）の最新結果を**読み取り**、時間/日数評価と合成（より深刻な方を採用）。
 *   ※ PreCheckの保存・初期化はRepository等、別レイヤで行う（ここでは書き込まない）。
 *
 * ■ 重要な前提（Invariants）
 * - mode==intervalBased の場合、recommendedIntervalHours は > 0。
 * - lastMaintenanceAtHour は 0 以上（負のアワーメータは不可）。
 * - latestPreCheckStatus は「当日などの最新結果」。null は「まだ記録なし」または「該当項目なし」。
 *
 * ■ 合成ポリシー（Safety First）
 * - final = max(timeBased, preCheck) で“安全側（厳しい側）”に倒す。
 * - notChecked / null はここでは「良」とみなす（未点検の警告は別ロジックで扱う）。
 *
 * ■ 単位（Units）
 * - Hours: int（アワーメータの整数時間）
 * - Days : int（差分日数）
 *
 * ■ よくある落とし穴
 * - latestPreCheckStatus を永続化する設計では、**日またぎのクリア戦略**が必須。
 *   例: アプリ起動時やPreCheck開始時に全項目をクリアする等。
 */
import 'package:farmflow/model/machine/equipment_status.dart';
// Domain enums/status
import 'package:farmflow/model/machine/maintenance_rules.dart';
// Rules for thresholding
import 'package:farmflow/model/precheck_item.dart'; // CheckStatus用
// PreCheck (CheckStatus)

class MaintenanceItem {
  const MaintenanceItem({
    required this.id,
    required this.type,
    required this.name,
    required this.mode,
    this.recommendedIntervalHours,
    this.lastMaintenanceAtHour,
    this.lastInspectionDate,
    this.note,
    this.latestPreCheckStatus, // 追加: 最新の使用前点検結果
  }) : assert(
         mode != ComponentMode.intervalBased ||
             (recommendedIntervalHours ?? 0) > 0,
         'intervalBased なのに recommendedIntervalHours が未設定/0',
       ),
       assert(
         (lastMaintenanceAtHour ?? 0) >= 0,
         'lastMaintenanceAtHour は負にできません',
       );

  final String id;
  final ComponentType type;
  final String name;
  final ComponentMode mode;
  final int? recommendedIntervalHours;
  final int? lastMaintenanceAtHour;
  final DateTime? lastInspectionDate;
  final String? note;

  /// 使用前点検（PreCheck）の**最新結果**。
  /// - `null` : まだ点検していない／該当の点検項目が存在しない
  /// - 値あり : 当日など直近の点検結果
  final CheckStatus? latestPreCheckStatus;

  /// 現在の状態を評価する（時間/日数ベース × PreCheck の合成）
  ///
  /// - 入力:
  ///   - [currentHour] : 現在のアワーメータ（int）
  ///   - [rules]       : しきい値や運用ルール
  ///   - [now]         : テスト用の時間上書き（未指定なら DateTime.now）
  /// - 返り値:
  ///   - より深刻な方を採用（critical > warning > good）
  /// - 注意:
  ///   - 未点検（null/notChecked）はここでは「good」とみなす
  ///   - 「未点検を警告したい」要件は別レイヤ（画面/サービス）で扱う
  EquipmentStatus evaluateStatus(
    int currentHour,
    MaintenanceRules rules, {
    DateTime? now,
  }) {
    final _now = now ?? DateTime.now();

    final timeBasedStatus = _evaluateTimeBasedStatus(currentHour, rules, _now);
    final preCheckStatus = _evaluatePreCheckStatus();

    return _maxStatus(timeBasedStatus, preCheckStatus);
  }

  // ---- 内部判定 ----

  /// 時間/日数ベースのステータス評価（純粋関数的な計算）
  ///
  /// - intervalBased:
  ///   - 使用時間 = currentHour - lastMaintenanceAtHour（負にならないよう 0 で下限）
  ///   - 残り比   = remaining / total を [0,1] にクランプ
  ///   - しきい値: [rules.yellowThreshold], [rules.criticalThreshold] は残り比で判定
  /// - inspectionOnly:
  ///   - 最終点検日が未設定なら warning
  ///   - 経過日数が [rules.inspectionMaxDaysWarning] / [rules.inspectionMaxDaysCritical] を超えたら昇格
  ///
  /// 返り値は EquipmentStatus のいずれか。
  EquipmentStatus _evaluateTimeBasedStatus(
    int currentHour,
    MaintenanceRules rules,
    DateTime now,
  ) {
    switch (mode) {
      case ComponentMode.intervalBased:
        final int total = recommendedIntervalHours ?? 0;
        if (total <= 0) return EquipmentStatus.good;

        // 逆転（lastMaintenanceAtHour > currentHour）でも負にならないよう下限0に丸める
        final int used = (currentHour - (lastMaintenanceAtHour ?? 0)).clamp(
          0,
          0x7fffffff,
        );
        final int remaining = (total - used).clamp(0, total);
        final double remainingRatio = (remaining / total).clamp(0.0, 1.0);

        if (remainingRatio < rules.criticalThreshold) {
          return EquipmentStatus.critical;
        } else if (remainingRatio < rules.yellowThreshold) {
          return EquipmentStatus.warning;
        } else {
          return EquipmentStatus.good;
        }

      case ComponentMode.inspectionOnly:
        final last = lastInspectionDate;
        if (last == null) return EquipmentStatus.warning;
        final int days = _daysSince(last, now);
        if (days >= rules.inspectionMaxDaysCritical) {
          return EquipmentStatus.critical;
        } else if (days >= rules.inspectionMaxDaysWarning) {
          return EquipmentStatus.warning;
        } else {
          return EquipmentStatus.good;
        }
    }
  }

  /// 使用前点検の結果を EquipmentStatus に正規化する
  ///
  /// ポリシー:
  /// - null / notChecked は「ここでは」good とする（重複警告を避ける）
  /// - critical / warning はそのままマッピング
  EquipmentStatus _evaluatePreCheckStatus() {
    final s = latestPreCheckStatus;
    if (s == null) return EquipmentStatus.good;

    switch (s) {
      case CheckStatus.critical:
        return EquipmentStatus.critical;
      case CheckStatus.warning:
        return EquipmentStatus.warning;
      case CheckStatus.good: // good（OK）はそのまま good にマップ
        return EquipmentStatus.good;
      case CheckStatus.notChecked:
        return EquipmentStatus.good;
    }
  }

  /// 将来 enum の並びが変わっても壊れないよう、優先度を明示マップで管理
  static const _severity = {
    EquipmentStatus.good: 0,
    EquipmentStatus.warning: 1,
    EquipmentStatus.critical: 2,
    // unknown を使う設計ならここに -1 等で追加
  };

  /// 2つのステータスのうち、**優先度が高い（深刻）方**を返す
  EquipmentStatus _maxStatus(EquipmentStatus a, EquipmentStatus b) {
    final aa = _severity[a] ?? 0;
    final bb = _severity[b] ?? 0;
    return (aa >= bb) ? a : b;
  }

  // ---- ヘルパ ----

  int _daysSince(DateTime from, DateTime to) => to.difference(from).inDays;

  /// 次回交換までの残り時間（hours）を返す
  /// total が未設定または 0 の場合は 0 を返す
  int remainingHours(int currentHour) {
    final int total = recommendedIntervalHours ?? 0;
    if (total <= 0) return 0;
    final int used = (currentHour - (lastMaintenanceAtHour ?? 0)).clamp(
      0,
      0x7fffffff,
    );
    return (total - used).clamp(0, total);
  }

  /// コピーを生成する。最新PreCheckを **明示的に null にしたい** 場合は
  /// [clearLatestPreCheck] を true にする（引数に null を渡しただけではクリアされない）。
  MaintenanceItem copyWith({
    String? id,
    ComponentType? type,
    String? name,
    ComponentMode? mode,
    int? recommendedIntervalHours,
    int? lastMaintenanceAtHour,
    DateTime? lastInspectionDate,
    String? note,
    CheckStatus? latestPreCheckStatus,
    bool clearLatestPreCheck = false, // ← 追加
  }) {
    return MaintenanceItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      recommendedIntervalHours:
          recommendedIntervalHours ?? this.recommendedIntervalHours,
      lastMaintenanceAtHour:
          lastMaintenanceAtHour ?? this.lastMaintenanceAtHour,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      note: note ?? this.note,
      latestPreCheckStatus:
          clearLatestPreCheck
              ? null
              : (latestPreCheckStatus ?? this.latestPreCheckStatus),
    );
  }
}
