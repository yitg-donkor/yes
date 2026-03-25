import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class SuperAdminOrdersPage extends StatefulWidget {
  const SuperAdminOrdersPage({super.key});

  @override
  State<SuperAdminOrdersPage> createState() => _SuperAdminOrdersPageState();
}

class _SuperAdminOrdersPageState extends State<SuperAdminOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _pharmacies = [];
  bool _loading = true;
  String _filterStatus = 'All';
  String _filterPharmacy = 'All';

  final _statuses = ['All', 'pending', 'confirmed', 'processing', 'ready', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      SupabaseService.getAllOrders(status: _filterStatus == 'All' ? null : _filterStatus),
      SupabaseService.getPharmacies(),
    ]);
    if (mounted) {
      setState(() {
        _orders = results[0] as List<Map<String, dynamic>>;
        _pharmacies = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterPharmacy == 'All') return _orders;
    return _orders.where((o) => o['pharmacy_id'] == _filterPharmacy).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Status filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statuses.map((s) {
                    final selected = _filterStatus == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s == 'All' ? 'All' : s[0].toUpperCase() + s.substring(1)),
                        selected: selected,
                        selectedColor: _statusColor(s).withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: selected ? _statusColor(s) : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        onSelected: (_) {
                          setState(() => _filterStatus = s);
                          _load();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              // Pharmacy filter
              Row(
                children: [
                  const Text('Pharmacy: ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _filterPharmacy,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem(value: 'All', child: Text('All Pharmacies')),
                        ..._pharmacies.map((p) => DropdownMenuItem(
                              value: p['id'] as String,
                              child: Text(p['name'] as String),
                            )),
                      ],
                      onChanged: (v) => setState(() => _filterPharmacy = v!),
                    ),
                  ),
                  Text('${_filtered.length} orders',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
              : _filtered.isEmpty
                  ? Center(
                      child: Text('No orders found',
                          style: TextStyle(color: Colors.grey.shade400)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) => _buildOrderCard(_filtered[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    final pharmacyName = order['pharmacies']?['name'] ?? 'Unknown Pharmacy';
    final studentName = order['profiles']?['name'] ?? 'Unknown Student';
    final total = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.receipt_long, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order['receipt_number'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(studentName,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  Row(
                    children: [
                      Icon(Icons.local_pharmacy, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(pharmacyName,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                Text('GH₵ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'completed' => Colors.green,
    'confirmed' => Colors.blue,
    'processing' => Colors.orange,
    'ready' => Colors.teal,
    'cancelled' => Colors.red,
    _ => Colors.orange,
  };
}
