import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static const _supabaseUrl = 'https://vdhgroudezwfgjjrawto.supabase.co';
  static const _serviceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkaGdyb3VkZXp3ZmdqanJhd3RvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MzkxNDQ5NiwiZXhwIjoyMDg5NDkwNDk2fQ.HqEOanf9NFt_agsKXYQi7n2KXmwVpxNs-ZHr6VtSY_s';

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
    String? pharmacyId,
  }) => client.auth.signUp(
    email: email,
    password: password,
    data: {
      'name': name,
      'role': role,
      if (studentId != null) 'student_id': studentId,
      if (pharmacyId != null) 'pharmacy_id': pharmacyId,
    },
  );

  static Future<void> signOut() => client.auth.signOut();

  /// Creates a staff/admin account WITHOUT disturbing the current session.
  static Future<void> createStaffAccount({
    required String email,
    required String password,
    required String name,
    required String role,
    String? pharmacyId,
  }) async {
    final createRes = await http.post(
      Uri.parse('$_supabaseUrl/auth/v1/admin/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_serviceRoleKey',
        'apikey': _serviceRoleKey,
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'email_confirm': true,
        'user_metadata': {
          'name': name,
          'role': role,
          if (pharmacyId != null) 'pharmacy_id': pharmacyId,
        },
      }),
    );

    if (createRes.statusCode != 200 && createRes.statusCode != 201) {
      final body = jsonDecode(createRes.body);
      final msg =
          body['msg'] ??
          body['message'] ??
          body['error_description'] ??
          'Failed to create account.';
      throw Exception(msg);
    }

    final newUser = jsonDecode(createRes.body);
    final newUserId = newUser['id'] as String?;
    if (newUserId == null) throw Exception('User created but ID missing.');

    await client.from('profiles').upsert({
      'id': newUserId,
      'email': email,
      'name': name,
      'role': role,
      if (pharmacyId != null) 'pharmacy_id': pharmacyId,
    }, onConflict: 'id');
  }

  // ─── Storage — Product Images ──────────────────────────────────────────────

  /// Upload image bytes to Supabase Storage and return the public URL.
  static Future<String> uploadProductImage({
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final path = 'products/$fileName';
    await client.storage
        .from('product-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return client.storage.from('product-images').getPublicUrl(path);
  }

  /// Delete a product image from storage by its public URL.
  static Future<void> deleteProductImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexWhere((s) => s == 'product-images');
      if (bucketIndex == -1) return;
      final path = segments.sublist(bucketIndex + 1).join('/');
      await client.storage.from('product-images').remove([path]);
    } catch (_) {
      // Non-critical
    }
  }

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

  static Future<List<Map<String, dynamic>>> getPharmacyStaff(
    String pharmacyId,
  ) => client
      .from('profiles')
      .select()
      .eq('pharmacy_id', pharmacyId)
      .inFilter('role', ['admin', 'pharmacist'])
      .order('name');

  // ─── Dashboard ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await client.rpc('get_dashboard_stats');
    return Map<String, dynamic>.from(res);
  }

  static Future<Map<String, dynamic>> getSuperAdminStats() async {
    final res = await client.rpc('get_super_admin_stats');
    return Map<String, dynamic>.from(res);
  }

  // ─── Pharmacies ────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPharmacies({
    bool activeOnly = false,
  }) async {
    var q = client.from('pharmacies').select();
    if (activeOnly) q = q.eq('is_active', true);
    return q.order('name');
  }

  static Future<Map<String, dynamic>> addPharmacy(
    Map<String, dynamic> data,
  ) async {
    final res = await client.from('pharmacies').insert(data).select().single();
    return res;
  }

  static Future<void> updatePharmacy(String id, Map<String, dynamic> data) =>
      client.from('pharmacies').update(data).eq('id', id);

  static Future<void> deletePharmacy(String id) =>
      client.from('pharmacies').delete().eq('id', id);

  static Future<void> setPharmacyStatus(String id, bool isActive) =>
      client.from('pharmacies').update({'is_active': isActive}).eq('id', id);

  // ─── Pharmacy Reviews ──────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPharmacyReviews(
    String pharmacyId,
  ) => client
      .from('pharmacy_reviews')
      .select('*, profiles(name)')
      .eq('pharmacy_id', pharmacyId)
      .order('created_at', ascending: false);

  static Future<double> getPharmacyRating(String pharmacyId) async {
    final res = await client
        .from('pharmacy_reviews')
        .select('rating')
        .eq('pharmacy_id', pharmacyId);
    if ((res as List).isEmpty) return 0.0;
    final sum = res.fold<int>(0, (s, r) => s + (r['rating'] as int));
    return sum / res.length;
  }

  static Future<Map<String, dynamic>?> getMyReview(String pharmacyId) async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      final res = await client
          .from('pharmacy_reviews')
          .select()
          .eq('pharmacy_id', pharmacyId)
          .eq('student_id', uid)
          .single();
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<void> submitReview({
    required String pharmacyId,
    required int rating,
    String? comment,
  }) async {
    final uid = currentUserId!;
    await client.from('pharmacy_reviews').upsert({
      'pharmacy_id': pharmacyId,
      'student_id': uid,
      'rating': rating,
      'comment': comment,
    }, onConflict: 'pharmacy_id,student_id');
  }

  // ─── Products ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getProducts({
    String? pharmacyId,
    String? category,
    String? search,
    bool inStockOnly = false,
  }) async {
    var query = client.from('products').select('*, pharmacies(id, name)');
    if (pharmacyId != null) query = query.eq('pharmacy_id', pharmacyId);
    if (category != null && category != 'All')
      query = query.eq('category', category);
    if (inStockOnly) query = query.gt('quantity', 0);
    if (search != null && search.isNotEmpty)
      query = query.ilike('name', '%$search%');
    return query.order('name');
  }

  static Future<void> addProduct(Map<String, dynamic> data) =>
      client.from('products').insert(data);

  static Future<void> updateProduct(String id, Map<String, dynamic> data) =>
      client.from('products').update(data).eq('id', id);

  static Future<void> deleteProduct(String id) =>
      client.from('products').delete().eq('id', id);

  static Future<List<String>> getProductCategories({String? pharmacyId}) async {
    var q = client.from('products').select('category');
    if (pharmacyId != null) q = q.eq('pharmacy_id', pharmacyId);
    final res = await q;
    final cats =
        (res as List)
            .map((e) => e['category'] as String? ?? 'General')
            .toSet()
            .toList()
          ..sort();
    return ['All', ...cats];
  }

  // ─── Orders ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createOrder({
    required String studentId,
    required String pharmacyId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String paymentMethod,
    required String deliveryMethod,
    String? deliveryAddress,
    String? notes,
  }) async {
    final order = await client
        .from('orders')
        .insert({
          'student_id': studentId,
          'pharmacy_id': pharmacyId,
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
          'delivery_method': deliveryMethod,
          'delivery_address': deliveryAddress,
          'notes': notes,
          'status': 'pending',
        })
        .select()
        .single();

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
      .select('*, pharmacies(name), order_items(*, products(name))')
      .eq('student_id', studentId)
      .order('created_at', ascending: false);

  static Future<List<Map<String, dynamic>>> getAllOrders({
    String? status,
  }) async {
    var query = client
        .from('orders')
        .select(
          '*, pharmacies(name), profiles(name, email, student_id), order_items(*)',
        );
    if (status != null && status != 'All') query = query.eq('status', status);
    return query.order('created_at', ascending: false);
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    final res = await client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId)
        .select();
    if ((res as List).isEmpty) {
      throw Exception('Update blocked — RLS policy denied the request.');
    }
  }

  // ─── Branches ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getBranches({
    String? pharmacyId,
  }) async {
    var q = client.from('branches').select('*, pharmacies(name)');
    if (pharmacyId != null) q = q.eq('pharmacy_id', pharmacyId);
    return q.order('name');
  }

  static Future<void> addBranch(Map<String, dynamic> data) =>
      client.from('branches').insert(data);

  static Future<void> updateBranch(String id, Map<String, dynamic> data) =>
      client.from('branches').update(data).eq('id', id);

  static Future<void> deleteBranch(String id) =>
      client.from('branches').delete().eq('id', id);

  // ─── Employees ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getEmployees({
    String? pharmacyId,
  }) async {
    var q = client.from('employees').select('*, branches(name)');
    if (pharmacyId != null) q = q.eq('pharmacy_id', pharmacyId);
    return q.order('name');
  }

  static Future<void> addEmployee(Map<String, dynamic> data) =>
      client.from('employees').insert(data);

  static Future<void> updateEmployee(String id, Map<String, dynamic> data) =>
      client.from('employees').update(data).eq('id', id);

  static Future<void> deleteEmployee(String id) =>
      client.from('employees').delete().eq('id', id);

  // ─── Suppliers ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getSuppliers({
    String? pharmacyId,
  }) async {
    var q = client.from('suppliers').select();
    if (pharmacyId != null) q = q.eq('pharmacy_id', pharmacyId);
    return q.order('name');
  }

  static Future<void> addSupplier(Map<String, dynamic> data) =>
      client.from('suppliers').insert(data);

  static Future<void> updateSupplier(String id, Map<String, dynamic> data) =>
      client.from('suppliers').update(data).eq('id', id);

  static Future<void> deleteSupplier(String id) =>
      client.from('suppliers').delete().eq('id', id);

  // ─── Sales ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getSales({
    String? pharmacyId,
  }) async {
    var q = client.from('sales').select('*, employees(name), profiles(name)');
    if (pharmacyId != null) q = q.eq('pharmacy_id', pharmacyId);
    return q.order('created_at', ascending: false);
  }

  static Future<void> addSale(Map<String, dynamic> data) =>
      client.from('sales').insert(data);

  // ─── Receipts ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getReceipts({
    String? pharmacyId,
  }) async {
    var q = client.from('receipts').select();
    if (pharmacyId != null) q = q.eq('pharmacy_id', pharmacyId);
    return q.order('created_at', ascending: false);
  }

  static Future<void> addReceipt(Map<String, dynamic> data) =>
      client.from('receipts').insert(data);

  // ─── Attendance ────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAttendance({
    String? pharmacyId,
  }) async {
    var q = client
        .from('attendance')
        .select('*, employees!inner(name, pharmacy_id)');
    if (pharmacyId != null) q = q.eq('employees.pharmacy_id', pharmacyId);
    return q.order('date', ascending: false);
  }

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
