import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});
  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String _search = '';
  String _category = 'All';
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

  void _showForm([Map<String, dynamic>? item]) {
    showDialog(
      context: context,
      builder: (_) => _ProductDialog(item: item, onSaved: _load),
    );
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Product'),
            content: const Text(
              'Are you sure you want to delete this product?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await SupabaseService.deleteProduct(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (v) {
                    _search = v;
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _category,
                items:
                    _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (v) {
                  setState(() => _category = v!);
                  _load();
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Product'),
              ),
            ],
          ),
        ),

        Expanded(
          child:
              _loading
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  )
                  : RefreshIndicator(
                    onRefresh: _load,
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        final cols =
                            constraints.maxWidth > 1100
                                ? 4
                                : constraints.maxWidth > 750
                                ? 3
                                : constraints.maxWidth > 500
                                ? 2
                                : 1;
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.1,
                              ),
                          itemCount: _products.length,
                          itemBuilder:
                              (ctx, i) => _buildProductCard(_products[i]),
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    final qty = p['quantity'] as int? ?? 0;
    final isLow = qty < 10;
    final isOut = qty == 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: Color(0xFF2E7D32),
                    size: 18,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _showForm(p);
                    if (v == 'delete') _delete(p['id']);
                  },
                  itemBuilder:
                      (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                  child: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              p['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              p['category'] ?? 'General',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GH₵ ${(double.tryParse(p['unit_price']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isOut
                            ? Colors.red.shade50
                            : isLow
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOut
                        ? 'Out of stock'
                        : isLow
                        ? 'Low: $qty'
                        : 'In stock: $qty',
                    style: TextStyle(
                      color:
                          isOut
                              ? Colors.red.shade700
                              : isLow
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;
  const _ProductDialog({this.item, required this.onSaved});
  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController();
  final _category = TextEditingController();
  final _expiry = TextEditingController();
  bool _requiresPrescription = false;
  bool _saving = false;
  List<Map<String, dynamic>> _suppliers = [];
  String? _selectedSupplier;

  @override
  void initState() {
    super.initState();
    final p = widget.item;
    if (p != null) {
      _name.text = p['name'] ?? '';
      _desc.text = p['description'] ?? '';
      _price.text = p['unit_price']?.toString() ?? '';
      _qty.text = p['quantity']?.toString() ?? '';
      _category.text = p['category'] ?? 'General';
      _expiry.text = p['latest_expiry_date'] ?? '';
      _requiresPrescription = p['requires_prescription'] ?? false;
      _selectedSupplier = p['supplier_id'];
    }
    SupabaseService.getSuppliers().then((s) {
      if (mounted) setState(() => _suppliers = s);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = {
      'name': _name.text,
      'description': _desc.text,
      'unit_price': double.tryParse(_price.text) ?? 0,
      'quantity': int.tryParse(_qty.text) ?? 0,
      'category': _category.text.isEmpty ? 'General' : _category.text,
      'requires_prescription': _requiresPrescription,
      'latest_expiry_date': _expiry.text.isEmpty ? null : _expiry.text,
      if (_selectedSupplier != null) 'supplier_id': _selectedSupplier,
    };
    if (widget.item == null) {
      await SupabaseService.addProduct(data);
    } else {
      await SupabaseService.updateProduct(widget.item!['id'], data);
    }
    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Product' : 'Edit Product'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tf(_name, 'Product Name', Icons.inventory),
              const SizedBox(height: 12),
              _tf(_desc, 'Description (optional)', Icons.description),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _tf(
                      _price,
                      'Unit Price (GH₵)',
                      Icons.attach_money,
                      isNum: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _tf(_qty, 'Quantity', Icons.numbers, isNum: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _tf(_category, 'Category', Icons.category),
              const SizedBox(height: 12),
              _tf(_expiry, 'Expiry Date (YYYY-MM-DD)', Icons.calendar_today),
              const SizedBox(height: 12),
              if (_suppliers.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _selectedSupplier,
                  decoration: InputDecoration(
                    labelText: 'Supplier',
                    prefixIcon: const Icon(Icons.local_shipping),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items:
                      _suppliers
                          .map(
                            (s) => DropdownMenuItem(
                              value: s['id'] as String,
                              child: Text(s['name'] as String),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selectedSupplier = v),
                ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text(
                  'Requires Prescription',
                  style: TextStyle(fontSize: 14),
                ),
                value: _requiresPrescription,
                onChanged: (v) => setState(() => _requiresPrescription = v),
                activeThumbColor: const Color(0xFF2E7D32),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child:
              _saving
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Save'),
        ),
      ],
    );
  }

  Widget _tf(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNum = false,
  }) => TextField(
    controller: ctrl,
    keyboardType: isNum ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
