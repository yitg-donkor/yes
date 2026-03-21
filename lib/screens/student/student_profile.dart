import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class StudentProfilePage extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final int unreadCount;
  final VoidCallback onMarkRead;

  const StudentProfilePage({super.key, this.profile, required this.unreadCount, required this.onMarkRead});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _showNotifications = false;

  Future<void> _loadNotifications() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    final notifs = await SupabaseService.getNotifications(uid);
    if (mounted) setState(() => _notifications = notifs);
  }

  Future<void> _markAllRead() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    await SupabaseService.markAllNotificationsRead(uid);
    widget.onMarkRead();
    await _loadNotifications();
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
                onPressed: () async {
                  setState(() => _showNotifications = !_showNotifications);
                  if (_showNotifications) _loadNotifications();
                },
              ),
              if (widget.unreadCount > 0) Positioned(
                right: 8, top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text('${widget.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
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
            // Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(initial, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      if (studentId.isNotEmpty) Text('ID: $studentId', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Student', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notifications panel
            if (_showNotifications) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (widget.unreadCount > 0)
                          TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
                      ],
                    ),
                  ),
                  if (_notifications.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No notifications', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._notifications.take(10).map((n) => _buildNotifTile(n)),
                  const SizedBox(height: 8),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Menu items
            _buildMenuSection('Account', [
              _buildMenuItem(Icons.person_outline, 'Edit Profile', Colors.blue, () {}),
              _buildMenuItem(Icons.lock_outline, 'Change Password', Colors.orange, () {}),
              _buildMenuItem(Icons.notifications_outlined, 'Notification Settings', Colors.purple, () {}),
            ]),
            const SizedBox(height: 12),
            _buildMenuSection('Orders', [
              _buildMenuItem(Icons.history, 'Order History', Colors.green, () {}),
              _buildMenuItem(Icons.receipt_outlined, 'Receipts', Colors.teal, () {}),
            ]),
            const SizedBox(height: 12),
            _buildMenuSection('Other', [
              _buildMenuItem(Icons.help_outline, 'Help & Support', Colors.grey, () {}),
              _buildMenuItem(Icons.info_outline, 'About', Colors.grey, () {}),
              _buildMenuItem(Icons.logout, 'Sign Out', Colors.red, () async {
                await SupabaseService.signOut();
              }),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifTile(Map<String, dynamic> n) {
    final isRead = n['is_read'] as bool? ?? false;
    final type = n['type'] as String? ?? 'info';
    final color = switch (type) {
      'success' => Colors.green, 'error' => Colors.red, 'warning' => Colors.orange, _ => Colors.blue,
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
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.notifications, color: color, size: 16),
        ),
        title: Text(n['title'] ?? '', style: TextStyle(fontSize: 13, fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
        subtitle: Text(n['message'] ?? '', style: const TextStyle(fontSize: 12)),
        trailing: isRead ? null : Container(
          width: 8, height: 8,
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
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: TextStyle(fontSize: 14, color: label == 'Sign Out' ? Colors.red : null)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }
}
