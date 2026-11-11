import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          'My Appointments',
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
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['appointmentDate'] as Timestamp?;
                  final bTime = bData['appointmentDate'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return aTime.compareTo(bTime);
                });

                if (docs.isEmpty) {
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
                            Icons.calendar_today,
                            size: 60,
                            color: Color(0xFF00C9A7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No appointments yet',
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
                          'Book your first appointment to see it here.',
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
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildAppointmentCard(
                      context,
                      data,
                      docs[index].id,
                      isDark,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    bool isDark,
  ) {
    final date = (data['appointmentDate'] as Timestamp?)?.toDate();
    final formattedDate = date != null
        ? DateFormat('EEE, d MMM yyyy • h:mm a').format(date)
        : 'Unknown date';
    final status = data['status'] ?? 'Booked';

    final canRate = status == 'Approved'; // Temporarily removed isPast check

    Color chipColor;
    if (status == 'Approved') {
      chipColor = const Color(0xFF10B981);
    } else if (status == 'Rejected') {
      chipColor = const Color(0xFFEF4444);
    } else {
      chipColor = const Color(0xFFFFB800);
    }

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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C9A7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Color(0xFF00C9A7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  data['clinicName'] ?? 'Unknown Clinic',
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
                  color: chipColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: chipColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.medical_services,
            data['service'] ?? 'No service',
          ),
          _buildInfoRow(Icons.calendar_month, formattedDate),
          const SizedBox(height: 12),

          if (status == 'Rejected') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data['rejectionReason'] ?? 'Your appointment was rejected. Please book a new date.',
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Book Again'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00C9A7)),
                  foregroundColor: const Color(0xFF00C9A7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (canRate) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showRatingDialog(context, docId, data['clinicId']),
                icon: const Icon(Icons.star, size: 18),
                label: const Text('Rate Clinic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('appointments')
                    .doc(docId)
                    .delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment cancelled.'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.cancel,
                size: 18,
                color: Color(0xFFEF4444),
              ),
              label: const Text(
                'Cancel Appointment',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }

  // ===== RATING DIALOG =====
  Future<void> _showRatingDialog(
    BuildContext context,
    String appointmentId,
    String? clinicId,
  ) async {
    if (clinicId == null) return;

    int rating = 0;
    final reviewController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Rate Clinic'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFB800),
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reviewController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Write a short review (optional)',
                    border: OutlineInputBorder(),
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
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );

    if (submitted != true || rating == 0) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('reviews').add({
      'clinicId': clinicId,
      'userId': user.uid,
      'appointmentId': appointmentId,
      'rating': rating,
      'review': reviewController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your review!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }
}
