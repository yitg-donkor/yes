import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  List<Map<String, dynamic>> _recentOrders = [];
  late final _ordersChannel = SupabaseService.subscribeToOrders((_) => _loadData());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _ordersChannel.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final stats = await SupabaseService.getDashboardStats();
      final orders = await SupabaseService.getAllOrders();
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentOrders = orders.take(5).toList();
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(),
            const SizedBox(height: 24),
            _buildStatCards(),
            const SizedBox(height: 24),
            _buildSecondaryStats(),
            const SizedBox(height: 24),
            _buildRecentOrders(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
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
                Text(
                  'Welcome back!',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pharma One Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_stats['pendingOrders'] ?? 0} orders awaiting processing',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.local_pharmacy, color: Colors.white24, size: 80),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    final cards = [
      _StatCard('Medicines Available', '${_stats['medicinesAvailable'] ?? 0}', Icons.medication, Colors.blue, 'In stock'),
      _StatCard('Medicine Shortage', '${_stats['medicineShortage'] ?? 0}', Icons.warning_amber, Colors.orange, 'Low stock items'),
      _StatCard('Total Revenue', 'GH₵ ${_formatNum(_stats['revenue'])}', Icons.account_balance_wallet, Colors.green, 'All time'),
      _StatCard('Pending Orders', '${_stats['pendingOrders'] ?? 0}', Icons.pending_actions, Colors.red, 'Need attention'),
    ];
    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth > 800 ? 4 : constraints.maxWidth > 500 ? 2 : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.6,
        ),
        itemCount: cards.length,
        itemBuilder: (ctx, i) => _buildStatCard(cards[i]),
      );
    });
  }

  Widget _buildStatCard(_StatCard card) {
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
              Text(card.subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: card.color)),
              Text(card.title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStats() {
    return Row(
      children: [
        Expanded(child: _buildInfoCard('Inventory', [
          _InfoItem('Total Medicines', '${_stats['totalMedicines'] ?? 0}'),
          _InfoItem('Qty Sold', _formatNum(_stats['qtyMedicinesSold'])),
        ])),
        const SizedBox(width: 16),
        Expanded(child: _buildInfoCard('Network', [
          _InfoItem('Total Suppliers', '${_stats['totalSuppliers'] ?? 0}'),
          _InfoItem('Employees', '${_stats['totalEmployees'] ?? 0}'),
        ])),
        const SizedBox(width: 16),
        Expanded(child: _buildInfoCard('Customers', [
          _InfoItem('Registered Students', '${_stats['totalCustomers'] ?? 0}'),
          _InfoItem('Top Product', '${_stats['frequentItem'] ?? 'N/A'}'),
        ])),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<_InfoItem> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                Text(item.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
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
                const Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Live', style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          if (_recentOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('No orders yet', style: TextStyle(color: Colors.grey.shade400))),
            )
          else
            ...(_recentOrders.map((order) => _buildOrderRow(order))),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final statusColor = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['receipt_number'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Text(
                  order['profiles']?['name'] ?? 'Unknown student',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Text(
            'GH₵ ${_formatNum(order['total_amount'])}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'completed' => Colors.green,
    'confirmed' || 'processing' => Colors.blue,
    'ready' => Colors.teal,
    'cancelled' => Colors.red,
    _ => Colors.orange,
  };

  String _formatNum(dynamic val) {
    if (val == null) return '0';
    final n = double.tryParse(val.toString()) ?? 0;
    return n.toStringAsFixed(2);
  }
}

class _StatCard {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  _StatCard(this.title, this.value, this.icon, this.color, this.subtitle);
}

class _InfoItem {
  final String label, value;
  _InfoItem(this.label, this.value);
}
