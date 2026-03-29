import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'admin_create_staff.dart';
import 'admin_dashboard.dart';
import 'admin_orders.dart';
import 'admin_products.dart';
import 'admin_remaining.dart';

enum AdminPortalType { admin, worker }

class AdminShell extends StatefulWidget {
  final AdminPortalType portalType;
  const AdminShell({super.key, this.portalType = AdminPortalType.admin});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  bool get _isAdmin => widget.portalType == AdminPortalType.admin;

  // ── Admin nav: Pharmacies removed — admin manages Branches and Staff only ──
  late final List<_NavItem> _navItems = _isAdmin
      ? [
          _NavItem(
            Icons.dashboard_rounded,
            'Dashboard',
            const Color(0xFF1565C0),
          ),
          _NavItem(
            Icons.shopping_bag_rounded,
            'Orders',
            const Color(0xFFE65100),
          ),
          _NavItem(
            Icons.inventory_2_rounded,
            'Products',
            const Color(0xFF6A1B9A),
          ),
          _NavItem(
            Icons.location_on_rounded,
            'Branches',
            const Color(0xFF00838F),
          ),
          _NavItem(Icons.badge_rounded, 'Employees', const Color(0xFFF57F17)),
          _NavItem(
            Icons.local_shipping_rounded,
            'Suppliers',
            const Color(0xFF558B2F),
          ),
          _NavItem(Icons.people_rounded, 'Customers', const Color(0xFFC2185B)),
          _NavItem(
            Icons.point_of_sale_rounded,
            'Sales',
            const Color(0xFFB71C1C),
          ),
          _NavItem(
            Icons.receipt_long_rounded,
            'Receipts',
            const Color(0xFF4E342E),
          ),
          _NavItem(
            Icons.access_time_rounded,
            'Attendance',
            const Color(0xFF0277BD),
          ),
        ]
      : [
          _NavItem(
            Icons.dashboard_rounded,
            'Dashboard',
            const Color(0xFF1565C0),
          ),
          _NavItem(
            Icons.shopping_bag_rounded,
            'Orders',
            const Color(0xFFE65100),
          ),
          _NavItem(
            Icons.inventory_2_rounded,
            'Products',
            const Color(0xFF6A1B9A),
          ),
          _NavItem(
            Icons.point_of_sale_rounded,
            'Sales',
            const Color(0xFFB71C1C),
          ),
          _NavItem(
            Icons.access_time_rounded,
            'Attendance',
            const Color(0xFF0277BD),
          ),
        ];

  late final List<Widget> _pages = _isAdmin
      ? const [
          AdminDashboard(),
          AdminOrdersPage(),
          AdminProductsPage(),
          AdminBranchesPage(), // was index 4 (after Pharmacies); now index 3
          AdminEmployeesPage(),
          AdminSuppliersPage(),
          AdminCustomersPage(),
          AdminSalesPage(),
          AdminReceiptsPage(),
          AdminAttendancePage(),
        ]
      : const [
          AdminDashboard(),
          AdminOrdersPage(),
          AdminProductsPage(),
          AdminSalesPage(),
          AdminAttendancePage(),
        ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final pageIndex = _selectedIndex.clamp(0, _pages.length - 1);

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
                    child: _pages[pageIndex],
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
    color: const Color(0xFF1A2035),
    child: _buildSidebarContent(),
  );

  Widget _buildSidebarContent() {
    return Container(
      color: const Color(0xFF1A2035),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF2E7D32),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pharma One',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _isAdmin ? 'Admin Portal' : 'Worker Portal',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
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
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
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
              leading: const Icon(
                Icons.logout,
                color: Colors.white54,
                size: 20,
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
            _navItems[_selectedIndex.clamp(0, _navItems.length - 1)].title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),

          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Live',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Admin-only: Create Staff button
          if (_isAdmin) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const CreateStaffDialog(),
              ),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Add Staff', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ],

          const SizedBox(width: 12),

          // Profile avatar
          FutureBuilder<Map<String, dynamic>?>(
            future: SupabaseService.getProfile(
              SupabaseService.currentUserId ?? '',
            ),
            builder: (context, snap) {
              final name = snap.data?['name'] ?? 'Staff';
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
              return Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF2E7D32),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
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
  _NavItem(this.icon, this.title, this.color);
}
