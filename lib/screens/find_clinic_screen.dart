import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'book_appointment_screen.dart';

class FindClinicScreen extends StatefulWidget {
  const FindClinicScreen({super.key});

  @override
  State<FindClinicScreen> createState() => _FindClinicScreenState();
}

class _FindClinicScreenState extends State<FindClinicScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF0057B8),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Find a Clinic',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0057B8),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2332) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search for a clinic...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF6B7280)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clinics')
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

                final clinics = snapshot.data?.docs ?? [];
                final filteredClinics = clinics.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredClinics.isEmpty) {
                  return const Center(child: Text('No clinics found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredClinics.length,
                  itemBuilder: (context, index) {
                    final clinic =
                        filteredClinics[index].data() as Map<String, dynamic>;
                    return _buildClinicCard(
                      context,
                      clinicId: filteredClinics[index].id,
                      clinic: clinic,
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicCard(
    BuildContext context, {
    required String clinicId,
    required Map<String, dynamic> clinic,
    required bool isDark,
  }) {
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
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic['name'] ?? 'Unnamed Clinic',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                    // ===== AVERAGE RATING =====
                    _buildRatingRow(clinicId, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, clinic['address'] ?? 'No address'),
          _buildInfoRow(Icons.phone, clinic['phone'] ?? 'No phone'),
          _buildInfoRow(Icons.access_time, clinic['hours'] ?? 'No hours'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (clinic['services'] as List<dynamic>? ?? [])
                .map(
                  (service) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C9A7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      service.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF00C9A7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),

          // ===== NAVIGATE BUTTON =====
          OutlinedButton.icon(
            onPressed: () async {
              final lat = clinic['latitude'];
              final lng = clinic['longitude'];
              if (lat != null && lng != null) {
                final url = Uri.parse(
                  'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Location not available for this clinic.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.directions, size: 18),
            label: const Text('Get Directions'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: Color(0xFF0057B8)),
              foregroundColor: const Color(0xFF0057B8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ===== BOOK APPOINTMENT BUTTON =====
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookAppointmentScreen(
                      clinicId: clinicId,
                      clinicName: clinic['name'] ?? 'Clinic',
                      services: List<String>.from(clinic['services'] ?? []),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month, size: 18),
              label: const Text('Book Appointment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String clinicId, bool isDark) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('reviews')
          .where('clinicId', isEqualTo: clinicId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // No reviews yet
        }

        final reviews = snapshot.data!.docs;
        double total = 0;
        for (var doc in reviews) {
          total += (doc.data() as Map)['rating'] ?? 0;
        }
        final average = total / reviews.length;

        return Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFFFB800), size: 16),
            const SizedBox(width: 4),
            Text(
              '${average.toStringAsFixed(1)} (${reviews.length} reviews)',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        );
      },
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
}
