class PreCheckItem {
  const PreCheckItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
  });

  final String id;
  final String name;
  final String description;
  final PreCheckCategory category;

  PreCheckItem copyWith({
    String? id,
    String? name,
    String? description,
    PreCheckCategory? category,
  }) {
    return PreCheckItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }
}

enum PreCheckCategory {
  tractor, //トラクター
  rotary, //ロータリー
}

enum CheckStatus {
  notChecked, //未選択
  good, //問題なし
  warning, //注意
  critical, //破損、交換
}
