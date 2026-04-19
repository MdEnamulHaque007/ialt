import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';

// Stock Report পেজ - From-To তারিখের মধ্যে স্টক হিসাব দেখানোর জন্য
class StockReport extends StatefulWidget {
  const StockReport({super.key});

  @override
  State<StockReport> createState() => _StockReportState();
}

// স্টেট ক্লাস - সব লজিক এখানে
class _StockReportState extends State<StockReport> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance; // Firestore connection

  DateTime? _fromDate; // শুরুর তারিখ
  DateTime? _toDate; // শেষ তারিখ

  List<Map<String, dynamic>> _stockItems = []; // স্টক লিস্ট
  bool _isLoading = false; // লোডিং indicator

  // From তারিখ সিলেক্ট করা
  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
        _toDate = null;
      });
    }
  }

  // To তারিখ সিলেক্ট করা
  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _toDate) {
      setState(() => _toDate = picked);
    }
  }

  // রিপোর্ট জেনারেট করা - মূল কাজ
  Future<void> _generateStockReport() async {
    if (_fromDate == null || _toDate == null) return;
    setState(() => _isLoading = true);

    try {
      final Timestamp fromTimestamp = Timestamp.fromDate(_fromDate!);
      final Timestamp toTimestamp = Timestamp.fromDate(
        _toDate!.add(const Duration(days: 1)),
      );

      // ৪টি কালেকশন থেকে ডেটা লোড
      final results = await Future.wait([
        firestore
            .collection('purchase_order')
            .get(), // Opening (purchase_order)
        firestore
            .collection('Production')
            .where(
              'date',
              isGreaterThanOrEqualTo: fromTimestamp,
              isLessThan: toTimestamp,
            )
            .get(),
        firestore
            .collection('issue')
            .where(
              'date',
              isGreaterThanOrEqualTo: fromTimestamp,
              isLessThan: toTimestamp,
            )
            .get(),
        firestore
            .collection('export')
            .where(
              'date',
              isGreaterThanOrEqualTo: fromTimestamp,
              isLessThan: toTimestamp,
            )
            .get(),
      ]);

      final List<Map<String, dynamic>> purchaseOrders = results[0].docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      final List<Map<String, dynamic>> issues = results[2].docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      final List<Map<String, dynamic>> exports = results[3].docs
          .map(
            (doc) => {'id': doc.id, ...Map<String, dynamic>.from(doc.data())},
          )
          .toList();

      // Stock হিসাবের জন্য map তৈরি - key: "PO|Article|Color"
      final Map<String, Map<String, dynamic>> stockMap = {};

      // ১. Purchase Order - Opening Stock
      for (final po in purchaseOrders) {
        final lines = po['lines'] as List<dynamic>? ?? [];
        for (final line in lines) {
          if (line is Map<String, dynamic>) {
            final poNo = po['poNo']?.toString() ?? '';
            final articleNo = line['article']?.toString() ?? '';
            final color = line['color']?.toString() ?? '';
            final qty =
                (double.tryParse(line['qty']?.toString() ?? '0') ?? 0.0);

            final key = '$poNo|$articleNo|$color';
            stockMap.putIfAbsent(
              key,
              () => {
                'poNo': poNo,
                'articleNo': articleNo,
                'color': color,
                'opening': 0.0,
                'production': 0.0,
                'issue': 0.0,
                'export': 0.0,
                'closing': 0.0,
              },
            );
            stockMap[key]!['opening'] =
                (stockMap[key]!['opening'] as double) + qty;
          }
        }
      }

      // ৩. Issue (Received) - স্টকে যোগ
      for (final issue in issues) {
        final delivery = issue['deliveryCriteria']?.toString() ?? '';
        final poNo = issue['poNo']?.toString() ?? '';
        final articleNo = issue['articleNo']?.toString() ?? '';
        final color = issue['color']?.toString() ?? '';
        final qty =
            (double.tryParse(issue['quantity']?.toString() ?? '0') ?? 0.0);

        final key = '$poNo|$articleNo|$color|$delivery';
        stockMap.putIfAbsent(
          key,
          () => {
            'poNo': poNo,
            'articleNo': articleNo,
            'color': color,
            'deliveryCriteria': delivery,
            'opening': 0.0,
            'production': 0.0,
            'issue': 0.0,
            'export': 0.0,
            'closing': 0.0,
          },
        );
        stockMap[key]!['issue'] = (stockMap[key]!['issue'] as double) + qty;
      }

      // ৪. Export - স্টক থেকে বিয়োগ
      for (final exp in exports) {
        final poNo = exp['poNo']?.toString() ?? '';
        final articleNo = exp['articleNo']?.toString() ?? '';
        final color = exp['color']?.toString() ?? '';
        final qty =
            (double.tryParse(exp['quantity']?.toString() ?? '0') ?? 0.0);

        final key = '$poNo|$articleNo|$color';
        stockMap.putIfAbsent(
          key,
          () => {
            'poNo': poNo,
            'articleNo': articleNo,
            'color': color,
            'opening': 0.0,
            'production': 0.0,
            'issue': 0.0,
            'export': 0.0,
            'closing': 0.0,
          },
        );
        stockMap[key]!['export'] = (stockMap[key]!['export'] as double) + qty;
      }

      // ৫. Closing Stock হিসাব - Opening + Production - Issue - Export
      final List<Map<String, dynamic>> stockList = [];
      for (final entry in stockMap.entries) {
        final item = entry.value;
        final closing = item['opening']! - item['issue']! - item['export']!;
        stockList.add({
          'poNo': item['poNo'],
          'articleNo': item['articleNo'],
          'color': item['color'],
          'opening': item['opening'],
          'production': item['production'],
          'issue': item['issue'],
          'export': item['export'],
          'closing': closing,
        });
      }

      setState(() {
        _stockItems = stockList;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('রিপোর্ট তৈরিতে সমস্যা: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Report')), // উপরের বার
      body: Padding(
        padding: const EdgeInsets.all(16.0), // প্যাডিং সবদিকে ১৬
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // বামে সারি
          children: [
            // তারিখ সিলেক্ট রো
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From Date:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ), // লেবেল
                      const SizedBox(height: 8),
                      GestureDetector(
                        // ক্লিকযোগ্য বক্স
                        onTap: () => _selectFromDate(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _fromDate == null
                                      ? 'শুরুর তারিখ নির্বাচন করুন'
                                      : DateFormat(
                                          'dd-MMM-yyyy',
                                        ).format(_fromDate!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16), // গ্যাপ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'To Date:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectToDate(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _toDate == null
                                      ? 'শেষ তারিখ নির্বাচন করুন'
                                      : DateFormat(
                                          'dd-MMM-yyyy',
                                        ).format(_toDate!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              // জেনারেট বাটন
              onPressed: _fromDate != null && _toDate != null
                  ? _generateStockReport
                  : null,
              icon: const Icon(Icons.calculate),
              label: const Text('রিপোর্ট তৈরি করুন'),
            ),
            const SizedBox(height: 24),
            Expanded(
              // টেবিল অংশ
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    ) // লোডিং স্পিনার
                  : _stockItems.isEmpty
                  ? const Center(
                      child: Text('তারিখ নির্বাচন করে রিপোর্ট তৈরি করুন'),
                    )
                  : DataTable2(
                      // ডেটা টেবিল
                      columnSpacing: 12, // কলামের মধ্যে গ্যাপ
                      horizontalMargin: 12, // পাশের মার্জিন
                      minWidth: 1200, // ন্যূনতম প্রস্থ
                      dataRowHeight: 50.0, // রো উচ্চতা
                      headingRowHeight: 56.0, // হেডার উচ্চতা
                      headingRowColor: WidgetStateProperty.all(
                        Colors.green.shade50,
                      ), // হেডার রঙ
                      columns: [
                        // কলাম সংজ্ঞা
                        const DataColumn2(
                          label: Text('PO No'),
                          size: ColumnSize.L,
                        ), // PO কলাম
                        const DataColumn2(
                          label: Text('Article No'),
                          size: ColumnSize.L,
                        ), // আর্টিকেল
                        const DataColumn2(
                          label: Text('Color'),
                          size: ColumnSize.L,
                        ), // কালার
                        const DataColumn2(
                          label: Text('Opening'),
                          size: ColumnSize.M,
                          numeric: true,
                        ), // শুরুর স্টক

                        const DataColumn2(
                          label: Text('Issue'),
                          size: ColumnSize.M,
                          numeric: true,
                        ), // ইস্যু
                        const DataColumn2(
                          label: Text('Export'),
                          size: ColumnSize.M,
                          numeric: true,
                        ), // এক্সপোর্ট
                        const DataColumn2(
                          label: Text('Closing'),
                          size: ColumnSize.M,
                          numeric: true,
                        ), // চূড়ান্ত
                      ],
                      rows: List.generate(_stockItems.length, (index) {
                        // প্রতিটি রো তৈরি
                        final item = _stockItems[index];
                        return DataRow(
                          cells: [
                            DataCell(Text(item['poNo'] ?? '')), // PO No
                            DataCell(Text(item['articleNo'] ?? '')), // Article
                            DataCell(Text(item['color'] ?? '')), // Color
                            DataCell(
                              Text(
                                '${item['opening']?.toStringAsFixed(2) ?? '0.00'}',
                              ),
                            ), // Opening

                            DataCell(
                              Text(
                                '${item['issue']?.toStringAsFixed(2) ?? '0.00'}',
                              ),
                            ), // Issue
                            DataCell(
                              Text(
                                '${item['export']?.toStringAsFixed(2) ?? '0.00'}',
                              ),
                            ), // Export
                            DataCell(
                              // Closing - রঙিন সেল
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: (item['closing'] ?? 0.0) > 0
                                      ? Colors
                                            .green
                                            .shade100 // সবুজ = স্টক আছে
                                      : Colors.red.shade100, // লাল = নেগেটিভ
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item['closing']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: (item['closing'] ?? 0.0) > 0
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
