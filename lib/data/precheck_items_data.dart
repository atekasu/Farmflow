import 'package:farmflow/model/precheck_item.dart';

class PreCheckItemsData {
  static const List<PreCheckItem> items = [
    PreCheckItem(
      id: 'engin_oil_check',
      name: 'エンジンオイル',
      description: 'レベルゲージの確認',
      category: PreCheckCategory.tractor,
    ),
    PreCheckItem(
      id: 'coolant_check',
      name: 'クーラント',
      description: 'リザーバータンクの確認',
      category: PreCheckCategory.tractor,
    ),
    PreCheckItem(
      id: 'grease_check',
      name: 'グリス',
      description: 'グリスポイントの確認',
      category: PreCheckCategory.tractor,
    ),
    PreCheckItem(
      id: 'air_filter_check',
      name: 'エアフィルター',
      description: 'エレメントの汚れの確認、交換の有無',
      category: PreCheckCategory.tractor,
    ),
    PreCheckItem(
      id: 'tire',
      name: 'タイヤ',
      description: '空気圧と摩耗具合の確認',
      category: PreCheckCategory.tractor,
    ),

    PreCheckItem(
      id: 'chain_cover',
      name: 'チェーンカバー',
      description: '摩耗具合の点検',
      category: PreCheckCategory.rotary,
    ),
    PreCheckItem(
      id: 'gir_oil',
      name: 'ギアオイル',
      description: '残量点検 ',
      category: PreCheckCategory.rotary,
    ),
    PreCheckItem(
      id: 'tilling_claw',
      name: '耕うん爪',
      description: '緩み、摩耗具合の点検',
      category: PreCheckCategory.rotary,
    ),
  ];
}
