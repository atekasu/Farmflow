import 'package:farmflow/api/machine_api.dart';
import 'package:farmflow/data/tractor_dummy.dart';
import 'package:farmflow/model/machine.dart';
import 'package:farmflow/model/machine/equipment_status.dart';
import 'package:farmflow/model/machine/maintenance_item.dart';
import 'package:farmflow/model/precheck_item.dart';
import 'package:farmflow/model/precheckrecord.dart';

/// 機械データの永続化に関するリポジトリ境界です。
abstract class MachineRepository {
  /// すべての利用可能な機械を返します。
  Future<List<Machine>> fetchAllMachines();

  /// 指定された機械データを保存します（[Machine.id] によるアップサート）。
  Future<void> updateMachine(Machine machine);

  /// 点検記録を保存し、対応する機械の状態を更新します。
  Future<void> savePreCheckRecord(PreCheckRecord record);

  /// 特定のメンテナンス項目に対する作業を記録します。
  /// lastMaintenanceAtHour を [currentHour] に更新し、直近の点検状態をクリアします。
  Future<void> recordMaintenance({
    required String machineId,
    required String itemId,
    required int currentHour,
  });
}

//=============================================
//実装クラス
//==============================================
///
/// 設計思想:
/// -APIが利用可能な場合は常にバックエンドから最新データを取得する
/// -API　障害時はダミーデータにフォールバック（可溶性優先）
/// -インメモリキャッシュを保持し、直のフォールバックに備える
/// ダミーデータを使用したシンプルなインメモリリポジトリです。
class MachineRepositoryImpl implements MachineRepository {
  MachineRepositoryImpl({MachineApi? api, List<Machine>? initial})
    : _api = api,
      _machines = List<Machine>.from(initial ?? dummyMachines);

  /// APIクライアント(nullの場合はダミーデータのみ使用)
  final MachineApi? _api;

  ///インメモリキャッシュ
  ///-API取得成功時:最新データで更新
  ///-API失敗時：前回の成功データを返す（フォールバック）
  ///-API未使用時:ダミーデータを保持
  final List<Machine> _machines;

  ///始業前点検の履歴（デバッグ/テスト目的で保存）
  final List<PreCheckRecord> _preCheckHistory = [];

  ///始業前点検項目とメンテンナンス項目のマッピング
  ///
  ///注意：このマッピングはComponetType　と PreCheckItem.idの対応関係を定義する
  ///新しい点検項目を追加する場合は、ここにも追加が必要
  static const Map<ComponentType, String> _componentToPreCheckId = {
    ComponentType.engineOil: 'engin_oil_check',
    ComponentType.coolant: 'coolant_check',
    ComponentType.grease: 'grease_check',
    ComponentType.airFilter: 'air_filter_check',
    ComponentType.tirePressure: 'tire',
    ComponentType.transmissionOil: 'gir_oil',
  };

  ///==============================================
  ///機械データの取得
  ///===============================================

  @override
  Future<List<Machine>> fetchAllMachines() async {
    //API　が設定されてない場合は、ダミーデータを返す（開発モード）
    if (_api == null) {
      print('📝ダミーデータを使用');
      return List<Machine>.unmodifiable(_machines);
    }
    try {
      print('🌐APIから機械データを取得中...');
      final machines = await _api.fetchMachines();

      print('✅APIからの取得成功: ${machines.length} 台の機械を取得');
      //インメモリキャッシュを最新データで更新
      //理由：次回のAPI失敗時にも、この最新データを返せるようにする
      _machines.clear();
      _machines.addAll(machines);

      return List<Machine>.unmodifiable(machines);
    } catch (e) {
      //API失敗時の安全設計:キャッシュされたデータを返す
      //
      //想定されるエラー:
      //- ネットワーク障害
      //- バックエンド未起動(SocketException)
      //- データフォーマットエラー(Connection refused)
      //-タイムアウト
      print('⚠️APIからの取得失敗: $e');
      print('⚠️ダミーデータにフォールバック');

      return List<Machine>.unmodifiable(_machines);
    }
  }

