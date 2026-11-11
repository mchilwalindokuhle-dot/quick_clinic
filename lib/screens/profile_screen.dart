import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _uid = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      setState(() {
        if (doc.exists) {
          final data = doc.data()!;
          _fullName = data['fullName'] ?? '';
          _email = data['email'] ?? user.email ?? '';
          _phone = data['phone'] ?? '';
        } else {
          _fullName = user.displayName ?? 'User';
          _email = user.email ?? '';
        }
        _uid = user.uid;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getInitials() {
    if (_fullName.isEmpty) return 'U';
    final parts = _fullName.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'
        .toUpperCase();
  }

  // ===== FEATURE 4: EDIT PROFILE DIALOG =====
  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _fullName);
    final phoneController = TextEditingController(text: _phone);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'fullName': nameController.text.trim(),
        'phone': phoneController.text.trim(),
      });

      // Also update Firebase Auth display name
      await FirebaseAuth.instance.currentUser?.updateDisplayName(
        nameController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _fullName = nameController.text.trim();
        _phone = phoneController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out of QuickClinic?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF0057B8),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0057B8),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF00C9A7)),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ===== AVATAR & NAME =====
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0057B8), Color(0xFF00C9A7)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C9A7).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _fullName.isEmpty ? 'User' : _fullName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ===== ACCOUNT INFORMATION =====
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    isDark: isDark,
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: _fullName,
                  ),
                  _buildInfoTile(
                    isDark: isDark,
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _email,
                  ),
                  _buildInfoTile(
                    isDark: isDark,
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: _phone.isEmpty ? 'Not set' : _phone,
                  ),
                  _buildInfoTile(
                    isDark: isDark,
                    icon: Icons.fingerprint,
                    label: 'User ID',
                    value: '${_uid.substring(0, 12)}...',
                  ),
                  const SizedBox(height: 28),

                  // ===== SETTINGS =====
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2332) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2D3748)
                            : const Color(0xFFF3F4F6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB800)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                            size: 20,
                            color: const Color(0xFFFFB800),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark Mode',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A2E),
                                ),
                              ),
                              Text(
                                isDark
                                    ? 'Currently enabled'
                                    : 'Currently disabled',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFFA0AEC0)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isDark,
                          onChanged: (value) {
                            themeProvider.toggleTheme();
                          },
                          activeThumbColor: const Color(0xFF00C9A7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ===== LOGOUT =====
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Log Out'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF3F4F6),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00C9A7).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF00C9A7)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFFA0AEC0)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
