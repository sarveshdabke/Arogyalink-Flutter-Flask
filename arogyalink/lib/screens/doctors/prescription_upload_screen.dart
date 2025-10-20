// lib/screens/doctors/prescription_upload_screen.dart

import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';

class PrescriptionUploadScreen extends StatefulWidget {
  final String token;
  const PrescriptionUploadScreen({super.key, required this.token});

  @override
  State<PrescriptionUploadScreen> createState() =>
      _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState extends State<PrescriptionUploadScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> completedAppointments = [];
  // Retaining this for UI state, as it was present in your working code.
  int? selectedAppointmentId; 

  @override
  void initState() {
    super.initState();
    loadCompletedAppointments();
  }

  Future<void> loadCompletedAppointments() async {
    setState(() => isLoading = true);
    try {
      final api = ApiService();
      // Assuming getCompletedAppointments returns List<Map<String, dynamic>>
      final List<dynamic> appointmentsData = await api.getCompletedAppointments(widget.token);
      
      if (!mounted) return;
      setState(() {
        completedAppointments = appointmentsData.cast<Map<String, dynamic>>(); 
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load appointments: ${e.toString()}')),
      );
    }
  }

  void showAddPrescriptionDialog(Map<String, dynamic> appt) {
    final TextEditingController medicinesController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // This is the core logic that was working in your successful snippet.
    // The issue was likely due to an inconsistency in the ApiService implementation 
    // or how the backend handles the key names.

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        // Enhanced title for better context
        title: Text("Prescription for ${appt['patient_name'] ?? 'Patient'}"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Patient Info Row
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Token: ${appt['token_number'] ?? '-'} | Symptoms: ${appt['symptoms'] ?? '-'}',
                    style: TextStyle(color: Colors.indigo.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),

                // Medicines Field (Multi-line)
                TextFormField(
                  controller: medicinesController,
                  decoration: const InputDecoration(
                    labelText: 'Medicines & Dosage',
                    hintText: 'e.g., Paracetamol 500mg - Twice daily for 5 days',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medical_services_outlined, size: 20),
                  ),
                  minLines: 3,
                  maxLines: 5,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter medicines and dosage details' : null,
                ),
                const SizedBox(height: 15),

                // Notes Field (Optional, but included)
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'General Notes/Instructions',
                    hintText: 'e.g., Follow up in 7 days, rest well.',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes, size: 20),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                
                // 1. Prepare Data
                String prescriptionDetails =
                    "Medicines: ${medicinesController.text.trim()}\n"
                    "Notes: ${notesController.text.trim()}";

                // Close the dialog and show progress
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Submitting prescription...')),
                );
                
                try {
                  final api = ApiService();
                  
                  // 2. The working API call structure
                  await api.addPrescription(
                    widget.token,
                    int.parse(appt['id'].toString()), // Appointment ID
                    {'prescription_details': prescriptionDetails}, // Payload
                  );

                  // 3. Update UI after successful API call
                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).clearSnackBars(); // Clear submitting message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Prescription added successfully'),
                        backgroundColor: Colors.green),
                  );

                  // Remove the appointment from the list and reset selection
                  setState(() {
                    completedAppointments
                        .removeWhere((a) => a['id'] == appt['id']);
                    selectedAppointmentId = null; // Important: Clear selection
                  });
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add prescription: ${e.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal, 
              foregroundColor: Colors.white,
            ),
            child: const Text("Submit Prescription"),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Info Rows (Reintroduced from earlier version for clean UI)
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.indigo.shade400),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Upload'),
        backgroundColor: Colors.indigo, // Coordinated color
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadCompletedAppointments,
            tooltip: 'Refresh Appointments',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : completedAppointments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade200),
                        const SizedBox(height: 24),
                        const Text(
                          'No pending prescriptions',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'All completed appointments have prescriptions uploaded.',
                          style: TextStyle(fontSize: 16, color: Colors.black45),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: completedAppointments.length,
                  itemBuilder: (context, index) {
                    final appt = completedAppointments[index];
                    final isSelected = selectedAppointmentId == appt['id'];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: isSelected ? 8 : 4, // Higher elevation when selected
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isSelected ? Colors.teal : Colors.indigo.shade100, width: isSelected ? 2 : 1),
                      ),
                      child: InkWell(
                        // Tap, double-tap, or long-press can select the card
                        onTap: () {
                           setState(() {
                             selectedAppointmentId = selectedAppointmentId == appt['id'] ? null : appt['id'];
                           });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Patient Name and Status
                              Text(
                                appt['patient_name'] ?? 'Unknown Patient',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.indigo,
                                ),
                              ),
                              const Divider(height: 15),

                              // 2. Appointment Details Rows
                              _buildInfoRow('Token', appt['token_number']?.toString() ?? '-', Icons.confirmation_number),
                              const SizedBox(height: 5),
                              _buildInfoRow('Age/Gender', '${appt['patient_age'] ?? '-'} / ${appt['gender'] ?? '-'}', Icons.person_outline),
                              const SizedBox(height: 5),
                              _buildInfoRow('Symptoms', appt['symptoms'] ?? 'N/A', Icons.local_hospital_outlined),
                              
                              // 3. Action Button (Shown only if selected)
                              if (isSelected) ...[
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => showAddPrescriptionDialog(appt),
                                    icon: const Icon(Icons.receipt_long),
                                    label: const Text("Add Prescription"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal, // Distinct action color
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}