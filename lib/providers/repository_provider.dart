import 'package:farmflow/api/machine_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmflow/data/machine_repository.dart';
import 'package:farmflow/data/tractor_dummy.dart';

/// MachineRepository をアプリ全体に供給するための DI（依存性注入）ポイント。
///
/// 「なぜこのコードが存在するのか」
///   - 各画面や ViewModel（Notifier）が MachineRepository を直接 new するのを避け、
///     データ取得方法（API / ダミー）を集中的に管理するため。
///
/// 「この Provider が担うこと」
///   1. MachineApi（HTTP クライアント）を生成し Repository に渡す
///   2. 本番 API・ダミーデータの切り替えをここだけで完結できるようにする
///   3. アプリ全体で同一の Repository インスタンスを共有させる
///
/// 「メリット」
///   - UI層がデータ取得の詳細（API の存在や URL）を知らずに済む
///   - テスト時に差し替えが容易（フェイク・モック・ダミー実装）

///API使用フラグ（開発中は切り替えれるように）
const bool _useApi = true;

///Repositoryの依存注入ポイント
final machineRepositoryProvider = Provider<MachineRepository>((ref) {
  //デバックようのログ
  print('🔧repository_provide:_useApi $_useApi');

  if (_useApi) {
    print('🔧repository_provide:AIP経由でデータ取得');
    final api = MachineApi(baseUrl: 'http://127.0.0.1:8000'); //ここでAPIを作る
    return MachineRepositoryImpl(api: api, initial: dummyMachines);
  } else {
    print('🔧repository_provide:ダミーデータのみ使用');
    return MachineRepositoryImpl(api: null, initial: dummyMachines);
  }
});