  //=============================================
  ///機械データの更新
  ///=============================================
  @override
  Future<void> updateMachine(Machine machine) async {
    final index = _machines.indexWhere((m) => m.id == machine.id);
    if (index >= 0) {
      _machines[index] = machine;
    } else {
      _machines.add(machine);
    }

    // TODO:Phase 3で実装予定
    // - APIへPUT/PATHリクエストを送信してバックエンドを更新
    // - 楽観的更新で即座にUIへ反映
  }

  // =============================================
  //始業前点検の記録
  //============================================

  @override
  Future<void> savePreCheckRecord(PreCheckRecord record) async {
    final index = _machines.indexWhere((m) => m.id == record.machineId);
    //大正機械の存在確認
    if (index == -1) {
      throw StateError('Machine ${record.machineId} not found');
    }

    //点検履歴に追加（デバッグ/テスト目的）
    _preCheckHistory.add(record);

    final machine = _machines[index];

    //点検結果を書くメンテナンス項目に反映
    //設計：点検で「異常」が見つかった項目のステータスを更新
    final updatedItems = machine.maintenanceItems
        .map((item) => _applyPreCheck(item, record.result))
        .toList(growable: false);

    //機械データを更新
    _machines[index] = machine.copyWith(
      maintenanceItems: updatedItems,
      lastPreCheck: record,
    );

    //TODO:Phase 3で実装予定
    //-APIへPOSTリクエストを送信してバックエンドを更新
    //-バックエンドで日付別の点検記録を管理
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // メンテナンス実施の記録
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @override
  Future<void> recordMaintenance({
    required String machineId,
    required String itemId,
    required int currentHour,
  }) async {
    //対象の機械の存在確認
    final machineIndex = _machines.indexWhere((m) => m.id == machineId);
    if (machineIndex == -1) {
      throw StateError('Machine $machineId not found');
    }

    final machine = _machines[machineIndex];

    //対象メンテナンス項目の存在確認
    final itemIndex = machine.maintenanceItems.indexWhere(
      (i) => i.id == itemId,
    );
    if (itemIndex == -1) {
      throw StateError('Maintenance item $itemId not found');
    }

    //メンテンナンス実施を記録
    //-lastMaintenanceAtHour を更新する
    //-latestPreCheckStatus をクリア（交換済みなので警告を消す）
    final item = machine.maintenanceItems[itemIndex];
    final updatedItems = item.resetInterval(currentHour: currentHour);

    //機械データを更新
    _machines[machineIndex] = machine.replaceMaintenanceItem(updatedItems);

    //TODO:PASE3で実装
    //-APIへPATCHリクエストを送信してメンテナンス記録を永続化
    //-バックエンドでメンテナンス管理
  }

  //========================
  //内部ヘルパーメソッド
  //========================

  /// 始業前点検の結果をメンテナンス項目に反映する
  ///
  /// ロジック:
  /// 1. ComponentType に対応する点検項目IDを取得
  /// 2. 点検結果が存在し、かつ notChecked 以外なら反映
  /// 3. 該当しない場合は元のアイテムをそのまま返す
  ///
  /// 注意: マッピングに存在しない ComponentType は無視される
  MaintenanceItem _applyPreCheck(
    MaintenanceItem item,
    Map<String, CheckStatus> result,
  ) {
    //ComponentType　に対応する点検項目IDを取得
    final key = _componentToPreCheckId[item.type];
    if (key == null) return item;

    //点検結果を取得
    final status = result[key];
    if (status == null || status == CheckStatus.notChecked) {
      return item;
    }

    //点検結果を反映
    return item.copyWith(latestPreCheckStatus: status);
  }

  /// デバッグやテスト目的で保存された履歴を公開します。
  List<PreCheckRecord> get preCheckHistory =>
      List<PreCheckRecord>.unmodifiable(_preCheckHistory);
}
