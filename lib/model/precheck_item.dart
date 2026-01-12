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
  tractor,
  rotary,
}

enum CheckStatus {
  notChecked,
  good,
  warning,
  critical,
}
