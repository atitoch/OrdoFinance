class ParsedTransaction {
  const ParsedTransaction({
    required this.type,
    required this.amount,
    required this.description,
    this.categoryName,
    this.date,
    this.note,
  });

  final String type; // expense, income, transfer
  final double amount;
  final String description;
  final String? categoryName;
  final DateTime? date;
  final String? note;

  factory ParsedTransaction.fromJson(Map<String, dynamic> json) {
    return ParsedTransaction(
      type: json['type'] as String? ?? 'expense',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: (json['description'] as String? ?? '').substring(
        0,
        ((json['description'] as String? ?? '').length).clamp(0, 80),
      ),
      categoryName: json['categoryName'] as String?,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String)
          : null,
      note: json['note'] as String?,
    );
  }

  /// Lee la respuesta del modelo en cualquiera de las formas que puede tomar:
  /// `{"movements": [...]}`, un array suelto, o un único objeto (que es lo que
  /// devolvía antes de admitir varios movimientos por captura).
  static List<ParsedTransaction> listFromJson(Object? decoded) {
    final raw = switch (decoded) {
      final Map<String, dynamic> map when map['movements'] is List =>
        map['movements'] as List<dynamic>,
      final List<dynamic> list => list,
      final Map<String, dynamic> map => [map],
      _ => const <dynamic>[],
    };

    final items = <ParsedTransaction>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      try {
        items.add(ParsedTransaction.fromJson(Map<String, dynamic>.from(entry)));
      } catch (_) {
        // Una fila ilegible no debe tirar el resto de la captura.
        continue;
      }
    }
    return items;
  }
}
