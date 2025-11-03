import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/machine.dart';
import '../model/machine/maintenance_rules.dart';
import '../application/machine_list_provider.dart';
import '../model/machine/equipment_status.dart';
import '../widget/tractor_list.dart';
import 'machine_detail_screen.dart';

/// アプリケーションのホーム画面（トラクター一覧画面）
///
/// 機能:
/// - 全トラクターの一覧表示
/// - 状態（良好/要確認/危険）によるフィルタリング
/// - トラクターをタップして詳細画面へ遷移
///
/// 設計の特徴:
/// - Riverpodで状態管理を行うため、ConsumerStatefulWidgetを使用
/// - フィルタリングロジックをメソッドとして分離し、テストしやすい設計
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// 現在選択されているフィルター（0: すべて, 1: 良好, 2: 要確認, 3: 危険）
  int selectedFilterIndex = 0;

  /// 将来的なボトムナビゲーション用のインデックス（現在未使用）
  int selectedNavIndex = 0;

  /// フィルターボタンのラベル定義
  /// インデックスとステータスの対応を明確にするため、配列の順序を変更しないこと
  final List<String> filterLabels = ['すべて', '良好', '要確認', '危険'];

  /// メンテナンスルール（ステータス判定に使用）
  /// constインスタンスを使うことでパフォーマンスを最適化
  final MaintenanceRules rules = const MaintenanceRules();

  @override
  Widget build(BuildContext context) {
    final machines = ref.watch(machineListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'トラクター管理',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(machines),
    );
  }

  /// トラクターリストを選択中のフィルターで絞り込む
  ///
  /// フィルタリングロジックをbuildメソッドから分離することで:
  /// - コードの可読性向上
  /// - ユニットテストが容易
  /// - ロジックの再利用が可能
  ///
  /// パラメータ:
  /// - w: フィルタリング前のトラクターリスト
  ///
  /// 戻り値: フィルタリング後のトラクターリスト
  List<Machine> _filterMachine(List<Machine> w) {
    // 「すべて」が選択されている場合は、フィルタリングせずそのまま返す
    if (selectedFilterIndex == 0) {
      return w;
    }

    // 各トラクターの総合ステータスを評価し、選択中のフィルターに一致するものだけを抽出
    return w.where((machines) {
      final status = machines.overallStatus(rules);
      switch (selectedFilterIndex) {
        case 1:
          return status == EquipmentStatus.good;
        case 2:
          return status == EquipmentStatus.warning;
        case 3:
          return status == EquipmentStatus.critical;
        default:
          // 想定外のインデックスの場合は全て表示（防衛的プログラミング）
          return true;
      }
    }).toList();
  }

  /// 画面のボディ部分を構築
  ///
  /// フィルターボタン群とトラクターリストを縦に配置する。
  /// フィルターの状態が変わると、自動的に表示されるリストも更新される。
  Widget _buildBody(List<Machine> machines) {
    final filteredMachines = _filterMachine(machines);
    return Column(
      children: [
        // フィルターボタン群
        // List.generateを使い、filterLabelsの数だけボタンを動的に生成
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: List.generate(filterLabels.length, (index) {
              final isSelected = selectedFilterIndex == index;
              return Expanded(
                child: Padding(
                  // 最後のボタン以外には右側にマージンを追加
                  padding: EdgeInsets.only(
                    right: index < filterLabels.length - 1 ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilterIndex = index;
                      });
                    },
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        // 選択中のボタンは青色、非選択は灰色
                        color:
                            isSelected
                                ? const Color(0xFF4a90e2)
                                : Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          filterLabels[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black54,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // トラクターリスト
        // Expandedで残りのスペースを全て使用し、スクロール可能にする
        Expanded(
          child: TractorList(
            machines: filteredMachines,
            onSelect: (machine) {
              // トラクターが選択されたら詳細画面へ遷移
              // machineオブジェクトではなくIDを渡すことで、
              // 詳細画面で常に最新の状態を取得できる設計
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MachineDetailScreen(machineId: machine.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
