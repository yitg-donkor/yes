// admin_remaining.dart — fixed version
import 'package:flutter/material.dart';
import 'package:group_9/services/pharmacy_context.dart';
import '../../services/supabase_service.dart';
import 'generic_crud_page.dart';

// ─── admin_branches.dart

class AdminBranchesPage extends StatelessWidget {
  const AdminBranchesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return GenericCrudPage(
      title: 'Branches',
      icon: Icons.location_on_rounded,
      color: const Color(0xFF00838F),
      fetchItems: SupabaseService.getBranches,
      displayColumns: const ['name', 'address', 'contact'],
      columnLabels: const ['Name', 'Address', 'Contact'],
      onAdd: (ctx, refresh) => _show(ctx, null, refresh),
      onEdit: (ctx, item, refresh) => _show(ctx, item, refresh),
      onDelete: SupabaseService.deleteBranch,
    );
  }

  void _show(
    BuildContext ctx,
    Map<String, dynamic>? item,
    VoidCallback refresh,
  ) async {
    final pharmacies = await SupabaseService.getPharmacies();
    final name = TextEditingController(text: item?['name'] ?? '');
    final address = TextEditingController(text: item?['address'] ?? '');
    final contact = TextEditingController(text: item?['contact'] ?? '');
    // Pre-fill pharmacy from existing item or from current user's pharmacy
    final myPharmacyId = await PharmacyContext.getPharmacyId();
    String? selectedPharmacy = item?['pharmacy_id'] ?? myPharmacyId;

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          title: Text(item == null ? 'Add Branch' : 'Edit Branch'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pharmacies.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: pharmacies.any((p) => p['id'] == selectedPharmacy)
                        ? selectedPharmacy
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Pharmacy',
                      prefixIcon: const Icon(Icons.local_pharmacy),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: pharmacies
                        .map(
                          (p) => DropdownMenuItem(
                            value: p['id'] as String,
                            child: Text(p['name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setSt(() => selectedPharmacy = v),
                  ),
                const SizedBox(height: 12),
                _tf(name, 'Branch Name', Icons.location_on),
                const SizedBox(height: 12),
                _tf(address, 'Address', Icons.home),
                const SizedBox(height: 12),
                _tf(contact, 'Contact', Icons.phone),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx2),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                var data = <String, dynamic>{
                  'name': name.text,
                  'address': address.text,
                  'contact': contact.text,
                };
                if (item == null) {
                  // Prefer picker selection, fallback to PharmacyContext
                  if (selectedPharmacy != null) {
                    data['pharmacy_id'] = selectedPharmacy!;
                  } else {
                    data = await PharmacyContext.addPharmacyId(data);
                  }
                  await SupabaseService.addBranch(data);
                } else {
                  await SupabaseService.updateBranch(item['id'], data);
                }
                Navigator.pop(ctx2);
                refresh();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String l, IconData i) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}

// ─── admin_employees.dart ─────────────────────────────────────────────────────

class AdminEmployeesPage extends StatelessWidget {
  const AdminEmployeesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return GenericCrudPage(
      title: 'Employees',
      icon: Icons.badge_rounded,
      color: const Color(0xFFF57F17),
      fetchItems: SupabaseService.getEmployees,
      displayColumns: const ['name', 'position', 'email'],
      columnLabels: const ['Name', 'Position', 'Email'],
      onAdd: (ctx, refresh) => _show(ctx, null, refresh),
      onEdit: (ctx, item, refresh) => _show(ctx, item, refresh),
      onDelete: SupabaseService.deleteEmployee,
    );
  }

  void _show(
    BuildContext ctx,
    Map<String, dynamic>? item,
    VoidCallback refresh,
  ) async {
    final branches = await SupabaseService.getBranches();
    final name = TextEditingController(text: item?['name'] ?? '');
    final position = TextEditingController(text: item?['position'] ?? '');
    final email = TextEditingController(text: item?['email'] ?? '');
    final contact = TextEditingController(text: item?['contact'] ?? '');
    String? selectedBranch = item?['branch_id'];

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          title: Text(item == null ? 'Add Employee' : 'Edit Employee'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (branches.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: branches.any((b) => b['id'] == selectedBranch)
                          ? selectedBranch
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Branch (optional)',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('— No branch —'),
                        ),
                        ...branches.map(
                          (b) => DropdownMenuItem(
                            value: b['id'] as String,
                            child: Text(b['name'] as String),
                          ),
                        ),
                      ],
                      onChanged: (v) => setSt(() => selectedBranch = v),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Text(
                        'No branches found. Add a branch first if needed.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _tf(name, 'Employee Name *', Icons.person),
                  const SizedBox(height: 12),
                  _tf(position, 'Position', Icons.work),
                  const SizedBox(height: 12),
                  _tf(email, 'Email', Icons.email),
                  const SizedBox(height: 12),
                  _tf(contact, 'Contact', Icons.phone),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx2),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx2).showSnackBar(
                    const SnackBar(
                      content: Text('Employee name is required.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                var data = <String, dynamic>{
                  'name': name.text.trim(),
                  'position': position.text.trim(),
                  'email': email.text.trim(),
                  'contact': contact.text.trim(),
                  if (selectedBranch != null) 'branch_id': selectedBranch,
                };
                if (item == null) {
                  // Inject pharmacy_id so RLS allows the insert
                  data = await PharmacyContext.addPharmacyId(data);
                  await SupabaseService.addEmployee(data);
                } else {
                  await SupabaseService.updateEmployee(item['id'], data);
                }
                Navigator.pop(ctx2);
                refresh();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String l, IconData i) => TextField(
    controller: c,
    decoration: InputDecoration(
      labelText: l,
      prefixIcon: Icon(i),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

// ─── admin_suppliers.dart ─────────────────────────────────────────────────────

class AdminSuppliersPage extends StatelessWidget {
  const AdminSuppliersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return GenericCrudPage(
      title: 'Suppliers',
      icon: Icons.local_shipping_rounded,
      color: const Color(0xFF558B2F),
      fetchItems: SupabaseService.getSuppliers,
      displayColumns: const ['name', 'contact', 'product_type'],
      columnLabels: const ['Name', 'Contact', 'Product Type'],
      onAdd: (ctx, refresh) => _show(ctx, null, refresh),
      onEdit: (ctx, item, refresh) => _show(ctx, item, refresh),
      onDelete: SupabaseService.deleteSupplier,
    );
  }

  void _show(
    BuildContext ctx,
    Map<String, dynamic>? item,
    VoidCallback refresh,
  ) {
    final name = TextEditingController(text: item?['name'] ?? '');
    final contact = TextEditingController(text: item?['contact'] ?? '');
    final type = TextEditingController(text: item?['product_type'] ?? '');
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Add Supplier' : 'Edit Supplier'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tf(name, 'Supplier Name', Icons.business),
              const SizedBox(height: 12),
              _tf(contact, 'Contact', Icons.phone),
              const SizedBox(height: 12),
              _tf(type, 'Product Type', Icons.category),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'name': name.text,
                'contact': contact.text,
                'product_type': type.text,
              };
              if (item == null) {
                final dataWithPharmacy = await PharmacyContext.addPharmacyId(
                  data,
                );
                await SupabaseService.addSupplier(dataWithPharmacy);
              } else {
                await SupabaseService.updateSupplier(item['id'], data);
              }
              Navigator.pop(ctx);
              refresh();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _tf(TextEditingController c, String l, IconData i) => TextField(
    controller: c,
    decoration: InputDecoration(
      labelText: l,
      prefixIcon: Icon(i),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

// ─── admin_customers.dart ─────────────────────────────────────────────────────

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});
  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  List<Map<String, dynamic>> _customers = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Use a direct query filtered by role=student to avoid RLS issues
      final all = await SupabaseService.getAllProfiles();
      final students = all.where((x) => x['role'] == 'student').toList();
      if (mounted)
        setState(() {
          _customers = students;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.toString();
        });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _customers;
    return _customers
        .where(
          (c) =>
              (c['name']?.toString() ?? '').toLowerCase().contains(
                _search.toLowerCase(),
              ) ||
              (c['email']?.toString() ?? '').toLowerCase().contains(
                _search.toLowerCase(),
              ) ||
              (c['student_id']?.toString() ?? '').toLowerCase().contains(
                _search.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _load,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
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
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFC2185B)),
                )
              : _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _search.isEmpty
                            ? 'No registered customers yet'
                            : 'No results for "$_search"',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final c = _filtered[i];
                      final name = c['name'] ?? 'Unknown';
                      final initial = name.isNotEmpty
                          ? name[0].toUpperCase()
                          : '?';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFFC2185B,
                            ).withOpacity(0.1),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Color(0xFFC2185B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            [
                              if (c['student_id'] != null &&
                                  c['student_id'] != '')
                                'ID: ${c['student_id']}',
                              c['email'] ?? '',
                            ].where((s) => s.isNotEmpty).join(' · '),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Icon(
                            Icons.person_outline,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── admin_sales.dart ────────────────────────────────────────────────────────

class AdminSalesPage extends StatefulWidget {
  const AdminSalesPage({super.key});
  @override
  State<AdminSalesPage> createState() => _AdminSalesPageState();
}

class _AdminSalesPageState extends State<AdminSalesPage> {
  List<Map<String, dynamic>> _sales = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sales = await SupabaseService.getSales();
      if (mounted)
        setState(() {
          _sales = sales;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Text(
                'Sales Records',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddSale(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Sale'),
              ),
            ],
          ),
        ),
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
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                )
              : _sales.isEmpty && _error == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.point_of_sale_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No sales recorded yet',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddSale(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add First Sale'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sales.length,
                    itemBuilder: (ctx, i) {
                      final sale = _sales[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.point_of_sale,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            sale['product_name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${sale['employees']?['name'] ?? 'Staff'} · ${sale['payment_method'] ?? 'cash'} · Qty: ${sale['quantity'] ?? 1}',
                          ),
                          trailing: Text(
                            'GH₵ ${(double.tryParse(sale['total_cost']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showAddSale() async {
    List<Map<String, dynamic>> products = [];
    List<Map<String, dynamic>> employees = [];
    List<Map<String, dynamic>> customers = [];
    String? _loadError;

    try {
      final results = await Future.wait([
        SupabaseService.getProducts(),
        SupabaseService.getEmployees(),
        SupabaseService.getAllProfiles(),
      ]);
      products = results[0] as List<Map<String, dynamic>>;
      employees = results[1] as List<Map<String, dynamic>>;
      customers = (results[2] as List<Map<String, dynamic>>)
          .where((c) => c['role'] == 'student')
          .toList();
    } catch (e) {
      _loadError = e.toString();
    }

    if (!mounted) return;

    if (_loadError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data: $_loadError'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? productId, employeeId, customerId;
    final qty = TextEditingController(text: '1');
    String paymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Add Sale'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Employee
                  DropdownButtonFormField<String>(
                    value: null,
                    decoration: InputDecoration(
                      labelText: 'Employee (optional)',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('— None —'),
                      ),
                      ...employees.map(
                        (e) => DropdownMenuItem(
                          value: e['id'] as String,
                          child: Text(e['name'] as String),
                        ),
                      ),
                    ],
                    onChanged: (v) => setSt(() => employeeId = v),
                  ),
                  const SizedBox(height: 12),
                  // Customer
                  DropdownButtonFormField<String>(
                    value: null,
                    decoration: InputDecoration(
                      labelText: 'Customer (optional)',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('— Walk-in —'),
                      ),
                      ...customers.map(
                        (c) => DropdownMenuItem(
                          value: c['id'] as String,
                          child: Text(c['name'] as String),
                        ),
                      ),
                    ],
                    onChanged: (v) => setSt(() => customerId = v),
                  ),
                  const SizedBox(height: 12),
                  // Product — required
                  DropdownButtonFormField<String>(
                    value: null,
                    decoration: InputDecoration(
                      labelText: 'Product *',
                      prefixIcon: const Icon(Icons.medication_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p['id'] as String,
                            child: Text(
                              '${p['name']} — GH₵${(double.tryParse(p['unit_price']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setSt(() => productId = v),
                  ),
                  const SizedBox(height: 12),
                  // Quantity
                  TextField(
                    controller: qty,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Payment method
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon: const Icon(Icons.payment_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: ['cash', 'mobile_money', 'card']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setSt(() => paymentMethod = v ?? 'cash'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (productId == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a product.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final product = products.firstWhere(
                  (p) => p['id'] == productId,
                );
                final price =
                    double.tryParse(product['unit_price']?.toString() ?? '0') ??
                    0;
                final quantity = int.tryParse(qty.text) ?? 1;

                var saleData = <String, dynamic>{
                  'product_id': productId,
                  'product_name': product['name'],
                  'quantity': quantity,
                  'total_cost': price * quantity,
                  'status': 'completed',
                  'payment_method': paymentMethod,
                  'receipt_num': 'REC-${DateTime.now().millisecondsSinceEpoch}',
                  if (employeeId != null) 'employee_id': employeeId,
                  if (customerId != null) 'customer_id': customerId,
                };

                // Inject pharmacy_id so RLS allows the insert
                saleData = await PharmacyContext.addPharmacyId(saleData);

                try {
                  await SupabaseService.addSale(saleData);
                  Navigator.pop(ctx);
                  _load();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sale recorded successfully.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save sale: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── admin_receipts.dart ─────────────────────────────────────────────────────

class AdminReceiptsPage extends StatefulWidget {
  const AdminReceiptsPage({super.key});
  @override
  State<AdminReceiptsPage> createState() => _AdminReceiptsPageState();
}

class _AdminReceiptsPageState extends State<AdminReceiptsPage> {
  List<Map<String, dynamic>> _receipts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Receipts come from the orders table — that's what has receipt_number
      final orders = await SupabaseService.getAllOrders();
      if (mounted)
        setState(() {
          _receipts = orders;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_receipts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No receipts yet',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receipts.length,
        itemBuilder: (ctx, i) {
          final r = _receipts[i];
          final items = r['order_items'] as List? ?? [];
          final itemSummary = items.isEmpty
              ? 'No items'
              : items.map((it) => it['product_name']).take(2).join(', ') +
                    (items.length > 2 ? ' +${items.length - 2} more' : '');
          final status = r['status'] as String? ?? 'pending';
          final statusColor = _statusColor(status);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
              ),
              title: Text(
                r['receipt_number'] ?? 'N/A',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${r['profiles']?['name'] ?? 'Unknown'} · $itemSummary',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'GH₵ ${(double.tryParse(r['total_amount']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

// ─── admin_attendance.dart ────────────────────────────────────────────────────

class AdminAttendancePage extends StatefulWidget {
  const AdminAttendancePage({super.key});
  @override
  State<AdminAttendancePage> createState() => _AdminAttendancePageState();
}

class _AdminAttendancePageState extends State<AdminAttendancePage> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await SupabaseService.getAttendance();
      if (mounted)
        setState(() {
          _records = records;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Text(
                'Attendance Records',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Attendance'),
              ),
            ],
          ),
        ),
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
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                )
              : _records.isEmpty && _error == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No attendance records yet',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAdd,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Log First Attendance'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    itemBuilder: (ctx, i) {
                      final r = _records[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.cyan.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.access_time,
                              color: Colors.cyan.shade700,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            r['employees']?['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${r['date'] ?? 'N/A'} · In: ${r['check_in_time'] ?? '-'} · Out: ${r['check_out_time'] ?? '-'}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showAdd() async {
    List<Map<String, dynamic>> employees = [];
    try {
      employees = await SupabaseService.getEmployees();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load employees: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No employees found. Add employees first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? empId;
    final checkIn = TextEditingController(text: '08:00:00');
    final checkOut = TextEditingController();
    final date = TextEditingController(
      text: DateTime.now().toString().substring(0, 10),
    );

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Log Attendance'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: null,
                  decoration: InputDecoration(
                    labelText: 'Employee *',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: employees
                      .map(
                        (e) => DropdownMenuItem(
                          value: e['id'] as String,
                          child: Text(e['name'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setSt(() => empId = v),
                ),
                const SizedBox(height: 12),
                _tf(date, 'Date (YYYY-MM-DD)', Icons.calendar_today),
                const SizedBox(height: 12),
                _tf(checkIn, 'Check In (HH:MM:SS)', Icons.login),
                const SizedBox(height: 12),
                _tf(checkOut, 'Check Out (HH:MM:SS)', Icons.logout),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (empId == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please select an employee.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                try {
                  await SupabaseService.addAttendance({
                    'employee_id': empId,
                    'date': date.text,
                    'check_in_time': checkIn.text.isEmpty ? null : checkIn.text,
                    'check_out_time': checkOut.text.isEmpty
                        ? null
                        : checkOut.text,
                  });
                  Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Failed to log attendance: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String l, IconData i) => TextField(
    controller: c,
    decoration: InputDecoration(
      labelText: l,
      prefixIcon: Icon(i),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
