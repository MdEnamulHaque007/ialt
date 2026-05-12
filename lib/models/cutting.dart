class Cutting {
  final String id;
  final String voucherNo;
  final String poNo;
  final String articleNo;
  final String color;
  final int quantity;
  final String date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cutting({
    required this.id,
    required this.voucherNo,
    required this.poNo,
    required this.articleNo,
    required this.color,
    required this.quantity,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory Cutting.fromFirestore(String id, Map<String, dynamic> data) {
    return Cutting(
      id: id,
      voucherNo: data['voucherNo']?.toString() ?? '',
      poNo: data['poNo']?.toString() ?? '',
      articleNo: data['articleNo']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
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
      'date': date,
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'voucherNo': voucherNo,
      'poNo': poNo,
      'articleNo': articleNo,
      'color': color,
      'quantity': quantity,
      'date': date,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Cutting.fromMap(Map<String, dynamic> map) {
    return Cutting(
      id: map['id']?.toString() ?? '',
      voucherNo: map['voucherNo']?.toString() ?? '',
      poNo: map['poNo']?.toString() ?? '',
      articleNo: map['articleNo']?.toString() ?? '',
      color: map['color']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      date: map['date']?.toString() ?? '',
      createdAt: map['createdAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }
}
