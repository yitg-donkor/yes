import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class StudentProfilePage extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final int unreadCount;
  final VoidCallback onMarkRead;

  const StudentProfilePage({
    super.key,
    this.profile,
    required this.unreadCount,
    required this.onMarkRead,
  });

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _showNotifications = false;
  bool _loadingNotifs = false;

  @override
  void initState() {
    super.initState();
    // Auto-load notifications on open so badge count is always fresh
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    setState(() => _loadingNotifs = true);
    try {
      final notifs = await SupabaseService.getNotifications(uid);
      if (mounted) setState(() => _notifications = notifs);
    } finally {
      if (mounted) setState(() => _loadingNotifs = false);
    }
  }

  Future<void> _markAllRead() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    await SupabaseService.markAllNotificationsRead(uid);
    widget.onMarkRead();
    await _loadNotifications();
  }

  // ── Edit Profile Dialog ───────────────────────────────────────────────────
  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: widget.profile?['name'] ?? '');
    final studentIdCtrl = TextEditingController(
      text: widget.profile?['student_id'] ?? '',
    );
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_outline, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text('Edit Profile'),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: studentIdCtrl,
                  decoration: InputDecoration(
                    labelText: 'Student ID',
                    prefixIcon: const Icon(Icons.school_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
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
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Name cannot be empty.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setSt(() => saving = true);
                      try {
                        final uid = SupabaseService.currentUserId!;
                        await SupabaseService.updateProfile(uid, {
                          'name': nameCtrl.text.trim(),
                          'student_id': studentIdCtrl.text.trim().isEmpty
                              ? null
                              : studentIdCtrl.text.trim(),
                        });
                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Reload shell profile by triggering a rebuild
                          setState(() {});
                        }
                      } catch (e) {
                        setSt(() => saving = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Failed: $e'),
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
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Change Password Dialog ────────────────────────────────────────────────
  void _showChangePassword() {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool saving = false;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text('Change Password'),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newPassCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setSt(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirmCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setSt(() => obscureConfirm = !obscureConfirm),
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
                      if (newPassCtrl.text.length < 6) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password must be at least 6 characters.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (newPassCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setSt(() => saving = true);
                      try {
                        await SupabaseService.client.auth.updateUser(
                          UserAttributes(password: newPassCtrl.text),
                        );
                        Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password changed successfully.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setSt(() => saving = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Failed: $e'),
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
              label: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notification Settings Dialog ──────────────────────────────────────────
  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_outlined, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Notification Settings'),
          ],
        ),
        content: const Text(
          'You will receive notifications when your order status changes — '
          'e.g. when it is confirmed, ready for pickup, or completed.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // ── Order History shortcut ────────────────────────────────────────────────
  void _showOrderHistoryInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tap the Cart tab → My Orders to view your order history.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final name = p?['name'] ?? 'Student';
    final email = p?['email'] ?? '';
    final studentId = p?['student_id'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  setState(() => _showNotifications = !_showNotifications);
                  if (_showNotifications) _loadNotifications();
                },
              ),
              if (widget.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${widget.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Profile Card ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (studentId.isNotEmpty)
                          Text(
                            'ID: $studentId',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Student',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Notifications Panel ───────────────────────────────────────
            if (_showNotifications) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              if (widget.unreadCount > 0)
                                TextButton(
                                  onPressed: _markAllRead,
                                  child: const Text('Mark all read'),
                                ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 18),
                                onPressed: _loadNotifications,
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_loadingNotifs)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: Color(0xFF2E7D32),
                        ),
                      )
                    else if (_notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ..._notifications.take(10).map((n) => _buildNotifTile(n)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Account Section ───────────────────────────────────────────
            _buildMenuSection('Account', [
              _buildMenuItem(
                Icons.person_outline,
                'Edit Profile',
                Colors.blue,
                _showEditProfile,
              ),
              _buildMenuItem(
                Icons.lock_outline,
                'Change Password',
                Colors.orange,
                _showChangePassword,
              ),
              _buildMenuItem(
                Icons.notifications_outlined,
                'Notification Settings',
                Colors.purple,
                _showNotificationSettings,
              ),
            ]),

            const SizedBox(height: 12),

            // ── Orders Section ────────────────────────────────────────────
            _buildMenuSection('Orders', [
              _buildMenuItem(
                Icons.history,
                'Order History',
                Colors.green,
                _showOrderHistoryInfo,
              ),
            ]),

            const SizedBox(height: 12),

            // ── Other Section ─────────────────────────────────────────────
            _buildMenuSection('Other', [
              _buildMenuItem(
                Icons.help_outline,
                'Help & Support',
                Colors.grey,
                () => _showHelpDialog(),
              ),
              _buildMenuItem(
                Icons.info_outline,
                'About',
                Colors.grey,
                () => _showAboutDialog(),
              ),
              _buildMenuItem(Icons.logout, 'Sign Out', Colors.red, () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await SupabaseService.signOut();
                }
              }),
            ]),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Help & Support'),
          ],
        ),
        content: const Text(
          'For assistance, please contact the pharmacy directly or '
          'reach out to your campus health services.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_pharmacy, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('About Pharma One'),
          ],
        ),
        content: const Text(
          'Pharma One is your campus pharmacy management app.\n\n'
          'Browse medicines, place orders, and track deliveries — all in one place.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifTile(Map<String, dynamic> n) {
    final isRead = n['is_read'] as bool? ?? false;
    final type = n['type'] as String? ?? 'info';
    final color = switch (type) {
      'success' => Colors.green,
      'error' => Colors.red,
      'warning' => Colors.orange,
      _ => Colors.blue,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isRead ? Colors.transparent : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.notifications, color: color, size: 16),
        ),
        title: Text(
          n['title'] ?? '',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          n['message'] ?? '',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
        onTap: () async {
          await SupabaseService.markNotificationRead(n['id']);
          _loadNotifications();
        },
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: label == 'Sign Out' ? Colors.red : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }
}
