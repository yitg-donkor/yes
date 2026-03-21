// admin_branches.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'generic_crud_page.dart';

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
    String? selectedPharmacy = item?['pharmacy_id'];

    showDialog(
      context: ctx,
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx2, setSt) => AlertDialog(
                  title: Text(item == null ? 'Add Branch' : 'Edit Branch'),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selectedPharmacy,
                          decoration: InputDecoration(
                            labelText: 'Pharmacy',
                            prefixIcon: const Icon(Icons.local_pharmacy),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items:
                              pharmacies
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
                        final data = {
                          'pharmacy_id': selectedPharmacy,
                          'name': name.text,
                          'address': address.text,
                          'contact': contact.text,
                        };
                        if (item == null) {
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

  Widget _tf(TextEditingController c, String l, IconData i) => TextField(
    controller: c,
    decoration: InputDecoration(
      labelText: l,
      prefixIcon: Icon(i),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx2, setSt) => AlertDialog(
                  title: Text(item == null ? 'Add Employee' : 'Edit Employee'),
                  content: SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedBranch,
                            decoration: InputDecoration(
                              labelText: 'Branch',
                              prefixIcon: const Icon(Icons.location_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items:
                                branches
                                    .map(
                                      (b) => DropdownMenuItem(
                                        value: b['id'] as String,
                                        child: Text(b['name'] as String),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setSt(() => selectedBranch = v),
                          ),
                          const SizedBox(height: 12),
                          _tf(name, 'Employee Name', Icons.person),
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
                        final data = {
                          'branch_id': selectedBranch,
                          'name': name.text,
                          'position': position.text,
                          'email': email.text,
                          'contact': contact.text,
                        };
                        if (item == null) {
                          await SupabaseService.addEmployee(data);
                        } else {
                          await SupabaseService.updateEmployee(
                            item['id'],
                            data,
                          );
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
      builder:
          (_) => AlertDialog(
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
                    await SupabaseService.addSupplier(data);
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

class AdminCustomersPage extends StatelessWidget {
  const AdminCustomersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return GenericCrudPage(
      title: 'Customers',
      icon: Icons.people_rounded,
      color: const Color(0xFFC2185B),
      fetchItems:
          () => SupabaseService.getAllProfiles().then(
            (p) => p.where((x) => x['role'] == 'student').toList(),
          ),
      displayColumns: const ['name', 'email', 'student_id'],
      columnLabels: const ['Name', 'Email', 'Student ID'],
      onAdd: (ctx, refresh) {},
      onEdit: (ctx, item, refresh) {},
      onDelete: (_) async {},
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sales = await SupabaseService.getSales();
    if (mounted) {
      setState(() {
        _sales = sales;
        _loading = false;
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
              ElevatedButton.icon(
                onPressed: () => _showAddSale(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Sale'),
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
                  : ListView.builder(
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
                            '${sale['employees']?['name'] ?? 'Staff'} · ${sale['payment_method'] ?? 'cash'}',
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
      ],
    );
  }

  void _showAddSale() async {
    final products = await SupabaseService.getProducts();
    final employees = await SupabaseService.getEmployees();
    final customers = await SupabaseService.getAllProfiles();
    String? productId, employeeId, customerId;
    final qty = TextEditingController(text: '1');
    final payment = TextEditingController(text: 'cash');

    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setSt) => AlertDialog(
                  title: const Text('Add Sale'),
                  content: SizedBox(
                    width: 450,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: employeeId,
                            decoration: InputDecoration(
                              labelText: 'Employee',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items:
                                employees
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e['id'] as String,
                                        child: Text(e['name'] as String),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setSt(() => employeeId = v),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: customerId,
                            decoration: InputDecoration(
                              labelText: 'Customer',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items:
                                customers
                                    .where((c) => c['role'] == 'student')
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c['id'] as String,
                                        child: Text(c['name'] as String),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setSt(() => customerId = v),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: productId,
                            decoration: InputDecoration(
                              labelText: 'Product',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items:
                                products
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p['id'] as String,
                                        child: Text(p['name'] as String),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setSt(() => productId = v),
                          ),
                          const SizedBox(height: 12),
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
                          DropdownButtonFormField<String>(
                            initialValue:
                                payment.text.isEmpty ? 'cash' : payment.text,
                            decoration: InputDecoration(
                              labelText: 'Payment Method',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items:
                                ['cash', 'mobile_money', 'card']
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => payment.text = v ?? 'cash',
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
                        final product = products.firstWhere(
                          (p) => p['id'] == productId,
                          orElse: () => {},
                        );
                        final price =
                            double.tryParse(
                              product['unit_price']?.toString() ?? '0',
                            ) ??
                            0;
                        final quantity = int.tryParse(qty.text) ?? 1;
                        await SupabaseService.addSale({
                          'employee_id': employeeId,
                          'customer_id': customerId,
                          'product_id': productId,
                          'product_name': product['name'],
                          'quantity': quantity,
                          'total_cost': price * quantity,
                          'status': 'completed',
                          'payment_method': payment.text,
                          'receipt_num':
                              'REC-${DateTime.now().millisecondsSinceEpoch}',
                        });
                        Navigator.pop(ctx);
                        _load();
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final receipts = await SupabaseService.getReceipts();
    if (mounted) {
      setState(() {
        _receipts = receipts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        )
        : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _receipts.length,
          itemBuilder: (ctx, i) {
            final r = _receipts[i];
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
                subtitle: Text(r['prod_name'] ?? 'N/A'),
                trailing: Text(
                  'GH₵ ${(double.tryParse(r['total_amount']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
  }
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final records = await SupabaseService.getAttendance();
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
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
              ElevatedButton.icon(
                onPressed: _showAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Attendance'),
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
                  : ListView.builder(
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
      ],
    );
  }

  void _showAdd() async {
    final employees = await SupabaseService.getEmployees();
    String? empId;
    final checkIn = TextEditingController(text: '08:00:00');
    final checkOut = TextEditingController();
    final date = TextEditingController(
      text: DateTime.now().toString().substring(0, 10),
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setSt) => AlertDialog(
                  title: const Text('Log Attendance'),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: empId,
                          decoration: InputDecoration(
                            labelText: 'Employee',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items:
                              employees
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
                        await SupabaseService.addAttendance({
                          'employee_id': empId,
                          'date': date.text,
                          'check_in_time':
                              checkIn.text.isEmpty ? null : checkIn.text,
                          'check_out_time':
                              checkOut.text.isEmpty ? null : checkOut.text,
                        });
                        Navigator.pop(ctx);
                        _load();
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
