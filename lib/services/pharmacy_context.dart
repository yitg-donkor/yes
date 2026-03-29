// ============================================================================
// PHARMACY CONTEXT HELPER SERVICE
// lib/services/pharmacy_context.dart
// ============================================================================
// This helper ensures all admin operations include the correct pharmacy_id
// Use this across all admin screens to avoid RLS violations
// ============================================================================

import 'package:group_9/services/supabase_service.dart';

class PharmacyContext {
  static String? _cachedPharmacyId;
  static String? _cachedUserId;

  /// Get the current user's pharmacy_id
  /// Returns null if user is not staff or doesn't have a pharmacy
  static Future<String?> getPharmacyId() async {
    final userId = SupabaseService.currentUserId;

    // Return cached value if user hasn't changed
    if (userId == _cachedUserId && _cachedPharmacyId != null) {
      return _cachedPharmacyId;
    }

    if (userId == null) return null;

    try {
      final profile = await SupabaseService.getProfile(userId);
      _cachedUserId = userId;
      _cachedPharmacyId = profile?['pharmacy_id'] as String?;
      return _cachedPharmacyId;
    } catch (e) {
      print('Error getting pharmacy_id: $e');
      return null;
    }
  }

  /// Clear the cached pharmacy_id (call on logout)
  static void clearCache() {
    _cachedPharmacyId = null;
    _cachedUserId = null;
  }

  /// Add pharmacy_id to data map if not already present
  /// Returns the updated data map
  static Future<Map<String, dynamic>> addPharmacyId(
    Map<String, dynamic> data, {
    bool force = false,
  }) async {
    // Skip if pharmacy_id already exists and we're not forcing
    if (!force && data.containsKey('pharmacy_id')) {
      return data;
    }

    final pharmacyId = await getPharmacyId();
    if (pharmacyId != null) {
      data['pharmacy_id'] = pharmacyId;
    }

    return data;
  }

  /// Validate that a pharmacy_id matches the current user's pharmacy
  /// Useful for update operations
  static Future<bool> validatePharmacyId(String? pharmacyId) async {
    if (pharmacyId == null) return false;
    final myPharmacyId = await getPharmacyId();
    return pharmacyId == myPharmacyId;
  }
}
