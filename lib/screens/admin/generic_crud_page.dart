import 'package:flutter/material.dart';

class GenericCrudPage extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Future<List<Map<String, dynamic>>> Function() fetchItems;
  final List<String> displayColumns;
  final List<String> columnLabels;
  final void Function(BuildContext, VoidCallback) onAdd;
  final void Function(BuildContext, Map<String, dynamic>, VoidCallback) onEdit;
  final Future<void> Function(String) onDelete;

  const GenericCrudPage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.fetchItems,
    required this.displayColumns,
    required this.columnLabels,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<GenericCrudPage> createState() => _GenericCrudPageState();
}

class _GenericCrudPageState extends State<GenericCrudPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _search = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Converts plural title to correct singular (Pharmacies→Pharmacy, etc.)
  String get _singular {
    final t = widget.title;
    if (t.endsWith('ies')) return '${t.substring(0, t.length - 3)}y';
    if (t.endsWith('s')) return t.substring(0, t.length - 1);
    return t;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.fetchItems();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _items;
    return _items
        .where(
          (item) => item.values.any(
            (v) => v.toString().toLowerCase().contains(_search.toLowerCase()),
          ),
        )
        .toList();
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('This action cannot be undone.'),
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
      try {
        await widget.onDelete(id);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
                    hintText: 'Search ${widget.title.toLowerCase()}...',
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
              ElevatedButton.icon(
                onPressed: () => widget.onAdd(context, _load),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add $_singular'),
              ),
            ],
          ),
        ),

        // Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: widget.color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                _loading ? 'Loading...' : '${_filtered.length} ${widget.title}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
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
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),

        // Data
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                )
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 56,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load ${widget.title.toLowerCase()}',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        _search.isEmpty
                            ? 'No ${widget.title.toLowerCase()} found'
                            : 'No results for "$_search"',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      if (_search.isEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => widget.onAdd(context, _load),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text('Add your first $_singular'),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final cols = constraints.maxWidth > 1000
                          ? 3
                          : constraints.maxWidth > 650
                          ? 2
                          : 1;
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) => _buildCard(_filtered[i]),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 16),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') widget.onEdit(context, item, _load);
                    if (v == 'delete') _delete(item['id']);
                  },
                  itemBuilder: (_) => [
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
                          Text('Delete', style: TextStyle(color: Colors.red)),
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
            const SizedBox(height: 8),
            if (widget.displayColumns.isNotEmpty)
              Text(
                item[widget.displayColumns[0]]?.toString() ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (widget.displayColumns.length > 1) ...[
              const SizedBox(height: 3),
              Text(
                item[widget.displayColumns[1]]?.toString() ?? '-',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (widget.displayColumns.length > 2) ...[
              const SizedBox(height: 2),
              Text(
                item[widget.displayColumns[2]]?.toString() ?? '-',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
