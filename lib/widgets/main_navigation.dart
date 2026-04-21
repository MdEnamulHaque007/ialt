import 'package:flutter/material.dart';
import '../pages/export.dart';
import '../pages/issue.dart';
import '../pages/master_lc_page.dart';
import '../pages/purchase_order_page.dart';
import '../pages/production_page.dart';
import '../pages/setting_page.dart';
import 'package:provider/provider.dart';
import '../pages/stock.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'logout_button.dart';
import '../pages/dashboard.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderPage(title: 'Report', icon: Icons.bar_chart);
}

// SettingPage is now imported from ../pages/setting_page.dart

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderPage(title: 'About', icon: Icons.info_outline);
}

class ActivityLogPage extends StatelessWidget {
  const ActivityLogPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderPage(title: 'Activity Log', icon: Icons.history);
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Colors.indigo.shade200),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$title page coming soon…',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─── NAV ITEM MODEL ───────────────────────────────────────
class _NavItem {
  final String title;
  final IconData icon;
  final Widget page;
  const _NavItem({required this.title, required this.icon, required this.page});
}

// ─── MAIN NAVIGATION ──────────────────────────────────────
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<_NavItem> _pages = [
    const _NavItem(
      title: 'Dashboard',
      icon: Icons.dashboard,
      page: Dashboard(),
    ),
    const _NavItem(
      title: 'Master LC Information',
      icon: Icons.dashboard,
      page: MasterLcContent(),
    ),
    const _NavItem(
      title: 'Production',
      icon: Icons.precision_manufacturing,
      page: ProductionPage(),
    ),
    const _NavItem(
      title: 'Purchase Order',
      icon: Icons.description_outlined,
      page: PurchaseOrderPage(),
    ),
    const _NavItem(
      title: 'FG Issues',
      icon: Icons.inventory_2,
      page: IssuePage(),
    ),
    const _NavItem(
      title: 'Export',
      icon: Icons.local_shipping,
      page: ExportPage(),
    ),
    const _NavItem(title: 'Stock', icon: Icons.warehouse, page: StockReport()),
    const _NavItem(
      title: 'Activity Log',
      icon: Icons.history,
      page: ActivityLogPage(),
    ),
    const _NavItem(title: 'Report', icon: Icons.bar_chart, page: ReportPage()),
    const _NavItem(title: 'Setting', icon: Icons.settings, page: SettingPage()),
    const _NavItem(title: 'About', icon: Icons.info_outline, page: AboutPage()),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _pages[_selectedIndex];

    return Scaffold(
      // Single AppBar — home.dart must NOT have its own Scaffold/AppBar
      appBar: AppBar(
        title: Text(current.title),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      drawer: Drawer(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.indigoAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_circle,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Selector<SettingsProvider, String>(
                    selector: (_, vm) => vm.companyName,
                    builder: (context, companyName, _) {
                      return Text(
                        companyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return Text(
                        auth.user?.email ?? 'User',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            const LogoutButton(),
            const Divider(),

            // ── Nav Items ────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  final isSelected = _selectedIndex == index;

                  return Column(
                    children: [
                      if (index == 8) const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          item.icon,
                          color: isSelected
                              ? Colors.indigo
                              : Colors.grey.shade600,
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: isSelected ? Colors.indigo : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: Colors.indigo.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        onTap: () {
                          setState(() => _selectedIndex = index);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Footer ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'v1.0.0',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
          ],
        ),
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages.map((p) => p.page).toList(),
      ),
    );
  }
}
