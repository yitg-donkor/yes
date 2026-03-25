import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _pharmacies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getSuperAdminStats(),
        SupabaseService.getPharmacies(),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _pharmacies = results[1] as List<Map<String, dynamic>>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1565C0)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(),
            const SizedBox(height: 24),
            _buildNetworkStats(),
            const SizedBox(height: 24),
            _buildPharmacyOverview(),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Network Overview',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 14)),
                const SizedBox(height: 4),
                const Text('Pharma One — Super Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '${_stats['activePharmacies'] ?? 0} active pharmacies across the network',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.admin_panel_settings,
              color: Colors.white24, size: 80),
        ],
      ),
    );
  }

  Widget _buildNetworkStats() {
    final cards = [
      _Card('Total Pharmacies', '${_stats['totalPharmacies'] ?? 0}',
          Icons.local_pharmacy, Colors.green, 'On network'),
      _Card('Active Pharmacies', '${_stats['activePharmacies'] ?? 0}',
          Icons.check_circle, Colors.blue, 'Currently active'),
      _Card('Network Revenue',
          'GH₵ ${_fmt(_stats['totalRevenue'])}',
          Icons.account_balance_wallet, Colors.teal, 'All completed orders'),
      _Card('Pending Orders', '${_stats['pendingOrders'] ?? 0}',
          Icons.pending_actions, Colors.orange, 'Across all pharmacies'),
      _Card('Total Students', '${_stats['totalStudents'] ?? 0}',
          Icons.school, Colors.purple, 'Registered'),
      _Card('Total Products', '${_stats['totalProducts'] ?? 0}',
          Icons.inventory_2, Colors.indigo, 'Across all pharmacies'),
    ];

    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth > 900
          ? 3
          : constraints.maxWidth > 600
              ? 2
              : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
        ),
        itemCount: cards.length,
        itemBuilder: (ctx, i) => _buildStatCard(cards[i]),
      );
    });
  }

  Widget _buildStatCard(_Card card) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: card.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(card.icon, color: card.color, size: 20),
              ),
              Text(card.subtitle,
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: card.color)),
              Text(card.title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyOverview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pharmacy Network',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${_pharmacies.length} pharmacies',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_pharmacies.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child:
                      Text('No pharmacies yet. Add one from the Pharmacies tab.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pharmacies.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) => _buildPharmacyRow(_pharmacies[i]),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPharmacyRow(Map<String, dynamic> p) {
    final isActive = p['is_active'] as bool? ?? true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_pharmacy,
              color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'] ?? 'N/A',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(p['address'] ?? '',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'Active' : 'Suspended',
              style: TextStyle(
                color: isActive
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic val) {
    if (val == null) return '0.00';
    return (double.tryParse(val.toString()) ?? 0).toStringAsFixed(2);
  }
}

class _Card {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  _Card(this.title, this.value, this.icon, this.color, this.subtitle);
}