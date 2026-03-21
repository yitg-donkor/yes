import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});
  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _filterStatus = 'All';
  String? _error;
  RealtimeChannel? _channel;
  // Track which order is currently being updated
  String? _updatingOrderId;

  final _statuses = [
    'All',
    'pending',
    'confirmed',
    'processing',
    'ready',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _channel = SupabaseService.subscribeToOrders((_) {
      debugPrint('🔔 Realtime: orders table changed, reloading...');
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    debugPrint('📦 Loading orders... filter=$_filterStatus');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await SupabaseService.getAllOrders(
        status: _filterStatus == 'All' ? null : _filterStatus,
      );
      debugPrint('✅ Loaded ${orders.length} orders');
      if (mounted)
        setState(() {
          _orders = orders;
          _loading = false;
        });
    } catch (e) {
      debugPrint('❌ Load orders error: $e');
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.toString();
        });
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    debugPrint('🔄 Attempting to update order $orderId → $newStatus');
    debugPrint('👤 Current user ID: ${SupabaseService.currentUserId}');

    setState(() => _updatingOrderId = orderId);

    try {
      // Step 1: Check current order state before update
      final before = await SupabaseService.client
          .from('orders')
          .select('id, status')
          .eq('id', orderId)
          .single();
      debugPrint('📋 Order BEFORE update: $before');

      // Step 2: Do the update
      debugPrint('⬆️ Sending update to Supabase...');
      final updateResult = await SupabaseService.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId)
          .select();
      debugPrint('📤 Update result: $updateResult');
      debugPrint('📊 Rows affected: ${(updateResult as List).length}');

      if ((updateResult as List).isEmpty) {
        debugPrint('⚠️ Zero rows updated — RLS is blocking the update');
        debugPrint('💡 Run fix_orders_rls_v2.sql in your Supabase SQL Editor');
        throw Exception(
          'RLS blocked the update — 0 rows affected.\n'
          'Run fix_orders_rls_v2.sql in Supabase SQL Editor.',
        );
      }

      // Step 3: Verify the update went through
      final after = await SupabaseService.client
          .from('orders')
          .select('id, status')
          .eq('id', orderId)
          .single();
      debugPrint('✅ Order AFTER update: $after');
      debugPrint('🎉 Status successfully changed to: ${after['status']}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Order marked as $newStatus'),
            backgroundColor: _statusColor(newStatus),
            duration: const Duration(seconds: 2),
          ),
        );
        _load();
      }
    } catch (e, stack) {
      debugPrint('❌ Update failed: $e');
      debugPrint('📍 Stack trace: $stack');
      if (mounted) {
        setState(() => _updatingOrderId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingOrderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statuses.map((s) {
                      final selected = _filterStatus == s;
                      final color = _statusColor(s);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            s == 'All'
                                ? 'All Orders'
                                : s[0].toUpperCase() + s.substring(1),
                          ),
                          selected: selected,
                          selectedColor: color.withOpacity(0.15),
                          checkmarkColor: color,
                          labelStyle: TextStyle(
                            color: selected ? color : Colors.grey.shade600,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
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
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _load,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // Error banner
        if (_error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),

        // Order count
        if (!_loading && _error == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  '${_orders.length} order${_orders.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const Spacer(),
                // Debug info
                Text(
                  'User: ${SupabaseService.currentUserId?.substring(0, 8) ?? 'none'}...',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),

        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                )
              : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No orders found',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (ctx, i) => _buildOrderCard(_orders[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    final studentName = order['profiles']?['name'] ?? 'Unknown Student';
    final studentId = order['profiles']?['student_id'] ?? '';
    final items = order['order_items'] as List? ?? [];
    final total =
        double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0;
    final orderId = order['id'] as String? ?? '';
    final isUpdating = _updatingOrderId == orderId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isUpdating
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Icon(Icons.receipt_long, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['receipt_number'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '$studentName${studentId.isNotEmpty ? ' ($studentId)' : ''}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      // Debug: show order ID
                      Text(
                        'ID: $orderId',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...items
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fiber_manual_record,
                          size: 6,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item['product_name']} × ${item['quantity']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          'GH₵ ${(double.tryParse(item['subtotal']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
            if (items.length > 3)
              Text(
                '+${items.length - 3} more items',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),

            const Divider(height: 20),

            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  '${order['delivery_method'] ?? 'pickup'} · ${order['payment_method'] ?? 'cash'}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'GH₵ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),

            if (status != 'completed' && status != 'cancelled') ...[
              const SizedBox(height: 12),
              isUpdating
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Updating...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : _buildActionButtons(orderId, status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String orderId, String currentStatus) {
    return Row(
      children: [
        if (currentStatus == 'pending') ...[
          _actionBtn(
            'Confirm',
            Colors.blue,
            Icons.thumb_up_outlined,
            () => _updateStatus(orderId, 'confirmed'),
          ),
          const SizedBox(width: 8),
          _actionBtn(
            'Cancel',
            Colors.red,
            Icons.cancel_outlined,
            () => _updateStatus(orderId, 'cancelled'),
            outlined: true,
          ),
        ],
        if (currentStatus == 'confirmed')
          _actionBtn(
            'Mark Processing',
            Colors.orange,
            Icons.settings_outlined,
            () => _updateStatus(orderId, 'processing'),
          ),
        if (currentStatus == 'processing')
          _actionBtn(
            'Mark Ready',
            Colors.teal,
            Icons.store_outlined,
            () => _updateStatus(orderId, 'ready'),
          ),
        if (currentStatus == 'ready')
          _actionBtn(
            'Complete',
            Colors.green,
            Icons.check_circle_outline,
            () => _updateStatus(orderId, 'completed'),
          ),
      ],
    );
  }

  Widget _actionBtn(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        elevation: 0,
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'completed' => Colors.green,
    'confirmed' => Colors.blue,
    'processing' => Colors.orange,
    'ready' => Colors.teal,
    'cancelled' => Colors.red,
    'All' => Colors.grey,
    _ => Colors.orange,
  };
}
 