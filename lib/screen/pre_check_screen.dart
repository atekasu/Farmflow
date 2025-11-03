import 'package:farmflow/model/precheckrecord.dart';
import 'package:flutter/material.dart';

import 'package:farmflow/model/precheck_item.dart';
import 'package:farmflow/model/machine.dart';
import 'package:farmflow/data/prechek_items_data.dart';
import 'package:farmflow/widget/pre_chek_item_card.dart';

/// 農機の使用前点検を行う画面
///
/// 点検項目ごとに正常/警告/危険のステータスを記録し、
/// 全項目がチェック済みになったら点検記録を作成して呼び出し元に返す。
///
/// 設計意図:
/// - 点検の完了状態は Navigator.pop で PreCheckRecord として返すことで、
///   呼び出し元が状態管理を行う責務分離を実現している
class PreWorkInspectionScreen extends StatefulWidget {
  /// 点検対象の農機
  final Machine machine;

  const PreWorkInspectionScreen({super.key, required this.machine});

  @override
  State<PreWorkInspectionScreen> createState() => _PreWorkInspectionScreen();
}

class _PreWorkInspectionScreen extends State<PreWorkInspectionScreen> {
  /// 各点検項目のチェック状態を保持するマップ
  /// key: 点検項目ID, value: チェック状態（未チェック/正常/警告/危険）
  Map<String, CheckStatus> _checkResults = {};

  @override
  void initState() {
    super.initState();
    // 全ての点検項目を「未チェック」状態で初期化
    // ユーザーが明示的に全項目をチェックする必要があるため、
    // デフォルトで「正常」にはしない設計
    _checkResults = {
      for (final item in PreCheckItemsData.items)
        item.id: CheckStatus.notChecked,
    };
  }

  /// 点検項目のステータスを更新する
  ///
  /// 子Widgetからのコールバックとして使用される。
  /// setStateを呼ぶことで、UIに変更を反映し、
  /// 全項目チェック済みかどうかの判定も更新される。
  void _updateItemStatus(String itemId, CheckStatus status) {
    setState(() {
      _checkResults[itemId] = status;
    });
  }

  /// 点検完了ボタンが押された時の処理
  ///
  /// 重要: Navigator.popで点検記録を返すことで、
  /// この画面は状態の永続化を行わず、呼び出し元に責務を委譲している。
  /// これにより、画面の責務を「点検の入力」のみに限定している。
  void _onCompletePressed() {
    // 点検記録を作成（チェック時点のアワー値も記録）
    final record = PreCheckRecord(
      machineId: widget.machine.id,
      checkDate: DateTime.now(),
      result: _checkResults,
      totalHoursAtCheck: widget.machine.totalHours.toInt(),
    );
    // 点検記録を呼び出し元に返して画面を閉じる
    Navigator.pop(context, record);
  }

  /// 全ての点検項目がチェック済みかどうかを判定
  ///
  /// 「未チェック」の項目が1つでもあればfalseを返す。
  /// この判定結果によって、点検完了ボタンの有効/無効が切り替わる。
  ///
  /// 注意: 正常/警告/危険のどれであってもチェック済みとみなす。
  /// これにより、ユーザーは問題がある項目も認識した上で点検を完了できる。
  bool get _isAllItemsChecked {
    for (final status in _checkResults.values) {
      if (status == CheckStatus.notChecked) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使用前点検')),
      body: Column(
        children: [
          // 点検項目リスト
          // スクロール可能な領域として展開し、項目数に応じて動的に表示
          Expanded(
            child: ListView.builder(
              itemCount: PreCheckItemsData.items.length,
              itemBuilder: (context, index) {
                final item = PreCheckItemsData.items[index];
                return PreCheckItemCard(
                  item: item,
                  currentStatus:
                      _checkResults[item.id] ?? CheckStatus.notChecked,
                  onChanged: (status) => _updateItemStatus(item.id, status),
                );
              },
            ),
          ),
          // 点検完了ボタン
          // 全項目チェック済みの時だけ有効化される（onPressedにnullを渡すと無効化）
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isAllItemsChecked ? () => _onCompletePressed() : null,
                child: const Text('点検終了'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
