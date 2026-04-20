import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/master_lc.dart';
import '../services/master_lc_service.dart';

// ─── CONSTANTS ────────────────────────────────────────────
const _kIndigo = Color(0xFF3730A3);
const _kIndigoLight = Color(0xFFEEF2FF);
const _kIndigoSurface = Color(0xFFF8F7FF);
const _kBorder = Color(0xFFE2E8F0);
const _kTextPrimary = Color(0xFF1E293B);
const _kTextSecondary = Color(0xFF64748B);
const _kRowAlt = Color(0xFFFAFAFF);
const _kSuccess = Color(0xFF10B981);
const _kWarning = Color(0xFFF59E0B);
const _kError = Color(0xFFEF4444);

final _numFmt = NumberFormat('#,##0.##');

// ─── MAIN ADMIN PANEL ─────────────────────────────────────
class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  // Dashboard Stats
  int poCount = 0;
  double poValue = 0;
  int productionCount = 0;
  double productionQty = 0;
  int issueCount = 0;
  double issueValue = 0;
  int exportCount = 0;
  double exportValue = 0;
  int lcCount = 0;
  double lcValue = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      // Purchase Orders
      final poSnapshot = await FirebaseFirestore.instance
          .collection('purchase_order')
          .get();
      poCount = poSnapshot.docs.length;
      poValue = poSnapshot.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc['totalValue']?.toDouble() ?? 0),
      );

      // Production
      final prodSnapshot = await FirebaseFirestore.instance
          .collection('Production')
          .get();
      productionCount = prodSnapshot.docs.length;
      productionQty = prodSnapshot.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc['qty']?.toDouble() ?? 0),
      );

      // Issues
      final issueSnapshot = await FirebaseFirestore.instance
          .collection('issue')
          .get();
      issueCount = issueSnapshot.docs.length;
      issueValue = issueSnapshot.docs.fold<double>(0, (sum, doc) {
        final qty = doc['quantity']?.toDouble() ?? 0;
        return sum + qty * 10;
      });

      // Exports
      final exportSnapshot = await FirebaseFirestore.instance
          .collection('export')
          .get();
      exportCount = exportSnapshot.docs.length;
      exportValue = exportSnapshot.docs.fold<double>(0, (sum, doc) {
        final qty = doc['quantity']?.toDouble() ?? 0;
        return sum + qty * 10;
      });

      // Master LC
      final lcSnapshot = await FirebaseFirestore.instance
          .collection('master_lc')
          .get();
      lcCount = lcSnapshot.docs.length;
      lcValue = lcSnapshot.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc['master_lc_value']?.toDouble() ?? 0),
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Dashboard stats error: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kIndigoSurface,
      body: Column(
        children: [
          // Premium App Bar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _kIndigo,
                  const Color(0xFF4F46E5),
                  const Color(0xFF6366F1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _kIndigo.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.account_tree_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'iALT Management System',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Enterprise Resource Dashboard',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Custom Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: _kIndigo,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.dashboard_outlined, size: 18),
                          text: 'Dashboard',
                        ),
                        Tab(
                          icon: Icon(Icons.description_outlined, size: 18),
                          text: 'Master L/C',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DashboardContent(
                  onRefresh: _loadDashboardStats,
                  stats: DashboardStats(
                    poCount: poCount,
                    poValue: poValue,
                    productionCount: productionCount,
                    productionQty: productionQty,
                    issueCount: issueCount,
                    issueValue: issueValue,
                    exportCount: exportCount,
                    exportValue: exportValue,
                    lcCount: lcCount,
                    lcValue: lcValue,
                  ),
                ),
                const MasterLcContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DASHBOARD STATS MODEL ────────────────────────────────
class DashboardStats {
  final int poCount;
  final double poValue;
  final int productionCount;
  final double productionQty;
  final int issueCount;
  final double issueValue;
  final int exportCount;
  final double exportValue;
  final int lcCount;
  final double lcValue;

  DashboardStats({
    required this.poCount,
    required this.poValue,
    required this.productionCount,
    required this.productionQty,
    required this.issueCount,
    required this.issueValue,
    required this.exportCount,
    required this.exportValue,
    required this.lcCount,
    required this.lcValue,
  });
}

// ─── DASHBOARD CONTENT ────────────────────────────────────
class _DashboardContent extends StatefulWidget {
  final VoidCallback onRefresh;
  final DashboardStats stats;

  const _DashboardContent({required this.onRefresh, required this.stats});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: _kIndigo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildWelcomeHeader(),
            ),
            const SizedBox(height: 28),
            FadeTransition(opacity: _fadeAnimation, child: _buildStatsGrid()),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildChartsSection(),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildRecentActivities(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final now = DateTime.now();
    String greeting = '';
    if (now.hour < 12) {
      greeting = 'Good Morning';
    } else if (now.hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kIndigo, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: _kIndigo.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting! 👋',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _kIndigo,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s your business overview for today.',
                  style: TextStyle(
                    fontSize: 14,
                    color: _kTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _kSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 14, color: _kSuccess),
                      const SizedBox(width: 4),
                      Text(
                        '+23% vs last month',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kSuccess,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: _kIndigo.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Icon(Icons.analytics_outlined, size: 52, color: _kIndigo),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _StatItem(
        title: 'Total POs',
        value: widget.stats.poCount.toString(),
        subtitle: 'Value: \$${_numFmt.format(widget.stats.poValue)}',
        icon: Icons.shopping_cart,
        color: Colors.blue,
        gradient: [Colors.blue.shade600, Colors.blue.shade400],
        trend: '+12%',
        trendUp: true,
      ),
      _StatItem(
        title: 'Production',
        value: widget.stats.productionCount.toString(),
        subtitle: '${_numFmt.format(widget.stats.productionQty)} units',
        icon: Icons.precision_manufacturing,
        color: Colors.green,
        gradient: [Colors.green.shade600, Colors.green.shade400],
        trend: '+8%',
        trendUp: true,
      ),
      _StatItem(
        title: 'Issues',
        value: widget.stats.issueCount.toString(),
        subtitle: '\$${_numFmt.format(widget.stats.issueValue)}',
        icon: Icons.inventory_2,
        color: Colors.orange,
        gradient: [Colors.orange.shade600, Colors.orange.shade400],
        trend: '-3%',
        trendUp: false,
      ),
      _StatItem(
        title: 'Exports',
        value: widget.stats.exportCount.toString(),
        subtitle: '\$${_numFmt.format(widget.stats.exportValue)}',
        icon: Icons.local_shipping,
        color: Colors.purple,
        gradient: [Colors.purple.shade600, Colors.purple.shade400],
        trend: '+15%',
        trendUp: true,
      ),
      _StatItem(
        title: 'Master L/C',
        value: widget.stats.lcCount.toString(),
        subtitle: '\$${_numFmt.format(widget.stats.lcValue)}',
        icon: Icons.description,
        color: _kIndigo,
        gradient: [_kIndigo, const Color(0xFF4F46E5)],
        trend: '+5%',
        trendUp: true,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final delay = index * 0.05;
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: Offset(0, 0.1 + delay),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOut,
                  ),
                ),
            child: _ModernStatCard(item: stats[index]),
          ),
        );
      },
    );
  }

  Widget _buildChartsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildChartCard(
            title: 'Revenue Overview',
            icon: Icons.attach_money,
            color: _kSuccess,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(
                      'PO Value',
                      Colors.blue,
                      widget.stats.poValue,
                    ),
                    _buildLegendItem(
                      'LC Value',
                      _kIndigo,
                      widget.stats.lcValue,
                    ),
                    _buildLegendItem(
                      'Export',
                      Colors.purple,
                      widget.stats.exportValue,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      Expanded(
                        flex:
                            ((widget.stats.poValue /
                                        (widget.stats.poValue +
                                            widget.stats.lcValue +
                                            widget.stats.exportValue)) *
                                    100)
                                .toInt(),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.blueAccent],
                            ),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex:
                            ((widget.stats.lcValue /
                                        (widget.stats.poValue +
                                            widget.stats.lcValue +
                                            widget.stats.exportValue)) *
                                    100)
                                .toInt(),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_kIndigo, _kIndigo.withOpacity(0.8)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kIndigo.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex:
                            ((widget.stats.exportValue /
                                        (widget.stats.poValue +
                                            widget.stats.lcValue +
                                            widget.stats.exportValue)) *
                                    100)
                                .toInt(),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.purple, Colors.purpleAccent],
                            ),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 4,
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
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildChartCard(
            title: 'Production vs Issues',
            icon: Icons.factory,
            color: Colors.orange,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildCircularProgress(
                        value: widget.stats.productionCount.toDouble(),
                        total:
                            (widget.stats.productionCount +
                                    widget.stats.issueCount)
                                .toDouble(),
                        color: Colors.green,
                        label: 'Production',
                      ),
                    ),
                    Expanded(
                      child: _buildCircularProgress(
                        value: widget.stats.issueCount.toDouble(),
                        total:
                            (widget.stats.productionCount +
                                    widget.stats.issueCount)
                                .toDouble(),
                        color: Colors.orange,
                        label: 'Issues',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double value) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: _kTextSecondary),
        ),
        Text(
          '\$${_numFmt.format(value)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCircularProgress({
    required double value,
    required double total,
    required Color color,
    required String label,
  }) {
    final percentage = total > 0 ? (value / total) * 100 : 0;
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: total > 0 ? value / total : 0,
                  strokeWidth: 8,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kIndigo, const Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.history_edu,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kTextPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: _kIndigo,
                  backgroundColor: _kIndigoLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActivityTimeline(),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRecentActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No recent activities',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          separatorBuilder: (_, __) => Divider(height: 32, color: _kBorder),
          itemBuilder: (context, index) {
            final activity = snapshot.data![index];
            return _ActivityTile(activity: activity);
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRecentActivities() async {
    final activities = <Map<String, dynamic>>[];
    final now = DateTime.now();

    try {
      // Recent POs
      final poRecent = await FirebaseFirestore.instance
          .collection('purchase_order')
          .orderBy('createdAt', descending: true)
          .limit(2)
          .get();

      for (var doc in poRecent.docs) {
        activities.add({
          'type': 'po',
          'title': 'New Purchase Order',
          'description': 'PO created with value \$${doc['totalValue']}',
          'time': doc['createdAt']?.toDate() ?? now,
          'icon': Icons.shopping_cart,
          'color': Colors.blue,
        });
      }

      // Recent Master LC
      final lcRecent = await FirebaseFirestore.instance
          .collection('master_lc')
          .orderBy('created_at', descending: true)
          .limit(2)
          .get();

      for (var doc in lcRecent.docs) {
        activities.add({
          'type': 'lc',
          'title': 'Master L/C Added',
          'description': 'L/C value: \$${doc['master_lc_value']}',
          'time': doc['created_at']?.toDate() ?? now,
          'icon': Icons.description,
          'color': _kIndigo,
        });
      }

      // Recent Production
      final prodRecent = await FirebaseFirestore.instance
          .collection('Production')
          .orderBy('createdAt', descending: true)
          .limit(2)
          .get();

      for (var doc in prodRecent.docs) {
        activities.add({
          'type': 'production',
          'title': 'Production Update',
          'description': '${doc['qty']} units produced',
          'time': doc['createdAt']?.toDate() ?? now,
          'icon': Icons.precision_manufacturing,
          'color': Colors.green,
        });
      }

      activities.sort((a, b) => b['time'].compareTo(a['time']));
      return activities.take(5).toList();
    } catch (e) {
      debugPrint('Error: $e');
      return [];
    }
  }
}

// ─── MODERN STAT CARD ─────────────────────────────────────
class _StatItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final String trend;
  final bool trendUp;

  _StatItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.trend,
    required this.trendUp,
  });
}

