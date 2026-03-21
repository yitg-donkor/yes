import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class StudentShopPage extends StatefulWidget {
  final Function(Map<String, dynamic>, int) onAddToCart;
  const StudentShopPage({super.key, required this.onAddToCart});
  @override
  State<StudentShopPage> createState() => _StudentShopPageState();
}

class _StudentShopPageState extends State<StudentShopPage> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String _search = '';
  String _category = 'All';
  bool _inStockOnly = true;
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products = await SupabaseService.getProducts(
      search: _search.isEmpty ? null : _search,
      category: _category,
      inStockOnly: _inStockOnly,
    );
    final cats = await SupabaseService.getProductCategories();
    if (mounted) {
      setState(() {
        _products = products;
        _categories = cats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Medicine Shop'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                _search = v;
                _load();
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _categories.map((cat) {
                          final selected = _category == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: selected,
                              selectedColor: Colors.green.shade100,
                              checkmarkColor: const Color(0xFF2E7D32),
                              labelStyle: TextStyle(
                                color:
                                    selected
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              onSelected: (_) {
                                setState(() => _category = cat);
                                _load();
                              },
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Text('In Stock', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _inStockOnly,
                      onChanged: (v) {
                        setState(() => _inStockOnly = v);
                        _load();
                      },
                      activeThumbColor: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child:
                _loading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    )
                    : _products.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No medicines found',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                        itemCount: _products.length,
                        itemBuilder: (ctx, i) => _buildCard(_products[i]),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> p) {
    final qty = p['quantity'] as int? ?? 0;
    final isOut = qty == 0;
    final isLow = qty > 0 && qty < 10;
    final requiresRx = p['requires_prescription'] as bool? ?? false;
    final price = double.tryParse(p['unit_price']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: () => _showDetail(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 70,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.medication,
                        color: Color(0xFF2E7D32),
                        size: 32,
                      ),
                    ),
                  ),
                  if (requiresRx)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Rx',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (isLow)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Only $qty left',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                p['name'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                p['category'] ?? 'General',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GH₵ ${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 36,
                child:
                    isOut
                        ? Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Out of Stock',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        )
                        : ElevatedButton.icon(
                          onPressed: () => widget.onAddToCart(p, 1),
                          icon: const Icon(Icons.add_shopping_cart, size: 14),
                          label: const Text(
                            'Add',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> p) {
    int qty = 1;
    final maxQty = p['quantity'] as int? ?? 0;
    final price = double.tryParse(p['unit_price']?.toString() ?? '0') ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setSt) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.medication,
                              color: Color(0xFF2E7D32),
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  p['category'] ?? 'General',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'GH₵ ${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      if (p['description'] != null &&
                          p['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          p['description'],
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _infoChip(
                            'Stock: $maxQty',
                            Icons.inventory,
                            Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          if (p['requires_prescription'] == true)
                            _infoChip(
                              'Prescription required',
                              Icons.medical_services,
                              Colors.orange,
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Text(
                            'Quantity:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed:
                                qty > 1 ? () => setSt(() => qty--) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$qty',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          IconButton(
                            onPressed:
                                qty < maxQty ? () => setSt(() => qty++) : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: GH₵ ${(price * qty).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed:
                              maxQty > 0
                                  ? () {
                                    widget.onAddToCart(p, qty);
                                    Navigator.pop(ctx);
                                  }
                                  : null,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text(
                            'Add to Cart',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _infoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
