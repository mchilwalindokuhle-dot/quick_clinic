import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../services/notification_service.dart';

import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _adminName = 'Admin';
  String? _adminClinicId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _adminName = doc.data()?['fullName']?.split(' ').first ?? 'Admin';
          _adminClinicId = doc.data()?['clinicId'];
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    String? selectedReason;

    final commonReasons = [
      'Slot fully booked',
      'Clinic closed on that date',
      'Doctor unavailable',
      'Incorrect patient information',
      'Other (type below)',
    ];

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Reject Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select a reason:'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: commonReasons.map((reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value;
                    });
                  },
                ),
                if (selectedReason == 'Other (type below)') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type your custom reason here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (selectedReason == 'Other (type below)') {
                    Navigator.pop(context, controller.text.trim());
                  } else {
                    Navigator.pop(context, selectedReason);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                ),
                child: const Text('Reject'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1620)
          : const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0057B8),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _adminClinicId == null
          ? const Center(child: Text('No clinic assigned to this admin.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('clinicId', isEqualTo: _adminClinicId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                final pending = docs
                    .where((doc) => (doc.data() as Map)['status'] == 'Booked')
                    .length;
                final approved = docs
                    .where((doc) => (doc.data() as Map)['status'] == 'Approved')
                    .length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(isDark),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total',
                              docs.length.toString(),
                              Icons.calendar_month,
                              const Color(0xFF0057B8),
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Pending',
                              pending.toString(),
                              Icons.pending_actions,
                              const Color(0xFFFFB800),
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Approved',
                              approved.toString(),
                              Icons.check_circle,
                              const Color(0xFF10B981),
                              isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Recent Appointments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (docs.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('No appointments for your clinic yet.'),
                          ),
                        )
                      else
                        ...docs.map(
                          (doc) => _buildAppointmentCard(context, doc, isDark),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _adminName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $_adminName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage clinic appointments',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    DocumentSnapshot doc,
    bool isDark,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['appointmentDate'] as Timestamp?)?.toDate();
    final formattedDate = date != null
        ? DateFormat('EEE, d MMM yyyy • h:mm a').format(date)
        : 'Unknown';
    final status = data['status'] ?? 'Booked';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['clinicName'] ?? 'Clinic',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: status == 'Approved'
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : (status == 'Rejected'
                            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                            : const Color(0xFFFFB800).withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: status == 'Approved'
                        ? const Color(0xFF10B981)
                        : (status == 'Rejected'
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFFFB800)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.medical_services, data['service'] ?? 'N/A'),
          _buildInfoRow(Icons.calendar_today, formattedDate),
          _buildInfoRow(
            Icons.person,
            'Patient ID: ${data['userId']?.substring(0, 8)}...',
          ),
          const SizedBox(height: 12),
          if (status == 'Booked') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // 1. Update Firestore
                      await FirebaseFirestore.instance
                          .collection('appointments')
                          .doc(doc.id)
                          .update({'status': 'Approved'});

                      // 2. Show Notification (AFTER the update)
                      await NotificationService.showNotification(
                        title: 'Appointment Approved',
                        body: 'You have approved an appointment.',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final reason = await _showRejectDialog();
                      if (reason != null && reason.isNotEmpty) {
                        // 1. Update Firestore
                        await FirebaseFirestore.instance
                            .collection('appointments')
                            .doc(doc.id)
                            .update({
                              'status': 'Rejected',
                              'rejectionReason': reason,
                            });

                        // 2. Show Notification (AFTER the update)
                        await NotificationService.showNotification(
                          title: 'Appointment Rejected',
                          body: 'You have rejected an appointment.',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}