class _ModernStatCard extends StatelessWidget {
  final _StatItem item;

  const _ModernStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: item.gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.title} details opened'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: item.color,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.trendUp ? Icons.trending_up : Icons.trending_down,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      item.trend,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ACTIVITY TILE ────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (activity['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            activity['icon'] as IconData,
            color: activity['color'] as Color,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity['description'] as String,
                style: TextStyle(fontSize: 12, color: _kTextSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(activity['time'] as DateTime),
                style: TextStyle(
                  fontSize: 10,
                  color: _kTextSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (activity['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'View',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: activity['color'] as Color,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

// ─── MASTER L/C CONTENT (পূর্বের কোডের ইন্টিগ্রেটেড ভার্সন) ───
class MasterLcContent extends StatefulWidget {
  const MasterLcContent({super.key});

  @override
  State<MasterLcContent> createState() => _MasterLcContentState();
}

class _MasterLcContentState extends State<MasterLcContent> {
  final CollectionReference _lcCol = FirebaseFirestore.instance.collection(
    'master_lc',
  );
  final _formKey = GlobalKey<FormState>();
  final _tagCtrl = TextEditingController();
  final _projectCtrl = TextEditingController();
  final _applicantCtrl = TextEditingController();
  final _scCtrl = TextEditingController();
  final _lcNoCtrl = TextEditingController();
  final _ttCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final MasterLCService _service = MasterLCService();
  DateTime? _selectedDate;
  List<String> _projects = [];

  List<String> _applicants = [];

  static const double _cSl = 52;
  static const double _cDate = 100;
  static const double _cTag = 110;
  static const double _cProject = 130;
  static const double _cApplicant = 140;
  static const double _cSc = 105;
  static const double _cLc = 125;
  static const double _cTt = 105;
  static const double _cValue = 115;
  static const double _cQty = 95;
  static const double _cAction = 88;

  @override
  void initState() {
    super.initState();
    _loadAutocompleteOptions();
  }

  Future<void> _loadAutocompleteOptions() async {
    final snap = await _lcCol.get();
    final projects = <String>{};
    final applicants = <String>{};
    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (d['project']?.isNotEmpty == true) projects.add(d['project']);
      if (d['applicant']?.isNotEmpty == true) applicants.add(d['applicant']);
    }
    if (mounted) {
      setState(() {
        _projects = projects.toList()..sort();
        _applicants = applicants.toList()..sort();
      });
    }
  }

  Future<void> _pickDate(StateSetter setDialogState) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _kIndigo)),
        child: child!,
      ),
    );
    if (picked != null) setDialogState(() => _selectedDate = picked);
  }

  Future<void> _addRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _snack('Please select a date', isError: true);
      return;
    }
    final lc = MasterLC(
      id: '',
      slNo: await _service.getNextSlNo(),
      tagNo: _tagCtrl.text.trim(),
      project: _projectCtrl.text.trim(),
      applicant: _applicantCtrl.text.trim(),
      scNo: _scCtrl.text.trim(),
      lcNo: _lcNoCtrl.text.trim(),
      ttNo: _ttCtrl.text.trim(),
      masterLcDate: _selectedDate!.toIso8601String(),
      masterLcValue: double.tryParse(_valueCtrl.text.trim()) ?? 0.0,
      masterLcQty: double.tryParse(_qtyCtrl.text.trim()) ?? 0.0,
    );
    await _service.add(lc);
    _snack('Record added successfully');
    _clearForm();
    _loadAutocompleteOptions();
  }

  Future<void> _updateRecord(String docId) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _snack('Please select a date', isError: true);
      return;
    }
    final lc = MasterLC(
      id: docId,
      slNo: 0,
      tagNo: _tagCtrl.text.trim(),
      project: _projectCtrl.text.trim(),
      applicant: _applicantCtrl.text.trim(),
      scNo: _scCtrl.text.trim(),
      lcNo: _lcNoCtrl.text.trim(),
      ttNo: _ttCtrl.text.trim(),
      masterLcDate: _selectedDate!.toIso8601String(),
      masterLcValue: double.tryParse(_valueCtrl.text.trim()) ?? 0.0,
      masterLcQty: double.tryParse(_qtyCtrl.text.trim()) ?? 0.0,
    );
    await _service.update(lc);

    _snack('Record updated successfully');
    _loadAutocompleteOptions();
  }

  Future<void> _deleteRecord(String docId) async {
    await _service.delete(docId);
    _snack('Record deleted successfully');
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _kError : _kIndigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearForm() {
    _tagCtrl.clear();
    _projectCtrl.clear();
    _applicantCtrl.clear();
    _scCtrl.clear();
    _lcNoCtrl.clear();
    _ttCtrl.clear();
    _valueCtrl.clear();
    _qtyCtrl.clear();
    _selectedDate = null;
  }

  void _fillForm(Map<String, dynamic> data) {
    _tagCtrl.text = data['tag_no'] ?? '';
    _projectCtrl.text = data['project'] ?? '';
    _applicantCtrl.text = data['applicant'] ?? '';
    _scCtrl.text = data['sc_no'] ?? '';
    _lcNoCtrl.text = data['lc_no'] ?? '';
    _ttCtrl.text = data['tt_no'] ?? '';
    _valueCtrl.text = (data['master_lc_value'] ?? 0).toString();
    _qtyCtrl.text = (data['master_lc_qty'] ?? 0).toString();
    _selectedDate = data['master_lc_date'] is Timestamp
        ? (data['master_lc_date'] as Timestamp?)?.toDate()
        : data['master_lc_date'] is String
        ? DateTime.parse(data['master_lc_date'])
        : null;
  }

  void _showFormDialog({String? docId, Map<String, dynamic>? data}) {
    final isEdit = docId != null;
    if (isEdit && data != null) {
      _fillForm(data);
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kIndigoLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_note : Icons.add_circle_outline,
                        color: _kIndigo,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Master L/C' : 'Add New Master L/C',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: _kTextSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: _kBorder),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _DatePickerField(
                            selectedDate: _selectedDate,
                            onTap: () => _pickDate(setDialogState),
                          ),
                          const SizedBox(height: 14),
                          _buildFormField(
                            'TAG Number *',
                            _tagCtrl,
                            Icons.tag,
                            validator: (v) =>
                                v?.trim().isEmpty == true ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          _buildAutocompleteField(
                            'Project *',
                            _projectCtrl,
                            _projects,
                            validator: (v) =>
                                v?.trim().isEmpty == true ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          _buildAutocompleteField(
                            'Applicant *',
                            _applicantCtrl,
                            _applicants,
                            validator: (v) =>
                                v?.trim().isEmpty == true ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  'SC Number',
                                  _scCtrl,
                                  Icons.receipt,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFormField(
                                  'L/C Number',
                                  _lcNoCtrl,
                                  Icons.credit_card,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildFormField(
                            'TT Number',
                            _ttCtrl,
                            Icons.swap_horiz,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberField(
                                  'L/C Value (USD)',
                                  _valueCtrl,
                                  Icons.attach_money,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildNumberField(
                                  'L/C Quantity',
                                  _qtyCtrl,
                                  Icons.inventory,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: _kBorder),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: _kTextSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          if (isEdit) {
                            await _updateRecord(docId);
                          } else {
                            await _addRecord();
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          _snack('Error: $e', isError: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kIndigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isEdit ? Icons.save_outlined : Icons.add,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(isEdit ? 'Update' : 'Add'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(String docId, int slNo) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kError.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline, color: _kError, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Record?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SL $slNo record will be permanently deleted.',
                style: const TextStyle(color: _kTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kTextSecondary,
                        side: const BorderSide(color: _kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _deleteRecord(docId);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kError,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: _kTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kIndigo, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
      ),
      validator: validator,
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: _kTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kIndigo, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
      ),
    );
  }

  Widget _buildAutocompleteField(
    String label,
    TextEditingController controller,
    List<String> options, {
    String? Function(String?)? validator,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return options.where(
          (o) => o.toLowerCase().contains(textEditingValue.text.toLowerCase()),
        );
      },
      onSelected: (selection) => controller.text = selection,
      fieldViewBuilder: (ctx, fieldCtrl, focusNode, onFieldSubmitted) {
        fieldCtrl.addListener(() {
          if (controller.text != fieldCtrl.text)
            controller.text = fieldCtrl.text;
        });
        return TextFormField(
          controller: fieldCtrl,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(
              Icons.business_outlined,
              size: 18,
              color: _kTextSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kIndigo, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
          ),
          validator: validator,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }

  Widget _buildTableCell(
    String text,
    double width, {
    Color? bg,
    bool bold = false,
    Color? textColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      color: bg,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: textColor ?? _kTextPrimary,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kIndigoSurface,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.description, size: 20, color: _kIndigo),
                const SizedBox(width: 10),
                const Text(
                  'Master L/C Management',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: _kTextPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _lcCol.orderBy('sl_no').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _kIndigo),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: _kError),
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No records found',
                          style: TextStyle(color: _kTextSecondary),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _showFormDialog(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kIndigo,
                          ),
                          child: const Text('Add First Record'),
                        ),
                      ],
                    ),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _kIndigo,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildTableCell(
                              'SL',
                              _cSl,
                              bg: _kIndigo,
                              textColor: Colors.white,
                              bold: true,
                            ),
                            _buildTableCell(
                              'Date',
                              _cDate,
                              bg: _kIndigo,
                              textColor: Colors.white,
                              bold: true,
                            ),
                            _buildTableCell(
                              'TAG No',
                              _cTag,
                              bg: _kIndigo,
                              textColor: Colors.white,
                              bold: true,
                            ),
                            _buildTableCell(
                              'Project',
                              _cProject,
                              bg: _kIndigo,
                              textColor: Colors.white,
                              bold: true,
                            ),
                            _buildTableCell(
                              'Applicant',
                              _cApplicant,
                              bg: _kIndigo,
                              textColor: Colors.white,
                              bold: true,
                            ),
                            _buildTableCell(
                              'SC No',
                              _cSc,
                              bg: _kIndigo,
                              textColor: Colors.white,
                              bold: true,
                            ),
                            _buildTableCell(
                              'L/C No',
                              _cLc,
                              bg: _kIndigo,
                              textColor: Colors.white,
                              bold: true,
                            ),
                            _buildTableCell(
                              'TT No',
                              _cTt,
                              bg: _kIndigo,
                              textColor: Colors.white,
                              bold: true,
                            ),
                            _buildTableCell(
                              'Value',
                              _cValue,
                              bg: _kIndigo,
                              textColor: Colors.white,
                              bold: true,
                            ),
                            _buildTableCell(
                              'Qty',
                              _cQty,
                              bg: _kIndigo,
                              textColor: Colors.white,
                              bold: true,
                            ),
                            _buildTableCell(
                              'Action',
                              _cAction,
                              bg: _kIndigo,
                              textColor: Colors.white,
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                      ...docs.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final doc = entry.value;
                        final d = doc.data() as Map<String, dynamic>;
                        final slNo = (d['sl_no'] as num?)?.toInt() ?? (idx + 1);
                        final date = (d['master_lc_date'] as Timestamp?)
                            ?.toDate();
                        final dateStr = date != null
                            ? DateFormat('dd-MM-yyyy').format(date)
                            : '—';
                        final isEven = idx % 2 == 0;
                        final bg = isEven ? Colors.white : _kRowAlt;
                        final value =
                            (d['master_lc_value'] as num?)?.toDouble() ?? 0;
                        final qty =
                            (d['master_lc_qty'] as num?)?.toDouble() ?? 0;
                        return Container(
                          decoration: BoxDecoration(
                            color: bg,
                            border: Border(
                              bottom: BorderSide(color: _kBorder, width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: _cSl,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                color: bg,
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _kIndigoLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$slNo',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _kIndigo,
                                    ),
                                  ),
                                ),
                              ),
                              _buildTableCell(dateStr, _cDate, bg: bg),
                              _buildTableCell(
                                d['tag_no'] ?? '—',
                                _cTag,
                                bg: bg,
                                bold: true,
                                textColor: _kIndigo,
                              ),
                              _buildTableCell(
                                d['project'] ?? '—',
                                _cProject,
                                bg: bg,
                              ),
                              _buildTableCell(
                                d['applicant'] ?? '—',
                                _cApplicant,
                                bg: bg,
                              ),
                              _buildTableCell(d['sc_no'] ?? '—', _cSc, bg: bg),
                              _buildTableCell(d['lc_no'] ?? '—', _cLc, bg: bg),
                              _buildTableCell(d['tt_no'] ?? '—', _cTt, bg: bg),
                              _buildTableCell(
                                value > 0 ? '\$${_numFmt.format(value)}' : '—',
                                _cValue,
                                bg: bg,
                                bold: value > 0,
                              ),
                              _buildTableCell(
                                qty > 0 ? _numFmt.format(qty) : '—',
                                _cQty,
                                bg: bg,
                              ),
                              Container(
                                width: _cAction,
                                color: bg,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Tooltip(
                                      message: 'Edit',
                                      child: InkWell(
                                        onTap: () => _showFormDialog(
                                          docId: doc.id,
                                          data: d,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            color: Colors.blue.shade600,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Tooltip(
                                      message: 'Delete',
                                      child: InkWell(
                                        onTap: () =>
                                            _showDeleteDialog(doc.id, slNo),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red.shade600,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tagCtrl.dispose();
    _projectCtrl.dispose();
    _applicantCtrl.dispose();
    _scCtrl.dispose();
    _lcNoCtrl.dispose();
    _ttCtrl.dispose();
    _valueCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }
}

// ─── DATE PICKER FIELD ────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const _DatePickerField({required this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selectedDate != null ? _kIndigo : _kBorder,
            width: selectedDate != null ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: selectedDate != null ? _kIndigo : _kTextSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedDate != null
                    ? DateFormat('dd MMM yyyy').format(selectedDate!)
                    : 'Select Date *',
                style: TextStyle(
                  color: selectedDate != null ? _kTextPrimary : _kTextSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            if (selectedDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kIndigoLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 10,
                    color: _kIndigo,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
