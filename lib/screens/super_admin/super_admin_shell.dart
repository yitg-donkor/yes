import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'super_admin_dashboard.dart';
import 'super_admin_pharmacies.dart';
import 'super_admin_orders.dart';

class SuperAdminShell extends StatefulWidget {
  const SuperAdminShell({super.key});

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.dashboard_rounded, 'Network Overview', Color(0xFF1565C0)),
    _NavItem(Icons.local_pharmacy_rounded, 'Pharmacies', Color(0xFF2E7D32)),
    _NavItem(Icons.receipt_long_rounded, 'All Orders', Color(0xFFE65100)),
  ];

  late final List<Widget> _pages = const [
    SuperAdminDashboard(),
    SuperAdminPharmaciesPage(),
    SuperAdminOrdersPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          if (isWide) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isWide),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F6FA),
                    child: _pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(child: _buildSidebarContent()),
    );
  }

  Widget _buildSidebar() => Container(
        width: 240,
        color: const Color(0xFF0D1B2A),
        child: _buildSidebarContent(),
      );

  Widget _buildSidebarContent() {
    return Container(
      color: const Color(0xFF0D1B2A),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1565C0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pharma One',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text('Super Admin',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, i) {
                final item = _navItems[i];
                final selected = _selectedIndex == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? item.color.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected
                            ? item.color
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 18),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white60,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedIndex = i);
                      if (MediaQuery.of(context).size.width <= 900) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Sign out
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.logout, color: Colors.white54, size: 20),
              title: const Text('Sign Out',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onTap: () async => await SupabaseService.signOut(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isWide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (!isWide)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          Text(
            _navItems[_selectedIndex].title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // Super admin badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user,
                    size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text('Super Admin',
                    style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Profile avatar
          FutureBuilder<Map<String, dynamic>?>(
            future: SupabaseService.getProfile(
                SupabaseService.currentUserId ?? ''),
            builder: (context, snap) {
              final name = snap.data?['name'] ?? 'Admin';
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
              return Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF1565C0),
                    child: Text(initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String title;
  final Color color;
  const _NavItem(this.icon, this.title, this.color);
}