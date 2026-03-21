// ─── admin_pharmacies.dart ────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'generic_crud_page.dart';

class AdminPharmaciesPage extends StatelessWidget {
  const AdminPharmaciesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return GenericCrudPage(
      title: 'Pharmacies',
      icon: Icons.local_pharmacy_rounded,
      color: const Color(0xFF2E7D32),
      fetchItems: SupabaseService.getPharmacies,
      displayColumns: const ['name', 'address', 'contact'],
      columnLabels: const ['Name', 'Address', 'Contact'],
      onAdd: (ctx, refresh) => _showDialog(ctx, null, refresh),
      onEdit: (ctx, item, refresh) => _showDialog(ctx, item, refresh),
      onDelete: (id) => SupabaseService.deletePharmacy(id),
    );
  }

  void _showDialog(
    BuildContext context,
    Map<String, dynamic>? item,
    VoidCallback refresh,
  ) {
    final name = TextEditingController(text: item?['name'] ?? '');
    final address = TextEditingController(text: item?['address'] ?? '');
    final contact = TextEditingController(text: item?['contact'] ?? '');
    showDialog(
      context: context,
      builder:
          (_) => _SimpleDialog(
            title: item == null ? 'Add Pharmacy' : 'Edit Pharmacy',
            icon: Icons.local_pharmacy,
            fields: [
              _Field(name, 'Pharmacy Name', Icons.local_pharmacy),
              _Field(address, 'Address', Icons.location_on),
              _Field(contact, 'Contact', Icons.phone),
            ],
            onSave: () async {
              final data = {
                'name': name.text,
                'address': address.text,
                'contact': contact.text,
              };
              if (item == null) {
                await SupabaseService.addPharmacy(data);
              } else {
                await SupabaseService.updatePharmacy(item['id'], data);
              }
              refresh();
            },
          ),
    );
  }
}

class _SimpleDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_Field> fields;
  final VoidCallback onSave;

  const _SimpleDialog({
    required this.title,
    required this.icon,
    required this.fields,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [Icon(icon), const SizedBox(width: 8), Text(title)]),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: fields),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onSave();
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _Field(this.controller, this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
