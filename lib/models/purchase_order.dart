import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseOrderLine {
  final String article;
  final String color;
  final int qty;
  final double unitPrice;
  final double totalValue;

  PurchaseOrderLine({
    required this.article,
    required this.color,
    required this.qty,
    required this.unitPrice,
    required this.totalValue,
  });

  factory PurchaseOrderLine.fromMap(Map<String, dynamic> data) {
    return PurchaseOrderLine(
      article: data['article']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
      qty: (data['qty'] as num?)?.toInt() ?? 0,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalValue: (data['totalValue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'article': article,
      'color': color,
      'qty': qty,
      'unitPrice': unitPrice,
      'totalValue': totalValue,
    };
  }
}

class PurchaseOrder {
  final String id;
  final String poNo;
  final String poDate;
  final String orderBy;
  final String brand;
  final String project;
  final String tag;
  final int totalQuantity;
  final double totalValue;
  final List<PurchaseOrderLine> lines;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PurchaseOrder({
    required this.id,
    required this.poNo,
    required this.poDate,
    required this.orderBy,
    required this.brand,
    required this.project,
    required this.tag,
    required this.totalQuantity,
    required this.totalValue,
    required this.lines,
    this.createdAt,
    this.updatedAt,
  });

  factory PurchaseOrder.fromFirestore(String id, Map<String, dynamic> data) {
    final rawLines = data['lines'] as List<dynamic>? ?? [];
    final lines = rawLines
        .map((l) => PurchaseOrderLine.fromMap(l as Map<String, dynamic>))
        .toList();

    return PurchaseOrder(
      id: id,
      poNo: data['poNo']?.toString() ?? '',
      poDate: data['poDate']?.toString() ?? '',
      orderBy: data['orderBy']?.toString() ?? '',
      brand: data['brand']?.toString() ?? '',
      project: data['project']?.toString() ?? '',
      tag: data['tag']?.toString() ?? '',
      totalQuantity: (data['totalQuantity'] as num?)?.toInt() ?? 0,
      totalValue: (data['totalValue'] as num?)?.toDouble() ?? 0.0,
      lines: lines,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : (data['createdAt'] is String ? DateTime.tryParse(data['createdAt']) : null),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : (data['updatedAt'] is String ? DateTime.tryParse(data['updatedAt']) : null),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'poNo': poNo,
      'poDate': poDate,
      'orderBy': orderBy,
      'brand': brand,
      'project': project,
      'tag': tag,
      'totalQuantity': totalQuantity,
      'totalValue': totalValue,
      'lines': lines.map((l) => l.toMap()).toList(),
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }
}
