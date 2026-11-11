import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../services/notification_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String clinicId;
  final String clinicName;
  final List<String> services;

  const BookAppointmentScreen({
    super.key,
    required this.clinicId,
    required this.clinicName,
    required this.services,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String? _selectedService;
  final _otherServiceController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otherServiceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _bookAppointment() async {
    setState(() {
      _errorMessage = null;
    });

    if (_selectedService == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      setState(() {
        _errorMessage = 'Please select a service, date, and time.';
      });
      return;
    }

    if (_selectedService == 'Other' &&
        _otherServiceController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please describe your reason in the text field.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // ===== FEATURE 3: SLOT FULLY BOOKED CHECK =====
    final existing = await FirebaseFirestore.instance
        .collection('appointments')
        .where('clinicId', isEqualTo: widget.clinicId)
        .where('appointmentDate', isEqualTo: Timestamp.fromDate(dateTime))
        .where('status', isEqualTo: 'Approved')
        .get();

    if (existing.docs.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'This slot is already booked. Please choose a different time.';
        });
      }
      return;
    }
    // ===============================================

    final finalService = _selectedService == 'Other'
        ? _otherServiceController.text.trim()
        : _selectedService;

    await FirebaseFirestore.instance.collection('appointments').add({
      'userId': user.uid,
      'clinicId': widget.clinicId,
      'clinicName': widget.clinicName,
      'service': finalService,
      'appointmentDate': Timestamp.fromDate(dateTime),
      'status': 'Booked',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // ===== FEATURE 6: NOTIFICATION ON BOOKING =====
    await NotificationService.showNotification(
      title: 'Appointment Booked',
      body: 'Your appointment at ${widget.clinicName} has been requested.',
    );
    // ===============================================

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment booked successfully!'),
        backgroundColor: Color(0xFF00C9A7),
      ),
    );

    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy');
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
          widget.clinicName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0057B8),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a Service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.services.map((service) {
                final isSelected = _selectedService == service;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedService = service;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00C9A7)
                          : (isDark ? const Color(0xFF1A2332) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00C9A7)
                            : (isDark
                                  ? const Color(0xFF2D3748)
                                  : const Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Text(
                      service,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedService == 'Other') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _otherServiceController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Please describe your reason',
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Select a Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2332) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2D3748)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF6B7280)),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? 'Pick a date'
                          : dateFormat.format(_selectedDate!),
                      style: TextStyle(
                        fontSize: 15,
                        color: _selectedDate == null
                            ? const Color(0xFF6B7280)
                            : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2332) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2D3748)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF6B7280)),
                    const SizedBox(width: 12),
                    Text(
                      _selectedTime == null
                          ? 'Pick a time'
                          : _selectedTime!.format(context),
                      style: TextStyle(
                        fontSize: 15,
                        color: _selectedTime == null
                            ? const Color(0xFF6B7280)
                            : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null) ...[
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
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _isLoading ? null : _bookAppointment,
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Confirm Appointment'),
            ),
          ],
        ),
      ),
    );
  }
}
