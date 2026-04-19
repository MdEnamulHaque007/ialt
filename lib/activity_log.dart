import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await firestore
          .collection('activity_log')
          .orderBy('timestamp', descending: true)
          .get();
      setState(() {
        _logs = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading logs: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total logs: ${_logs.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No activity logs found'),
                      ],
                    ),
                  )
                : DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 800,
                    dataRowHeight: 60,
                    headingRowHeight: 56,
                    headingRowColor: WidgetStateProperty.all(
                      Colors.blue.shade50,
                    ),
                    columns: const [
                      DataColumn2(
                        label: Text(
                          'Time',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text(
                          'Action',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Text(
                          'Details',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Text(
                          'User',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        size: ColumnSize.S,
                      ),
                    ],
                    rows: List.generate(_logs.length, (index) {
                      final log = _logs[index];
                      final timeStr = log['timestamp'] != null
                          ? (log['timestamp'] as Timestamp).toDate()
                          : DateTime.now();
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(DateFormat('dd-MMM HH:mm').format(timeStr)),
                          ),
                          DataCell(
                            Text(
                              log['action'] ?? '',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataCell(Text(log['details'] ?? '')),
                          DataCell(Text(log['user'] ?? 'Unknown')),
                        ],
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}
