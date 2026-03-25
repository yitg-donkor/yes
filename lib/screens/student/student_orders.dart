import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class StudentOrdersPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final Function(List<Map<String, dynamic>>) onUpdateCart;
  final Map<String, dynamic>? profile;
  final VoidCallback onOrderPlaced;

  const StudentOrdersPage({
    super.key,
    required this.cart,
    required this.onUpdateCart,
    this.profile,
    required this.onOrderPlaced,
  });

  @override
  State<StudentOrdersPage> createState() => _StudentOrdersPageState();
}

class _StudentOrdersPageState extends State<StudentOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _delivery = 'pickup';
  String _payment = 'cash';
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<Map<String, dynamic>> _orders = [];
  bool _loadingOrders = true;
  bool _placingOrder = false;
  String? _selectedOrderId; // for expanded detail view

  RealtimeChannel? _ordersChannel;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadOrders();
    _setupRealtime();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _ordersChannel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtime() {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    // Re-load orders whenever a change happens to the orders table
    _ordersChannel = SupabaseService.subscribeToOrders((_) {
      if (mounted) _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) {
      if (mounted) setState(() => _loadingOrders = false);
      return;
    }
    try {
      final orders = await SupabaseService.getStudentOrders(uid);
      if (mounted) setState(() { _orders = orders; _loadingOrders = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  double get _total => widget.cart.fold(
        0,
        (sum, item) =>
            sum +
            ((double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0) *
                (item['quantity'] as int? ?? 1)),
      );

  Future<void> _placeOrder() async {
    if (widget.cart.isEmpty) return;
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    if (_delivery == 'delivery' && _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your delivery address.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shopping_cart_checkout, color: Color(0xFF2E7D32)),
            SizedBox(width: 10),
            Text('Confirm Order'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...widget.cart.map((item) {
                    final price = double.tryParse(
                            item['unit_price']?.toString() ?? '0') ?? 0;
                    final qty = item['quantity'] as int? ?? 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item['product_name']} × $qty',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            'GH₵ ${(price * qty).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        'GH₵ ${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                            fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                _delivery == 'pickup'
                    ? 'Pickup from pharmacy'
                    : 'Delivery to: ${_addressCtrl.text}',
                style: const TextStyle(fontSize: 13),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.payment_outlined,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                _paymentLabel(_payment),
                style: const TextStyle(fontSize: 13),
              ),
            ]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Place Order'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _placingOrder = true);
    try {
      await SupabaseService.createOrder(
        pharmacyId: widget.cart.first['pharmacy_id'] as String,
        studentId: uid,
        items: widget.cart,
        totalAmount: _total,
        paymentMethod: _payment,
        deliveryMethod: _delivery,
        deliveryAddress:
            _delivery == 'delivery' ? _addressCtrl.text.trim() : null,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      widget.onOrderPlaced();
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Order placed! We\'ll notify you of updates.'),
            ]),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 4),
          ),
        );
        _tabs.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  String _paymentLabel(String p) => switch (p) {
        'mobile_money' => 'Mobile Money',
        'card' => 'Card Payment',
        _ => 'Cash on Pickup',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Cart'),
                  if (widget.cart.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.cart.length}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('My Orders'),
                  if (_orders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_orders.length}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildCart(), _buildOrderHistory()],
      ),
    );
  }

  // ─── CART TAB ─────────────────────────────────────────────────────────────

  Widget _buildCart() {
    if (widget.cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Your cart is empty',
                style:
                    TextStyle(fontSize: 18, color: Colors.grey.shade400)),
            const SizedBox(height: 8),
            Text('Add medicines from the shop',
                style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cart items
              ...widget.cart.map((item) => _buildCartItem(item)),
              const SizedBox(height: 20),

              // Delivery method
              _buildSection('Delivery Method', [
                _deliveryOption(
                  'pickup',
                  'Pickup from pharmacy',
                  Icons.store_outlined,
                  'Ready when confirmed',
                ),
                const SizedBox(height: 8),
                _deliveryOption(
                  'delivery',
                  'Delivery to address',
                  Icons.delivery_dining_outlined,
                  'Additional delivery time applies',
                ),
                if (_delivery == 'delivery') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Delivery Address',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 16),

              // Payment method
              _buildSection('Payment Method', [
                DropdownButtonFormField<String>(
                  value: _payment,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.payment_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'cash', child: Text('Cash on Pickup')),
                    DropdownMenuItem(
                        value: 'mobile_money', child: Text('Mobile Money')),
                    DropdownMenuItem(
                        value: 'card', child: Text('Card Payment')),
                  ],
                  onChanged: (v) => setState(() => _payment = v!),
                ),
              ]),
              const SizedBox(height: 16),

              // Notes
              _buildSection('Additional Notes (optional)', [
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Any special instructions...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 100), // space for bottom bar
            ],
          ),
        ),

        // Checkout bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(
                    'GH₵ ${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _placingOrder ? null : _placeOrder,
                    icon: _placingOrder
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.shopping_cart_checkout),
                    label: Text(
                      _placingOrder ? 'Placing Order...' : 'Place Order',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deliveryOption(
      String value, String label, IconData icon, String subtitle) {
    final selected = _delivery == value;
    return GestureDetector(
      onTap: () => setState(() => _delivery = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2E7D32).withOpacity(0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFF2E7D32)
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? const Color(0xFF2E7D32)
                    : Colors.grey,
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? const Color(0xFF2E7D32)
                              : Colors.black87)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF2E7D32), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final price =
        double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0;
    final qty = item['quantity'] as int? ?? 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medication,
                  color: Color(0xFF2E7D32), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['product_name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'GH₵ ${price.toStringAsFixed(2)} each',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    final newCart =
                        List<Map<String, dynamic>>.from(widget.cart);
                    if (qty <= 1) {
                      newCart.remove(item);
                    } else {
                      item['quantity'] = qty - 1;
                    }
                    widget.onUpdateCart(newCart);
                  },
                  icon: const Icon(Icons.remove_circle_outline, size: 22),
                  color: Colors.grey,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('$qty',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => item['quantity'] = qty + 1);
                    widget.onUpdateCart(widget.cart);
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  color: const Color(0xFF2E7D32),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: Text(
                'GH₵ ${(price * qty).toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32)),
                textAlign: TextAlign.right,
              ),
            ),
            IconButton(
              onPressed: () {
                final newCart =
                    List<Map<String, dynamic>>.from(widget.cart);
                newCart.remove(item);
                widget.onUpdateCart(newCart);
              },
              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // ─── ORDER HISTORY TAB ────────────────────────────────────────────────────

  Widget _buildOrderHistory() {
    if (_loadingOrders) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No orders yet',
                style:
                    TextStyle(fontSize: 18, color: Colors.grey.shade400)),
            const SizedBox(height: 8),
            Text('Your orders will appear here',
                style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabs.animateTo(0),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Start Shopping'),
            ),
          ],
        ),
      );
    }

    // Group active vs past orders
    final activeOrders = _orders
        .where((o) =>
            !['completed', 'cancelled'].contains(o['status']))
        .toList();
    final pastOrders = _orders
        .where((o) =>
            ['completed', 'cancelled'].contains(o['status']))
        .toList();

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activeOrders.isNotEmpty) ...[
            _sectionHeader('Active Orders', activeOrders.length),
            const SizedBox(height: 8),
            ...activeOrders.map((o) => _buildOrderCard(o)),
            const SizedBox(height: 16),
          ],
          if (pastOrders.isNotEmpty) ...[
            _sectionHeader('Past Orders', pastOrders.length),
            const SizedBox(height: 8),
            ...pastOrders.map((o) => _buildOrderCard(o)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600)),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    final items = order['order_items'] as List? ?? [];
    final total =
        double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0;
    final orderId = order['id'] as String;
    final isExpanded = _selectedOrderId == orderId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isExpanded
            ? BorderSide(color: color.withOpacity(0.4), width: 1.5)
            : BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Main row — tap to expand
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() =>
                _selectedOrderId = isExpanded ? null : orderId),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(status),
                                color: color, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              status[0].toUpperCase() +
                                  status.substring(1),
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        order['receipt_number'] ?? '',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          items.isEmpty
                              ? 'No items'
                              : items.length == 1
                                  ? items[0]['product_name'] ?? ''
                                  : '${items[0]['product_name']} + ${items.length - 1} more',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'GH₵ ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                            fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_deliveryLabel(order['delivery_method'])} · ${_paymentLabel(order['payment_method'] ?? 'cash')}',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Expanded detail view
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // All items
                  const Text('Items',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.medication,
                                  color: Color(0xFF2E7D32), size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${item['product_name']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              '× ${item['quantity']}',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'GH₵ ${(double.tryParse(item['subtotal']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      )),

                  const Divider(height: 20),

                  // Order info
                  _detailRow('Receipt Number',
                      order['receipt_number'] ?? 'N/A'),
                  _detailRow('Delivery',
                      _deliveryLabel(order['delivery_method'])),
                  if (order['delivery_address'] != null)
                    _detailRow(
                        'Address', order['delivery_address']),
                  _detailRow('Payment',
                      _paymentLabel(order['payment_method'] ?? 'cash')),
                  if (order['notes'] != null)
                    _detailRow('Notes', order['notes']),
                  const SizedBox(height: 8),

                  // Total
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(
                        'GH₵ ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),

                  // Status timeline
                  const SizedBox(height: 16),
                  _buildStatusTimeline(status),

                  // Cancel button for pending orders
                  if (status == 'pending') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _cancelOrder(orderId),
                        icon: const Icon(Icons.cancel_outlined,
                            size: 16),
                        label: const Text('Cancel Order'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    final steps = [
      ('pending', 'Order Placed', Icons.shopping_cart_outlined),
      ('confirmed', 'Confirmed', Icons.thumb_up_outlined),
      ('processing', 'Processing', Icons.settings_outlined),
      ('ready', 'Ready', Icons.store_outlined),
      ('completed', 'Completed', Icons.check_circle_outline),
    ];

    final currentIdx =
        steps.indexWhere((s) => s.$1 == currentStatus);
    final isCancelled = currentStatus == 'cancelled';

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade700, size: 18),
            const SizedBox(width: 8),
            Text('Order was cancelled',
                style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Progress',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 10),
        Row(
          children: steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isDone = i <= currentIdx;
            final isCurrent = i == currentIdx;
            final color = isDone
                ? const Color(0xFF2E7D32)
                : Colors.grey.shade300;

            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDone
                              ? color
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: color, width: isCurrent ? 2 : 1),
                        ),
                        child: Icon(step.$3,
                            size: 14,
                            color: isDone
                                ? Colors.white
                                : Colors.grey.shade400),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.$2,
                        style: TextStyle(
                          fontSize: 9,
                          color: isDone
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade400,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  if (i < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 18),
                        color: i < currentIdx
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade200,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
            'Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await SupabaseService.updateOrderStatus(orderId, 'cancelled');
      _loadOrders();
      if (mounted) {
        setState(() => _selectedOrderId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to cancel: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  String _deliveryLabel(dynamic v) =>
      v == 'delivery' ? 'Delivery' : 'Pickup';

  Color _statusColor(String s) => switch (s) {
        'completed' => Colors.green,
        'confirmed' => Colors.blue,
        'processing' => Colors.orange,
        'ready' => Colors.teal,
        'cancelled' => Colors.red,
        _ => Colors.orange,
      };

  IconData _statusIcon(String s) => switch (s) {
        'completed' => Icons.check_circle,
        'confirmed' => Icons.thumb_up,
        'processing' => Icons.settings,
        'ready' => Icons.store,
        'cancelled' => Icons.cancel,
        _ => Icons.pending,
      };
}