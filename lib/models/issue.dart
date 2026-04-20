class Issue {
  final String id;
  final String voucherNo;
  final String poNo;
  final String articleNo;
  final String color;
  final int quantity;
  final String criteria;
  final String date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Issue({
    required this.id,
    required this.voucherNo,
    required this.poNo,
    required this.articleNo,
    required this.color,
    required this.quantity,
    required this.criteria,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory Issue.fromFirestore(String id, Map<String, dynamic> data) {
    return Issue(
      id: id,
      voucherNo: data['voucherNo']?.toString() ?? '',
      poNo: data['poNo']?.toString() ?? '',
      articleNo: data['articleNo']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      criteria: data['criteria']?.toString() ?? 'FG',
      date: data['date']?.toString() ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'voucherNo': voucherNo,
      'poNo': poNo,
      'articleNo': articleNo,
      'color': color,
      'quantity': quantity,
      'criteria': criteria,
      'date': date,
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  Issue copyWith({
    String? voucherNo,
    String? poNo,
    String? articleNo,
    String? color,
    int? quantity,
    String? criteria,
    String? date,
  }) {
    return Issue(
      id: id,
      voucherNo: voucherNo ?? this.voucherNo,
      poNo: poNo ?? this.poNo,
      articleNo: articleNo ?? this.articleNo,
      color: color ?? this.color,
      quantity: quantity ?? this.quantity,
      criteria: criteria ?? this.criteria,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() => 'Issue(id: $id, voucherNo: $voucherNo, poNo: $poNo)';
}
