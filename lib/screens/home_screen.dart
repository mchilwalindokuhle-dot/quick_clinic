import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import 'find_clinic_screen.dart';
import 'my_appointments_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'reminders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User';
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

      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _userName = data?['fullName']?.split(' ').first ?? 'User';
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _userName = user.displayName?.split(' ').first ?? 'User';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isLoading ? 'Hello 👋' : 'Hello, $_userName 👋',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: themeProvider.isDarkMode
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF0057B8),
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== WELCOME BANNER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0057B8), Color(0xFF00C9A7)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C9A7).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.local_hospital,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'QuickClinic',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find a clinic. Book an appointment. Skip the queue.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // ===== QUICK ACTIONS =====
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context: context,
              title: 'Find a Clinic',
              subtitle: 'See clinics near you',
              icon: Icons.local_hospital,
              gradientColors: const [Color(0xFF0057B8), Color(0xFF00C9A7)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FindClinicScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context: context,
              title: 'My Appointments',
              subtitle: 'View your booked slots',
              icon: Icons.calendar_today,
              gradientColors: const [Color(0xFF00C9A7), Color(0xFF0057B8)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyAppointmentsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context: context,
              title: 'Profile',
              subtitle: 'Manage your account',
              icon: Icons.person,
              gradientColors: const [Color(0xFFFFB800), Color(0xFFE0A000)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context: context,
              title: 'Reminders',
              subtitle: 'Upcoming appointment alerts',
              icon: Icons.notifications_active,
              gradientColors: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RemindersScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2332) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}
