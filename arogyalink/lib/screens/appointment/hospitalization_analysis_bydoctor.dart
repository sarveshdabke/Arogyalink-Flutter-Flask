// ignore_for_file: file_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class DoctorTreatmentAnalysisScreen extends StatefulWidget {
  const DoctorTreatmentAnalysisScreen({super.key});

  @override
  State<DoctorTreatmentAnalysisScreen> createState() =>
      _DoctorTreatmentAnalysisScreenState();
}

class _DoctorTreatmentAnalysisScreenState
    extends State<DoctorTreatmentAnalysisScreen> {
  bool _isLoading = true;
  List<dynamic> _treatmentHistory = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchTreatmentHistory();
  }

  Future<void> _fetchTreatmentHistory() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.getDoctorTreatmentHistory();

    if (result['success'] == true && result['data'] != null) {
      setState(() {
        _treatmentHistory = List<Map<String, dynamic>>.from(result['data']);
        _isLoading = false;
      });
      // 🔹 Mark all as seen when screen opens
      await _apiService.markTreatmentAsSeen();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Failed to load data")),
      );
    }
  }

  Future<void> _refreshHistory() async {
    await _fetchTreatmentHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Treatment Analysis"),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _treatmentHistory.isEmpty
              ? const Center(
                  child: Text(
                    "No treatment history found.",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _treatmentHistory.length,
                    itemBuilder: (context, index) {
                      final history = _treatmentHistory[index];
                      final patientName =
                          history['patient_name'] ?? "Unknown Patient";
                      final doctorName =
                          history['doctor_name'] ?? "Unknown Doctor";
                      final treatmentNotes =
                          history['treatment_notes'] ?? "No notes";
                      final statusUpdate =
                          history['status_update'] ?? "No status";
                      final referralReason = history['referral_reason'] ?? 'N/A';
                      final timestamp = history['timestamp'] != null
                          ? DateFormat('dd MMM yyyy, hh:mm a')
                              .format(DateTime.parse(history['timestamp']))
                          : "Unknown time";

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.blueAccent),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text("Doctor: $doctorName"),
                              const SizedBox(height: 6),
                              Text("Treatment Notes: $treatmentNotes"),
                              const SizedBox(height: 4),
                              Text("Status Update: $statusUpdate"),
                              const SizedBox(height: 4),
                              Text("Referral Reason: $referralReason"),
                              const SizedBox(height: 6),
                              Text(
                                "Timestamp: $timestamp",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
