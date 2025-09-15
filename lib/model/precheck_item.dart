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
}

enum PreCheckCategory { tractor, rotary }
