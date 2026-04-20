import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_report.dart';

class StockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<StockReport>> generateReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final fromTimestamp = Timestamp.fromDate(fromDate);
    final toTimestamp = Timestamp.fromDate(toDate.add(const Duration(days: 1)));

    // ৩টি collection থেকে data load
    final results = await Future.wait([
      _firestore.collection('purchase_order').get(),
      _firestore
          .collection('issue')
          .where('date', isGreaterThanOrEqualTo: fromTimestamp)
          .where('date', isLessThan: toTimestamp)
          .get(),
      _firestore
          .collection('export')
          .where('date', isGreaterThanOrEqualTo: fromTimestamp)
          .where('date', isLessThan: toTimestamp)
          .get(),
    ]);

    final purchaseOrders = results[0].docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
    final issues = results[1].docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
    final exports = results[2].docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    final Map<String, Map<String, dynamic>> stockMap = {};

    // 1. Opening = Purchase Order qty
    for (final po in purchaseOrders) {
      final lines = po['lines'] as List<dynamic>? ?? [];
      for (final line in lines) {
        if (line is Map<String, dynamic>) {
          final poNo = po['poNo']?.toString() ?? '';
          final articleNo = line['article']?.toString() ?? '';
          final color = line['color']?.toString() ?? '';
          final qty = (double.tryParse(line['qty']?.toString() ?? '0') ?? 0.0);
          final key = '$poNo|$articleNo|$color';
          stockMap.putIfAbsent(
            key,
            () => {
              'poNo': poNo,
              'articleNo': articleNo,
              'color': color,
              'opening': 0.0,
              'issue': 0.0,
              'export': 0.0,
            },
          );
          stockMap[key]!['opening'] =
              (stockMap[key]!['opening'] as double) + qty;
        }
      }
    }

    // 2. Issue = FG declared qty (যোগ হবে)
    for (final issue in issues) {
      final poNo = issue['poNo']?.toString() ?? '';
      final articleNo = issue['articleNo']?.toString() ?? '';
      final color = issue['color']?.toString() ?? '';
      final qty =
          (double.tryParse(issue['quantity']?.toString() ?? '0') ?? 0.0);
      final key = '$poNo|$articleNo|$color';
      stockMap.putIfAbsent(
        key,
        () => {
          'poNo': poNo,
          'articleNo': articleNo,
          'color': color,
          'opening': 0.0,
          'issue': 0.0,
          'export': 0.0,
        },
      );
      stockMap[key]!['issue'] = (stockMap[key]!['issue'] as double) + qty;
    }

    // 3. Export = বিয়োগ হবে
    for (final exp in exports) {
      final poNo = exp['poNo']?.toString() ?? '';
      final articleNo = exp['articleNo']?.toString() ?? '';
      final color = exp['color']?.toString() ?? '';
      final qty = (double.tryParse(exp['quantity']?.toString() ?? '0') ?? 0.0);
      final key = '$poNo|$articleNo|$color';
      stockMap.putIfAbsent(
        key,
        () => {
          'poNo': poNo,
          'articleNo': articleNo,
          'color': color,
          'opening': 0.0,
          'issue': 0.0,
          'export': 0.0,
        },
      );
      stockMap[key]!['export'] = (stockMap[key]!['export'] as double) + qty;
    }

    // 4. StockReport list তৈরি করুন
    return stockMap.entries.map((entry) {
      final item = entry.value;
      return StockReport.calculate(
        poNo: item['poNo'] as String,
        articleNo: item['articleNo'] as String,
        color: item['color'] as String,
        opening: item['opening'] as double,
        issue: item['issue'] as double,
        export: item['export'] as double,
      );
    }).toList();
  }
}
