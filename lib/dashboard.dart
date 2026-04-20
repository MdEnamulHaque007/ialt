import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  int poCount = 0;
  double poValue = 0;
  int productionCount = 0;
  double productionQty = 0;
  int issueCount = 0;
  double issueValue = 0;
  int exportCount = 0;
  double exportValue = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

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
    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _loadStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
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

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Dashboard stats error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: _buildWelcomeSection(),
                  ),
                ),
                const SizedBox(height: 32),
                _buildStatsGrid(),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation.drive(
                      Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ),
                    ),
                    child: _buildRecentActivity(),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.indigo,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade700,
                Colors.indigo.shade500,
                Colors.blue.shade400,
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          child: const SizedBox.expand(),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
          color: Colors.white,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadStats,
          color: Colors.white,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.1),
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
                  'Welcome back! 👋',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s what\'s happening with your business today.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.indigo.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.indigo.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _StatData(
        title: 'Total POs',
        value: poCount.toString(),
        subtitle: 'Value: \$${NumberFormat('#,##0').format(poValue)}',
        icon: Icons.shopping_cart,
        gradient: [Colors.blue.shade600, Colors.blue.shade400],
        trend: '+12%',
        trendUp: true,
      ),
      _StatData(
        title: 'Productions',
        value: productionCount.toString(),
        subtitle: NumberFormat('#,##0').format(productionQty),
        icon: Icons.precision_manufacturing,
        gradient: [Colors.green.shade600, Colors.green.shade400],
        trend: '+8%',
        trendUp: true,
      ),
      _StatData(
        title: 'Issues',
        value: issueCount.toString(),
        subtitle: '\$${NumberFormat('#,##0').format(issueValue)}',
        icon: Icons.inventory_2,
        gradient: [Colors.orange.shade600, Colors.orange.shade400],
        trend: '-3%',
        trendUp: false,
      ),
      _StatData(
        title: 'Exports',
        value: exportCount.toString(),
        subtitle: '\$${NumberFormat('#,##0').format(exportValue)}',
        icon: Icons.local_shipping,
        gradient: [Colors.purple.shade600, Colors.purple.shade400],
        trend: '+15%',
        trendUp: true,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.1,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation.drive(
              Tween<Offset>(
                begin: Offset(
                  0,
                  0.05 * (index + 1),
                ), // Move calculation outside
                end: Offset.zero,
              ),
            ),
            child: _ModernStatCard(data: stats[index]),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade600, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.history_edu_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _loadStats,
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    backgroundColor: Colors.indigo.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildActivityTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTimeline() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRecentActivities(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load activities',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading activities...'),
              ],
            ),
          );
        }

        final activities = snapshot.data!;

        if (activities.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No recent activities',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          separatorBuilder: (context, index) =>
              Divider(height: 32, color: Colors.grey.shade200),
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _ActivityItem(activity: activity);
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRecentActivities() async {
    final activities = <Map<String, dynamic>>[];
    final now = DateTime.now();

    try {
      // Fetch recent POs
      final poRecent = await FirebaseFirestore.instance
          .collection('purchase_order')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      for (var doc in poRecent.docs) {
        activities.add({
          'type': 'po',
          'title': 'New Purchase Order',
          'description':
              'PO #${doc.id} created with value \$${doc['totalValue']}',
          'time': doc['createdAt']?.toDate() ?? now,
          'icon': Icons.shopping_cart,
          'color': Colors.blue,
        });
      }

      // Fetch recent Productions
      final prodRecent = await FirebaseFirestore.instance
          .collection('Production')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      for (var doc in prodRecent.docs) {
        activities.add({
          'type': 'production',
          'title': 'Production Update',
          'description': 'Production batch completed: ${doc['qty']} units',
          'time': doc['createdAt']?.toDate() ?? now,
          'icon': Icons.precision_manufacturing,
          'color': Colors.green,
        });
      }

      // Sort by time
      activities.sort((a, b) => b['time'].compareTo(a['time']));

      return activities.take(5).toList();
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      return [];
    }
  }
}

class _StatData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String trend;
  final bool trendUp;

  _StatData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.trend,
    required this.trendUp,
  });
}

class _ModernStatCard extends StatelessWidget {
  final _StatData data;

  const _ModernStatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.gradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: data.gradient.first.withOpacity(0.3),
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
                content: Text('${data.title} details opened'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: data.gradient.first,
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      data.trendUp ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.trend,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
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

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (activity['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            activity['icon'] as IconData,
            color: activity['color'] as Color,
            size: 24,
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
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity['description'] as String,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(activity['time'] as DateTime),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (activity['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'View',
            style: TextStyle(
              fontSize: 12,
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
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
