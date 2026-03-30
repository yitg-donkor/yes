import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_shell.dart';
import 'screens/super_admin/super_admin_shell.dart';
import 'services/supabase_service.dart';

const String _supabaseUrl = 'https://vdhgroudezwfgjjrawto.supabase.co';
const String _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZkaGdyb3VkZXp3ZmdqanJhd3RvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM5MTQ0OTYsImV4cCI6MjA4OTQ5MDQ5Nn0.2DU035H7mD3Wy-FOYFnMWnh3gPjnE2uKT08I0iTubOM';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  runApp(const PharmaOneApp());
}

class PharmaOneApp extends StatelessWidget {
  const PharmaOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharma One',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ── Auth Gate ─────────────────────────────────────────────────────────────────

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final session = snapshot.data?.session;
        if (session == null) return const LoginScreen();

        return FutureBuilder<Map<String, dynamic>?>(
          future: SupabaseService.getProfile(session.user.id),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            final profile = profileSnapshot.data;
            final role =
                profile?['role']?.toString() ??
                session.user.userMetadata?['role']?.toString() ??
                'student';

            // Staff roles need a pharmacy suspension check
            if (role == 'admin' || role == 'pharmacist') {
              final pharmacyId = profile?['pharmacy_id'] as String?;
              if (pharmacyId != null) {
                return _PharmacyGate(pharmacyId: pharmacyId, role: role);
              }
            }

            return switch (role) {
              'super_admin' => const SuperAdminShell(),
              'admin' => const AdminShell(portalType: AdminPortalType.admin),
              'pharmacist' => const AdminShell(
                portalType: AdminPortalType.worker,
              ),
              _ => const StudentShell(),
            };
          },
        );
      },
    );
  }
}

// ── Pharmacy Gate ─────────────────────────────────────────────────────────────
// Actively checks pharmacy suspension status on mount and when the app
// resumes from background, so suspension takes effect immediately even
// for already-logged-in staff.

class _PharmacyGate extends StatefulWidget {
  final String pharmacyId;
  final String role;

  const _PharmacyGate({required this.pharmacyId, required this.role});

  @override
  State<_PharmacyGate> createState() => _PharmacyGateState();
}

class _PharmacyGateState extends State<_PharmacyGate>
    with WidgetsBindingObserver {
  bool? _isActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check every time the app comes back to the foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final active = await SupabaseService.isPharmacyActive(widget.pharmacyId);
    if (mounted) setState(() => _isActive = active);
  }

  @override
  Widget build(BuildContext context) {
    if (_isActive == null) return const _LoadingScreen();

    if (!_isActive!) {
      return _SuspendedScreen(onSignOut: () => SupabaseService.signOut());
    }

    return widget.role == 'admin'
        ? const AdminShell(portalType: AdminPortalType.admin)
        : const AdminShell(portalType: AdminPortalType.worker);
  }
}

// ── Shared Screens ────────────────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
    );
  }
}

class _SuspendedScreen extends StatelessWidget {
  final VoidCallback onSignOut;

  const _SuspendedScreen({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block_rounded,
                  size: 64,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Pharmacy Suspended',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your pharmacy has been suspended by the network '
                'administrator. Please contact support for assistance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
