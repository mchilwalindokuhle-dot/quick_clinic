import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedRole = 'patient';

  // Clinic selection for Admins
  String? _selectedClinicId;
  String? _selectedClinicName;
  List<Map<String, dynamic>> _clinics = [];

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('clinics')
        .get();
    setState(() {
      _clinics = snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              'name': doc.data()['name'] ?? 'Unnamed Clinic',
            },
          )
          .toList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
    });

    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    if (_selectedRole == 'admin' && _selectedClinicId == null) {
      setState(() {
        _errorMessage = 'Please select the clinic you manage.';
      });
      return;
    }

    if (!_emailController.text.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();
    final error = await authService.registerWithEmail(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: _selectedRole,
      clinicId: _selectedRole == 'admin' ? _selectedClinicId : null,
      clinicName: _selectedRole == 'admin' ? _selectedClinicName : null,
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
      if (_selectedRole == 'admin') {
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
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
            child: const Icon(Icons.person_add, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Join QuickClinic to get started',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            decoration: const InputDecoration(
              hintText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              hintText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_reset),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ===== ROLE SELECTOR =====
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'I am registering as:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Patient'),
                  selected: _selectedRole == 'patient',
                  onSelected: (selected) {
                    setState(() {
                      _selectedRole = 'patient';
                      _selectedClinicId = null; // Reset clinic
                    });
                  },
                  selectedColor: const Color(0xFF00C9A7).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _selectedRole == 'patient'
                        ? const Color(0xFF00C9A7)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Clinic Admin'),
                  selected: _selectedRole == 'admin',
                  onSelected: (selected) {
                    setState(() {
                      _selectedRole = 'admin';
                    });
                  },
                  selectedColor: const Color(0xFF0057B8).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _selectedRole == 'admin'
                        ? const Color(0xFF0057B8)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          // ===== CLINIC DROPDOWN (Only for Admin) =====
          if (_selectedRole == 'admin') ...[
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select your clinic:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedClinicId,
              decoration: const InputDecoration(
                hintText: 'Choose a clinic',
                prefixIcon: Icon(Icons.local_hospital),
              ),
              items: _clinics.map((clinic) {
                return DropdownMenuItem<String>(
                  value: clinic['id'],
                  child: Text(clinic['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedClinicId = value;
                  _selectedClinicName = _clinics.firstWhere(
                    (c) => c['id'] == value,
                  )['name'];
                });
              },
            ),
          ],
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text('Create Account'),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Login',
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
