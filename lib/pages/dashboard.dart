import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool _isLoading = true;

  // Metrics
  int _lcCount = 0;
  double _lcValue = 0;

  int _poCount = 0;
  double _poValue = 0;

  int _prodCount = 0;
  double _prodQty = 0;

  int _issueCount = 0;
  double _issueQty = 0;

  int _exportCount = 0;
  double _exportQty = 0;

  // Recent Activity
  List<Map<String, dynamic>> _recentActivities = [];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  final NumberFormat _numberFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final db = FirebaseFirestore.instance;

      // 1. Master LC (master_lc_value)
      final lcSnap = await db.collection('master_lc').get();
      int tempLcCount = lcSnap.size;
      double tempLcValue = 0;
      for (var doc in lcSnap.docs) {
        final data = doc.data();
        tempLcValue += _parseDouble(data['master_lc_value']);
      }

      // 2. Purchase Orders (totalValue)
      final poSnap = await db.collection('purchase_order').get();
      int tempPoCount = poSnap.size;
      double tempPoValue = 0;
      for (var doc in poSnap.docs) {
        tempPoValue += _parseDouble(doc.data()['totalValue']);
      }

      // 3. Production (qty)
      final prodSnap = await db.collection('Production').get();
      int tempProdCount = prodSnap.size;
      double tempProdQty = 0;
      for (var doc in prodSnap.docs) {
        tempProdQty += _parseDouble(doc.data()['qty']);
      }

      // 4. FG Issues (quantity)
      final issueSnap = await db.collection('issue').get();
      int tempIssueCount = issueSnap.size;
      double tempIssueQty = 0;
      for (var doc in issueSnap.docs) {
        tempIssueQty += _parseDouble(doc.data()['quantity']);
      }

      // 5. Exports (quantity)
      final exportSnap = await db.collection('export').get();
      int tempExportCount = exportSnap.size;
      double tempExportQty = 0;
      for (var doc in exportSnap.docs) {
        tempExportQty += _parseDouble(doc.data()['quantity']);
      }

      // Fetch Recent Activity (last 5 from PO and Production)
      List<Map<String, dynamic>> tempActivities = [];

      try {
        final poRecent = await db
            .collection('purchase_order')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();
        for (var doc in poRecent.docs) {
          final data = doc.data();
          tempActivities.add({
            'title': 'Purchase Order Created',
            'description':
                'PO #${data['po_id'] ?? doc.id} value: ${_currencyFormat.format(_parseDouble(data['totalValue']))}',
            'time': _parseDate(data['createdAt']),
            'icon': Icons.shopping_cart_outlined,
            'color': Colors.blue,
          });
        }
      } catch (e) {
        // Continue if index is missing or other read error
      }

      try {
        final prodRecent = await db
            .collection('Production')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();
        for (var doc in prodRecent.docs) {
          final data = doc.data();
          tempActivities.add({
            'title': 'Production Entry',
            'description':
                'Produced ${_numberFormat.format(_parseDouble(data['qty']))} items',
            'time': _parseDate(data['createdAt']),
            'icon': Icons.precision_manufacturing_outlined,
            'color': Colors.green,
          });
        }
      } catch (e) {
        // Continue
      }

      // Sort combined activities and take top 5
      tempActivities.sort(
        (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime),
      );
      _recentActivities = tempActivities.take(5).toList();

      if (mounted) {
        setState(() {
          _lcCount = tempLcCount;
          _lcValue = tempLcValue;
          _poCount = tempPoCount;
          _poValue = tempPoValue;
          _prodCount = tempProdCount;
          _prodQty = tempProdQty;
          _issueCount = tempIssueCount;
          _issueQty = tempIssueQty;
          _exportCount = tempExportCount;
          _exportQty = tempExportQty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard data: $e')),
        );
      }
    }
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is String) {
      return DateTime.tryParse(val) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _timeAgo(DateTime d) {
    Duration diff = DateTime.now().difference(d);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overview Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadDashboardData,
                      tooltip: 'Refresh Dashboard',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Wrap for Stats Cards
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard(
                      title: 'Master LC',
                      count: _lcCount,
                      value: _currencyFormat.format(_lcValue),
                      subLabel: 'Total LC Value',
                      icon: Icons.description_outlined,
                      color: Colors.indigo,
                    ),
                    _buildStatCard(
                      title: 'Purchase Orders',
                      count: _poCount,
                      value: _currencyFormat.format(_poValue),
                      subLabel: 'Total PO Value',
                      icon: Icons.shopping_cart_outlined,
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      title: 'Production',
                      count: _prodCount,
                      value: _numberFormat.format(_prodQty),
                      subLabel: 'Total Quantity',
                      icon: Icons.precision_manufacturing_outlined,
                      color: Colors.green,
                    ),
                    _buildStatCard(
                      title: 'FG Issues',
                      count: _issueCount,
                      value: _numberFormat.format(_issueQty),
                      subLabel: 'Total Issued Qty',
                      icon: Icons.inventory_2_outlined,
                      color: Colors.orange,
                    ),
                    _buildStatCard(
                      title: 'Export',
                      count: _exportCount,
                      value: _numberFormat.format(_exportQty),
                      subLabel: 'Total Exported Qty',
                      icon: Icons.local_shipping_outlined,
                      color: Colors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Recent Activity Section
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _recentActivities.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'No recent activity found.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentActivities.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _recentActivities[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: (item['color'] as Color)
                                    .withValues(alpha: 0.1),
                                child: Icon(
                                  item['icon'] as IconData,
                                  color: item['color'] as Color,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                item['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(item['description']),
                              trailing: Text(
                                _timeAgo(item['time'] as DateTime),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white54,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required String value,
    required String subLabel,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 200,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                NumberFormat('#,###').format(count),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Records',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                subLabel,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
