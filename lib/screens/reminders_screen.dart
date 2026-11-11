import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../providers/theme_provider.dart';

import 'package:provider/provider.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1620)
          : const Color(0xFFF5F9FF),
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
          'Reminders',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0057B8),
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please log in first.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('userId', isEqualTo: user.uid)
                  .where('status', isEqualTo: 'Approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final now = DateTime.now();
                final nextWeek = now.add(const Duration(days: 7));

                // Filter for appointments within the next 7 days
                final upcoming = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['appointmentDate'] as Timestamp?)
                      ?.toDate();
                  if (date == null) return false;
                  return date.isAfter(now) && date.isBefore(nextWeek);
                }).toList();

                // Sort by date
                upcoming.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['appointmentDate'] as Timestamp?;
                  final bTime = bData['appointmentDate'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return aTime.compareTo(bTime);
                });

                if (upcoming.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C9A7)
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none,
                            size: 60,
                            color: Color(0xFF00C9A7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No upcoming reminders',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You have no appointments in the next 7 days.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: upcoming.length,
                  itemBuilder: (context, index) {
                    final data = upcoming[index].data() as Map<String, dynamic>;
                    final date = (data['appointmentDate'] as Timestamp?)
                        ?.toDate();
                    final formattedDate = date != null
                        ? DateFormat('EEE, d MMM yyyy • h:mm a').format(date)
                        : 'Unknown date';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A2332) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.05,
                            ),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C9A7)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_active,
                              color: Color(0xFF00C9A7),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['clinicName'] ?? 'Clinic',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['service'] ?? 'Service',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF00C9A7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
