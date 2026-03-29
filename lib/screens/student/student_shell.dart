import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import 'student_home.dart';
import 'student_orders.dart';
import 'student_profile.dart';
import 'student_shop.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;
  List<Map<String, dynamic>> _cart = [];
  int _unreadNotifications = 0;
  Map<String, dynamic>? _profile;
  RealtimeChannel? _notificationsChannel;
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _notificationsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) {
      if (mounted) setState(() => _profileLoaded = true);
      return;
    }

    try {
      // Run both in parallel so we don't wait twice
      final results = await Future.wait([
        SupabaseService.getProfile(uid),
        SupabaseService.getUnreadCount(uid),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _unreadNotifications = results[1] as int;
          _profileLoaded = true;
        });
        // Only set up realtime after profile is loaded
        _setupNotifications(uid);
      }
    } catch (_) {
      // Profile load failed — still show the shell, just without profile data
      if (mounted) setState(() => _profileLoaded = true);
    }
  }

  void _setupNotifications(String uid) {
    _notificationsChannel?.unsubscribe();
    _notificationsChannel = SupabaseService.subscribeToNotifications(uid, (_) {
      if (mounted) setState(() => _unreadNotifications++);
    });
  }

  void _addToCart(Map<String, dynamic> product, int quantity) {
    setState(() {
      final existingIdx = _cart.indexWhere(
        (i) => i['product_id'] == product['id'],
      );
      if (existingIdx >= 0) {
        _cart[existingIdx]['quantity'] =
            (_cart[existingIdx]['quantity'] as int) + quantity;
      } else {
        _cart.add({
          'pharmacy_id': product['pharmacy_id'],
          'pharmacy_name': product['pharmacies']?['name'],
          'product_id': product['id'],
          'product_name': product['name'],
          'unit_price': product['unit_price'],
          'quantity': quantity,
        });
      }
    });
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => setState(() => _index = 2),
        ),
      ),
    );
  }

  void _updateCart(List<Map<String, dynamic>> cart) =>
      setState(() => _cart = cart);

  @override
  Widget build(BuildContext context) {
    // Show a simple loader while profile is being fetched
    // This prevents the freeze caused by IndexedStack building
    // all pages before profile data is available
    if (!_profileLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          StudentHomePage(
            profile: _profile,
            onAddToCart: _addToCart,
            onNavigateToShop: () => setState(() => _index = 1),
          ),
          StudentShopPage(onAddToCart: _addToCart),
          StudentOrdersPage(
            cart: _cart,
            onUpdateCart: _updateCart,
            profile: _profile,
            onOrderPlaced: () => setState(() {
              _cart = [];
              _index = 3;
            }),
          ),
          StudentProfilePage(
            profile: _profile,
            unreadCount: _unreadNotifications,
            onMarkRead: () => setState(() => _unreadNotifications = 0),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.store_rounded),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_rounded),
                if (_cart.isNotEmpty)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_cart.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.person_rounded),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
