import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Simple flag — always true since we initialize in main() before runApp
  static bool isConfigured = true;
  static void markConfigured() => isConfigured = true;

  // ─── Auth ──────────────────────────────────────────────────────────────────

  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => currentUser?.id;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  static Future<AuthResponse> signIn(String email, String password) =>
      client.auth.signInWithPassword(email: email, password: password);

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'student',
    String? studentId,
  }) => client.auth.signUp(
    email: email,
    password: password,
    data: {'name': name, 'role': role, 'student_id': studentId},
  );

  static Future<void> signOut() => client.auth.signOut();

  static Future<void> resetPassword(String email) =>
      client.auth.resetPasswordForEmail(email);

  // ─── Profile ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    final res = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return res;
  }

  static Future<void> updateProfile(String userId, Map<String, dynamic> data) =>
      client.from('profiles').update(data).eq('id', userId);

  static Future<List<Map<String, dynamic>>> getAllProfiles() =>
      client.from('profiles').select().order('created_at', ascending: false);

  // ─── Dashboard ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await client.rpc('get_dashboard_stats');
    return Map<String, dynamic>.from(res);
  }

  // ─── Products ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getProducts({
    String? category,
    String? search,
    bool inStockOnly = false,
  }) async {
    var query = client.from('products').select('*, suppliers(name)');
    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }
    if (inStockOnly) {
      query = query.gt('quantity', 0);
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }
    return query.order('name');
  }

  static Future<void> addProduct(Map<String, dynamic> data) =>
      client.from('products').insert(data);

  static Future<void> updateProduct(String id, Map<String, dynamic> data) =>
      client.from('products').update(data).eq('id', id);

  static Future<void> deleteProduct(String id) =>
      client.from('products').delete().eq('id', id);

  static Future<List<String>> getProductCategories() async {
    final res = await client.from('products').select('category');
    final categories =
        (res as List)
            .map((e) => e['category'] as String? ?? 'General')
            .toSet()
            .toList()
          ..sort();
    return ['All', ...categories];
  }

  // ─── Orders ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createOrder({
    required String studentId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String paymentMethod,
    required String deliveryMethod,
    String? deliveryAddress,
    String? notes,
  }) async {
    // Create the order
    final order = await client
        .from('orders')
        .insert({
          'student_id': studentId,
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
          'delivery_method': deliveryMethod,
          'delivery_address': deliveryAddress,
          'notes': notes,
          'status': 'pending',
        })
        .select()
        .single();

    // Insert order items
    final orderItems = items
        .map(
          (item) => {
            'order_id': order['id'],
            'product_id': item['product_id'],
            'product_name': item['product_name'],
            'quantity': item['quantity'],
            'unit_price': item['unit_price'],
          },
        )
        .toList();
    await client.from('order_items').insert(orderItems);

    return order;
  }

  static Future<List<Map<String, dynamic>>> getStudentOrders(
    String studentId,
  ) => client
      .from('orders')
      .select('*, order_items(*, products(name, image_url))')
      .eq('student_id', studentId)
      .order('created_at', ascending: false);

  static Future<List<Map<String, dynamic>>> getAllOrders({
    String? status,
  }) async {
    var query = client
        .from('orders')
        .select(
          '*, profiles(name, email, student_id), order_items(*, products(name))',
        );
    if (status != null && status != 'All') {
      query = query.eq('status', status);
    }
    return query.order('created_at', ascending: false);
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    final res = await client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId)
        .select();
    if ((res as List).isEmpty) {
      throw Exception(
        'Update blocked — RLS policy denied the request. Run fix_orders_rls.sql in Supabase.',
      );
    }
  }

  static Future<Map<String, dynamic>> getOrderById(String orderId) => client
      .from('orders')
      .select(
        '*, profiles(name, email, contact), order_items(*, products(name, unit_price))',
      )
      .eq('id', orderId)
      .single();

  // ─── Pharmacies ────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPharmacies() =>
      client.from('pharmacies').select().order('name');

  static Future<void> addPharmacy(Map<String, dynamic> data) =>
      client.from('pharmacies').insert(data);

  static Future<void> updatePharmacy(String id, Map<String, dynamic> data) =>
      client.from('pharmacies').update(data).eq('id', id);

  static Future<void> deletePharmacy(String id) =>
      client.from('pharmacies').delete().eq('id', id);

  // ─── Branches ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getBranches() =>
      client.from('branches').select('*, pharmacies(name)').order('name');

  static Future<void> addBranch(Map<String, dynamic> data) =>
      client.from('branches').insert(data);

  static Future<void> updateBranch(String id, Map<String, dynamic> data) =>
      client.from('branches').update(data).eq('id', id);

  static Future<void> deleteBranch(String id) =>
      client.from('branches').delete().eq('id', id);

  // ─── Employees ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getEmployees() =>
      client.from('employees').select('*, branches(name)').order('name');

  static Future<void> addEmployee(Map<String, dynamic> data) =>
      client.from('employees').insert(data);

  static Future<void> updateEmployee(String id, Map<String, dynamic> data) =>
      client.from('employees').update(data).eq('id', id);

  static Future<void> deleteEmployee(String id) =>
      client.from('employees').delete().eq('id', id);

  // ─── Suppliers ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getSuppliers() =>
      client.from('suppliers').select().order('name');

  static Future<void> addSupplier(Map<String, dynamic> data) =>
      client.from('suppliers').insert(data);

  static Future<void> updateSupplier(String id, Map<String, dynamic> data) =>
      client.from('suppliers').update(data).eq('id', id);

  static Future<void> deleteSupplier(String id) =>
      client.from('suppliers').delete().eq('id', id);

  // ─── Sales ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getSales() => client
      .from('sales')
      .select('*, employees(name), profiles(name)')
      .order('created_at', ascending: false);

  static Future<void> addSale(Map<String, dynamic> data) =>
      client.from('sales').insert(data);

  // ─── Receipts ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getReceipts() =>
      client.from('receipts').select().order('created_at', ascending: false);

  static Future<void> addReceipt(Map<String, dynamic> data) =>
      client.from('receipts').insert(data);

  // ─── Attendance ────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAttendance() => client
      .from('attendance')
      .select('*, employees(name)')
      .order('date', ascending: false);

  static Future<void> addAttendance(Map<String, dynamic> data) =>
      client.from('attendance').insert(data);

  static Future<void> updateAttendance(String id, Map<String, dynamic> data) =>
      client.from('attendance').update(data).eq('id', id);

  // ─── Notifications ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getNotifications(String userId) =>
      client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

  static Future<void> markNotificationRead(String id) =>
      client.from('notifications').update({'is_read': true}).eq('id', id);

  static Future<void> markAllNotificationsRead(String userId) => client
      .from('notifications')
      .update({'is_read': true})
      .eq('user_id', userId);

  static Future<int> getUnreadCount(String userId) async {
    final res = await client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false);
    return (res as List).length;
  }

  // ─── Realtime ──────────────────────────────────────────────────────────────

  static RealtimeChannel subscribeToOrders(Function(dynamic) onUpdate) => client
      .channel('orders-channel')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        callback: (payload) => onUpdate(payload),
      )
      .subscribe();

  static RealtimeChannel subscribeToNotifications(
    String userId,
    Function(dynamic) onInsert,
  ) => client
      .channel('notifications-$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) => onInsert(payload),
      )
      .subscribe();
}
