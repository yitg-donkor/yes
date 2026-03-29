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
  List<Map<String, dynamic>> _pharmacies = [];
  bool _loading = true;
  String _search = '';
  String _category = 'All';
  bool _inStockOnly = true;
  List<String> _categories = ['All'];

  String? _selectedPharmacyId;
  String _selectedPharmacyName = 'All Pharmacies';

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    final pharmacies = await SupabaseService.getPharmacies(activeOnly: true);
    if (mounted) setState(() => _pharmacies = pharmacies);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final products = await SupabaseService.getProducts(
      pharmacyId: _selectedPharmacyId,
      search: _search.isEmpty ? null : _search,
      category: _category,
      inStockOnly: _inStockOnly,
    );
    final cats = await SupabaseService.getProductCategories(
      pharmacyId: _selectedPharmacyId,
    );
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
                _loadProducts();
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Pharmacy Selector ────────────────────────────────────────────
          if (_pharmacies.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Pharmacy',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _pharmacyChip(
                          null,
                          'All Pharmacies',
                          _selectedPharmacyId == null,
                        ),
                        ..._pharmacies.map(
                          (p) => _pharmacyChip(
                            p['id'] as String,
                            p['name'] as String,
                            _selectedPharmacyId == p['id'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedPharmacyId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Row(
                        children: [
                          FutureBuilder<double>(
                            future: SupabaseService.getPharmacyRating(
                              _selectedPharmacyId!,
                            ),
                            builder: (ctx, snap) {
                              final rating = snap.data ?? 0.0;
                              return Row(
                                children: [
                                  ...List.generate(
                                    5,
                                    (i) => Icon(
                                      i < rating.round()
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    rating == 0
                                        ? 'No ratings yet'
                                        : '${rating.toStringAsFixed(1)} / 5.0',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _showRateDialog(),
                                    child: Text(
                                      'Rate this pharmacy',
                                      style: TextStyle(
                                        color: Colors.amber.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // ── Category + Stock Filter ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final selected = _category == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: selected,
                            selectedColor: Colors.green.shade100,
                            checkmarkColor: const Color(0xFF2E7D32),
                            labelStyle: TextStyle(
                              color: selected
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              setState(() => _category = cat);
                              _loadProducts();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Text('In Stock', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _inStockOnly,
                      onChanged: (v) {
                        setState(() => _inStockOnly = v);
                        _loadProducts();
                      },
                      activeThumbColor: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Products Grid ────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
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
                    onRefresh: _loadProducts,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.68,
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

  Widget _pharmacyChip(String? id, String name, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPharmacyId = id;
          _selectedPharmacyName = name;
          _category = 'All';
        });
        _loadProducts();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              id == null ? Icons.store_rounded : Icons.local_pharmacy_rounded,
              size: 13,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Product Card with real image ─────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> p) {
    final qty = p['quantity'] as int? ?? 0;
    final isOut = qty == 0;
    final isLow = qty > 0 && qty < 10;
    final requiresRx = p['requires_prescription'] as bool? ?? false;
    final price = double.tryParse(p['unit_price']?.toString() ?? '0') ?? 0;
    final pharmacyName = p['pharmacies']?['name'] ?? '';
    final imageUrl = p['image_url'] as String?;

    return GestureDetector(
      onTap: () => _showDetail(p),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _iconPlaceholder(height: 120),
                          )
                        : _iconPlaceholder(height: 120),
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
                          horizontal: 5,
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
              const SizedBox(height: 2),
              Text(
                p['category'] ?? 'General',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),

              // Pharmacy label
              if (pharmacyName.isNotEmpty && _selectedPharmacyId == null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_pharmacy_outlined,
                        size: 10,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          pharmacyName,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),
              Text(
                'GH₵ ${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: isOut
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

  Widget _iconPlaceholder({double height = 44}) => Container(
    width: double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.medication, color: Color(0xFF2E7D32), size: 28),
  );

  // ── Product Detail Bottom Sheet with image ───────────────────────────────
  void _showDetail(Map<String, dynamic> p) {
    int qty = 1;
    final maxQty = p['quantity'] as int? ?? 0;
    final price = double.tryParse(p['unit_price']?.toString() ?? '0') ?? 0;
    final pharmacyName = p['pharmacies']?['name'] ?? '';
    final pharmacyId = p['pharmacy_id'] as String?;
    final imageUrl = p['image_url'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
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
              const SizedBox(height: 16),

              // ── Image banner ─────────────────────────────────────────
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.medication,
                          color: Color(0xFF2E7D32),
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.medication,
                      color: Color(0xFF2E7D32),
                      size: 56,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

              // Pharmacy info
              if (pharmacyName.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_pharmacy,
                        color: Colors.green.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available at',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              pharmacyName,
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (pharmacyId != null)
                        FutureBuilder<double>(
                          future: SupabaseService.getPharmacyRating(pharmacyId),
                          builder: (ctx, snap) {
                            final rating = snap.data ?? 0.0;
                            if (rating == 0) return const SizedBox();
                            return Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],

              if (p['description'] != null &&
                  p['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  p['description'],
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  _infoChip('Stock: $maxQty', Icons.inventory, Colors.blue),
                  const SizedBox(width: 8),
                  if (p['requires_prescription'] == true)
                    _infoChip(
                      'Prescription required',
                      Icons.medical_services,
                      Colors.orange,
                    ),
                ],
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Quantity:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: qty > 1 ? () => setSt(() => qty--) : null,
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
                    onPressed: qty < maxQty ? () => setSt(() => qty++) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
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
                  onPressed: maxQty > 0
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showRateDialog() {
    if (_selectedPharmacyId == null) return;
    int selectedRating = 0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Rate $_selectedPharmacyName'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setSt(() => selectedRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        i < selectedRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write a review (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () async {
                      await SupabaseService.submitReview(
                        pharmacyId: _selectedPharmacyId!,
                        rating: selectedRating,
                        comment: commentCtrl.text.trim().isEmpty
                            ? null
                            : commentCtrl.text.trim(),
                      );
                      Navigator.pop(ctx);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Review submitted!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
              child: const Text('Submit'),
            ),
          ],
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
