import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
    });

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();
    final error = await authService.loginWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
    } else {
      // After successful login, fetch the user's role from Firestore
      final user = FirebaseAuth.instance.currentUser;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final role = doc.data()?['role'] ?? 'patient';

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = AuthService();
    final error = await authService.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
    } else {
      // After successful Google Sign-In, fetch the user's role
      final user = FirebaseAuth.instance.currentUser;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final role = doc.data()?['role'] ?? 'patient';

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address. We will send you a link to reset your password.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00C9A7),
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );

    if (confirmed != true || controller.text.trim().isEmpty) return;

    final authService = AuthService();
    final error = await authService.sendPasswordReset(controller.text);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email.'),
          backgroundColor: Color(0xFF00C9A7),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0057B8), Color(0xFF00C9A7)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: _buildCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0057B8), Color(0xFF00C9A7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.local_hospital,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'QuickClinic',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to find a clinic near you',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Email address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          // Remember Me Checkbox
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF00C9A7),
                  ),
                  const Text(
                    'Remember me',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFF00C9A7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text('Login'),
          ),
          // OR Divider
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          // Google Sign-In Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleGoogleSignIn,
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Sign in with Google'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: const Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Register',
                  style: TextStyle(
                    color: Color(0xFF00C9A7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
