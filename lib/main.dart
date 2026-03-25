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
                borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

            final role =
                profileSnapshot.data?['role']?.toString() ??
                session.user.userMetadata?['role']?.toString() ??
                'student';

            // ── Role-based routing ────────────────────────────────────────
            return switch (role) {
              'super_admin' => const SuperAdminShell(),
              'admin'       => const AdminShell(portalType: AdminPortalType.admin),
              'pharmacist'  => const AdminShell(portalType: AdminPortalType.worker),
              _             => const StudentShell(),
            };
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
    );
  }
}