// lib/screens/doctors/refer_hospitalization_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';

class ReferHospitalizationScreen extends StatefulWidget {
  final String token; // JWT token for doctor
  const ReferHospitalizationScreen({super.key, required this.token});

  @override
  State<ReferHospitalizationScreen> createState() =>
      _ReferHospitalizationScreenState();
}

class _ReferHospitalizationScreenState
    extends State<ReferHospitalizationScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> referredAppointments = [];

  @override
  void initState() {
    super.initState();
    fetchReferredAppointments();
  }

  Future<void> fetchReferredAppointments() async {
    setState(() => isLoading = true);
    try {
      final api = ApiService();
      final data = await api.getDoctorReferredAppointments(widget.token);
      setState(() {
        referredAppointments =
            List<Map<String, dynamic>>.from(data['appointments']);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch referred appointments: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer Hospitalization'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : referredAppointments.isEmpty
              ? const Center(
                  child: Text(
                    'No referred appointments found',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: referredAppointments.length,
                  itemBuilder: (context, index) {
                    final appt = referredAppointments[index];
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appt['patient_name'] ?? "Unknown",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                "Age: ${appt['patient_age'] ?? '-'} | Gender: ${appt['gender'] ?? '-'}"),
                            Text(
                                "Contact: ${appt['patient_contact'] ?? '-'} | Email: ${appt['patient_email'] ?? '-'}"),
                            Text(
                                "Time: ${appt['start_time'] ?? '-'} - ${appt['end_time'] ?? '-'}"),
                            Text("Symptoms: ${appt['symptoms'] ?? '-'}"),
                            Text("Token No: ${appt['token_number'] ?? '-'}"),
                            Text("Status: ${appt['status'] ?? '-'}"),
                            Text(
                              "Referral Reason: ${appt['referral_reason'] ?? '-'}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            if (appt['is_emergency'] ?? false)
                              const Text(
                                "⚠️ Emergency",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
