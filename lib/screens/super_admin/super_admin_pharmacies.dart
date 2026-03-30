import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class SuperAdminPharmaciesPage extends StatefulWidget {
  const SuperAdminPharmaciesPage({super.key});

  @override
  State<SuperAdminPharmaciesPage> createState() =>
      _SuperAdminPharmaciesPageState();
}

class _SuperAdminPharmaciesPageState extends State<SuperAdminPharmaciesPage> {
  List<Map<String, dynamic>> _pharmacies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await SupabaseService.getPharmacies();
    if (mounted)
      setState(() {
        _pharmacies = list;
        _loading = false;
      });
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
              Text(
                '${_pharmacies.length} pharmacies on network',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showOnboardDialog,
                icon: const Icon(Icons.add_business, size: 18),
                label: const Text('Onboard Pharmacy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                )
              : _pharmacies.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pharmacies.length,
                    itemBuilder: (ctx, i) => _buildPharmacyCard(_pharmacies[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_pharmacy_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No pharmacies yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showOnboardDialog,
            icon: const Icon(Icons.add_business),
            label: const Text('Onboard First Pharmacy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(Map<String, dynamic> p) {
    final isActive = p['is_active'] as bool? ?? true;
    final id = p['id'] as String;

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
                    color: isActive
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.local_pharmacy,
                    color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        p['address'] ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(isActive),
              ],
            ),
            const SizedBox(height: 14),

            // Contact info
            Row(
              children: [
                if (p['contact'] != null && p['contact'] != '') ...[
                  Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    p['contact'],
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                ],
                if (p['email'] != null && p['email'] != '') ...[
                  Icon(
                    Icons.email_outlined,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    p['email'],
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ],
            ),
            const Divider(height: 20),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _actionBtn(
                  'Edit Details',
                  Icons.edit_outlined,
                  Colors.blue,
                  () => _showEditDialog(p),
                ),
                _actionBtn(
                  'Create Admin',
                  Icons.person_add_outlined,
                  Colors.green,
                  () => _showCreateAdminDialog(id, p['name'] ?? ''),
                ),
                _actionBtn(
                  isActive ? 'Suspend' : 'Reactivate',
                  isActive
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  isActive ? Colors.red : Colors.green,
                  () => _toggleStatus(id, isActive),
                ),
                _actionBtn(
                  'Delete',
                  Icons.delete_forever_outlined,
                  Colors.grey.shade600,
                  () => _showDeleteDialog(p),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Suspended',
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // ─── Onboard Dialog ──────────────────────────────────────────────────────

  void _showOnboardDialog() {
    final name = TextEditingController();
    final address = TextEditingController();
    final contact = TextEditingController();
    final email = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_business, color: Color(0xFF1565C0)),
              SizedBox(width: 10),
              Text('Onboard New Pharmacy'),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tf(name, 'Pharmacy Name *', Icons.local_pharmacy),
                const SizedBox(height: 12),
                _tf(address, 'Address', Icons.location_on),
                const SizedBox(height: 12),
                _tf(contact, 'Contact Number', Icons.phone),
                const SizedBox(height: 12),
                _tf(email, 'Email', Icons.email),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      if (name.text.trim().isEmpty) return;
                      setSt(() => saving = true);
                      try {
                        await SupabaseService.addPharmacy({
                          'name': name.text.trim(),
                          'address': address.text.trim(),
                          'contact': contact.text.trim(),
                          'email': email.text.trim(),
                          'is_active': true,
                        });
                        Navigator.pop(ctx);
                        _load();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${name.text} onboarded successfully!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        setSt(() => saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              icon: saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 16),
              label: const Text('Onboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Edit Dialog ─────────────────────────────────────────────────────────

  void _showEditDialog(Map<String, dynamic> p) {
    final name = TextEditingController(text: p['name'] ?? '');
    final address = TextEditingController(text: p['address'] ?? '');
    final contact = TextEditingController(text: p['contact'] ?? '');
    final email = TextEditingController(text: p['email'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Pharmacy'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tf(name, 'Pharmacy Name', Icons.local_pharmacy),
              const SizedBox(height: 12),
              _tf(address, 'Address', Icons.location_on),
              const SizedBox(height: 12),
              _tf(contact, 'Contact Number', Icons.phone),
              const SizedBox(height: 12),
              _tf(email, 'Email', Icons.email),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.updatePharmacy(p['id'], {
                'name': name.text.trim(),
                'address': address.text.trim(),
                'contact': contact.text.trim(),
                'email': email.text.trim(),
              });
              Navigator.pop(context);
              _load();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ─── Create Admin Dialog ─────────────────────────────────────────────────

  void _showCreateAdminDialog(String pharmacyId, String pharmacyName) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool saving = false;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.person_add, color: Color(0xFF2E7D32)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Create Pharmacy Admin'),
                    Text(
                      pharmacyName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'This admin will only have access to $pharmacyName\'s data.',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                _tf(nameCtrl, 'Full Name', Icons.person),
                const SizedBox(height: 12),
                _tf(emailCtrl, 'Email Address', Icons.email),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Temporary Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setSt(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      if (nameCtrl.text.isEmpty ||
                          emailCtrl.text.isEmpty ||
                          passCtrl.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fill all fields. Password min 6 chars.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setSt(() => saving = true);
                      try {
                        await SupabaseService.createStaffAccount(
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text,
                          name: nameCtrl.text.trim(),
                          role: 'admin',
                          pharmacyId: pharmacyId,
                        );
                        ;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Admin account created for ${nameCtrl.text}',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        setSt(() => saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              icon: saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 16),
              label: const Text('Create Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Suspend / Reactivate ────────────────────────────────────────────────

  Future<void> _toggleStatus(String id, bool currentlyActive) async {
    final action = currentlyActive ? 'suspend' : 'reactivate';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          currentlyActive ? 'Suspend Pharmacy' : 'Reactivate Pharmacy',
        ),
        content: Text(
          currentlyActive
              ? 'Suspending will prevent students from placing new orders. Existing orders remain. Continue?'
              : 'This will allow the pharmacy to accept orders again. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentlyActive ? Colors.red : Colors.green,
            ),
            child: Text(currentlyActive ? 'Suspend' : 'Reactivate'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await SupabaseService.setPharmacyStatus(id, !currentlyActive);
    _load();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pharmacy ${currentlyActive ? 'suspended' : 'reactivated'}.',
        ),
        backgroundColor: currentlyActive ? Colors.red : Colors.green,
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> p) {
    final nameCtrl = TextEditingController();
    final pharmacyName = p['name'] as String? ?? 'this pharmacy';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete Pharmacy'),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'This cannot be undone.',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Deleting "$pharmacyName" will permanently remove all its '
                        'products, branches, employees, suppliers, orders, and '
                        'staff accounts from the network.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Type the pharmacy name to confirm:',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: pharmacyName,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (_) => setSt(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: nameCtrl.text.trim() == pharmacyName
                  ? () async {
                      Navigator.pop(ctx);
                      try {
                        await SupabaseService.deletePharmacy(p['id']);
                        _load();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '"$pharmacyName" permanently deleted.',
                            ),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Delete failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.delete_forever, size: 16),
              label: const Text('Delete Permanently'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String label, IconData icon) => TextField(
    controller: c,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
