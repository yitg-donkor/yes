import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

/// Public login screen.
/// Students can sign up here. Pharmacist/admin accounts are
/// created exclusively by admins inside the admin dashboard.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all required fields.');
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isLogin) {
        await SupabaseService.signIn(email, password);
        // AuthGate stream will navigate automatically on success
      } else {
        final name = _nameCtrl.text.trim();
        if (name.isEmpty) {
          _showError('Please enter your full name.');
          return;
        }
        if (password.length < 6) {
          _showError('Password must be at least 6 characters.');
          return;
        }
        await SupabaseService.signUp(
          email: email,
          password: password,
          name: name,
          role: 'student', // always student — no role picker on public screen
          studentId: _studentIdCtrl.text.trim().isEmpty
              ? null
              : _studentIdCtrl.text.trim(),
        );
        _showSuccess('Account created! Please sign in.');
        setState(() => _isLogin = true);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pharma One',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const Text(
                  'Your Campus Pharmacy',
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isLogin ? 'Sign In' : 'Create Student Account',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLogin
                              ? 'Sign in to access your pharmacy portal.'
                              : 'Create a student account to order medicines.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign-up only fields
                        if (!_isLogin) ...[
                          TextField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _studentIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Student ID (optional)',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Email
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Sign In' : 'Create Account',
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () =>
                              setState(() => _isLogin = !_isLogin),
                          child: Text(
                            _isLogin
                                ? "New student? Create an account"
                                : 'Already have an account? Sign In',
                            style:
                                const TextStyle(color: Color(0xFF2E7D32)),
                          ),
                        ),

                        // Staff hint
                        if (_isLogin) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Staff / Admin? Use your assigned credentials.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}