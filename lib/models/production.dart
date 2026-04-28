class Production {
  final String id;
  final String poNo;
  final String articleNo;
  final String color;
  final int qty;
  final String date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Production({
    required this.id,
    required this.poNo,
    required this.articleNo,
    required this.color,
    required this.qty,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory Production.fromFirestore(String id, Map<String, dynamic> data) {
    return Production(
      id: id,
      poNo: data['poNo']?.toString() ?? '',
      articleNo: data['articleNo']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
      qty: (data['qty'] as num?)?.toInt() ?? 0,
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
      'poNo': poNo,
      'articleNo': articleNo,
      'color': color,
      'qty': qty,
      'date': date,
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  Production copyWith({
    String? poNo,
    String? articleNo,
    String? color,
    int? qty,
    String? date,
  }) {
    return Production(
      id: id,
      poNo: poNo ?? this.poNo,
      articleNo: articleNo ?? this.articleNo,
      color: color ?? this.color,
      qty: qty ?? this.qty,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() =>
      'Production(id: $id, poNo: $poNo, articleNo: $articleNo)';
}
