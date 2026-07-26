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
}
