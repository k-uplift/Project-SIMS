class OcrDraftItem {
  String name;
  String category;
  String quantity;

  OcrDraftItem({
    required this.name,
    required this.category,
    required this.quantity,
  });

  int get count {
    return int.tryParse(quantity.trim()) ?? 1;
  }

  factory OcrDraftItem.fromJson(Map<String, dynamic> json) {
    final rawQuantity = json['quantity'];

    return OcrDraftItem(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '기타',
      quantity: rawQuantity == null ? '1' : rawQuantity.toString(),
    );
  }
}

class OcrResult {
  final String sourceKind;
  final List<OcrDraftItem> items;
  final String model;

  const OcrResult({
    required this.sourceKind,
    required this.items,
    required this.model,
  });

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];

    return OcrResult(
      sourceKind: json['source_kind'] as String? ?? '',
      items: rawItems
          .map((item) => OcrDraftItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      model: json['model'] as String? ?? '',
    );
  }
}
