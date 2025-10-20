// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  MyAppointmentsScreenState createState() => MyAppointmentsScreenState();
}

class MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  // 1. Create an instance of ApiService here
  final ApiService _apiService = ApiService(); 
  
  List<dynamic> hospitalizations = [];
  bool isLoading = true;
  List<bool> expandedFlags = []; // Track expanded state for each card

  @override
  void initState() {
    super.initState();
    fetchHospitalizations();
  }

  Future<void> fetchHospitalizations() async {
    try {
      // 2. Call the method on the instance, not the class
      final data = await _apiService.getMyHospitalizations(); 
      
      setState(() {
        hospitalizations = data;
        expandedFlags = List<bool>.filled(data.length, false);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        // Use a dynamic message for better debugging
        SnackBar(content: Text("Failed to fetch hospitalizations: $e")),
      );
    }
  }

  Widget buildCard(int index) {
    // ... (rest of buildCard method is correct)
    final admission = hospitalizations[index];
    final isExpanded = expandedFlags[index];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          ListTile(
            // NOTE: You are displaying 'patient_name' here. Ensure your Python backend's 
            // `admission.to_dict()` includes the patient's name, or you might need to adjust this key.
            title: Text(admission['patient_name'] ?? 'Hospitalization Record'), 
            subtitle:  Text(
                  '${admission['admission_date']?.split('T').first ?? 'N/A'}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  expandedFlags[index] = !expandedFlags[index];
                });
              },
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Status: ${admission['status']}"),
                  const SizedBox(height: 8),
                  // Use a helper function for consistent detail lines
                  _buildDetailRow("Reason/Symptoms:", admission['reason_symptoms']),
                  _buildDetailRow("Gender:", admission['gender']),
                  _buildDetailRow("Age:", admission['patient_age'].toString()),
                  _buildDetailRow("Contact:", admission['contact_number']),
                  _buildDetailRow("Email:", admission['email']),
                  const Divider(),
                  _buildDetailRow("Bed ID:", admission['bed_partition_id']),
                  _buildDetailRow("Doctor ID:", admission['doctor_id']),
                  const Divider(),
                  _buildDetailRow("Guardian:", 
                      "${admission['guardian_name']} (${admission['guardian_relationship'] ?? 'Relation'})"),
                  _buildDetailRow("Guardian Contact:", admission['guardian_contact_number']),
                  const Divider(),
                  _buildDetailRow("Insurance:", 
                      "${admission['insurance_provider'] ?? 'N/A'} - ${admission['insurance_policy_number'] ?? 'N/A'}"),
                  _buildDetailRow("Payment Mode:", admission['payment_mode']),
                  const Divider(),
                  _buildDetailRow("Allergies:", admission['allergies']),
                  _buildDetailRow("Medications:", admission['current_medications']),
                  _buildDetailRow("Surgeries:", admission['past_surgeries']),
                  _buildDetailRow("Instructions:", admission['special_instructions']),
                  const Divider(),
                  _buildDetailRow("Seen by Doctor:", admission['is_seen_by_doctor'] ? 'Yes' : 'No'),
                  _buildDetailRow("Created At:", admission['created_at']),
                  _buildDetailRow("Updated At:", admission['updated_at']),
                  if (admission['rejection_reason'] != null)
                    _buildDetailRow("Rejection Reason:", admission['rejection_reason'], isBold: true),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Helper widget to display details clearly and handle nulls
  Widget _buildDetailRow(String label, dynamic value, {bool isBold = false}) {
    if (value == null || (value is String && value.isEmpty)) {
      return const SizedBox.shrink();
    }
    String displayValue = value.toString();
    if (displayValue == 'null') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text.rich(
        TextSpan(
          text: '$label ',
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500),
          children: [
            TextSpan(
              text: displayValue,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Hospitalizations")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hospitalizations.isEmpty
              ? const Center(child: Text("No hospitalizations found"))
              : ListView.builder(
                  itemCount: hospitalizations.length,
                  itemBuilder: (context, index) => buildCard(index),
                ),
    );
  }
}