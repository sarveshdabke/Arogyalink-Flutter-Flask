// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';

class DoctorHospitalizationsScreen extends StatefulWidget {
  final String token;
  const DoctorHospitalizationsScreen({super.key, required this.token});

  @override
  State<DoctorHospitalizationsScreen> createState() =>
      _DoctorHospitalizationsScreenState();
}

class _DoctorHospitalizationsScreenState
    extends State<DoctorHospitalizationsScreen> {
  List<Map<String, dynamic>> hospitalizations = [];
  bool isLoading = true;
  List<bool> isExpandedList = [];

  @override
  void initState() {
    super.initState();
    loadHospitalizations();
  }

  Future<void> loadHospitalizations() async {
    setState(() => isLoading = true);
    try {
      final api = ApiService();
      final data = await api.getDoctorHospitalizations(widget.token);
      setState(() {
        hospitalizations = data;
        isLoading = false;
        isExpandedList = List.generate(hospitalizations.length, (_) => false);
      });
    } catch (e) {
      setState(() => isLoading = false);
      // ignore: duplicate_ignore
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching hospitalizations: $e')),
      );
    }
  }

  void openTreatmentForm(Map<String, dynamic> adm) {
    showDialog(
      context: context,
      builder: (context) {
        String treatmentNotes = '';
        String statusUpdate = 'In Progress';
        String referralReason = '';
        bool showReferral = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text("Doctor Treatment Form"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: "Treatment Notes"),
                    onChanged: (val) => treatmentNotes = val,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: statusUpdate,
                    items: const [
                      DropdownMenuItem(
                          value: "In Progress", child: Text("In Progress")),
                      DropdownMenuItem(
                          value: "Referred", child: Text("Referred")),
                      DropdownMenuItem(
                          value: "Discharged", child: Text("Discharged")),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        statusUpdate = val!;
                        showReferral = val == "Referred";
                      });
                    },
                    decoration: const InputDecoration(labelText: "Status Update"),
                  ),
                  if (showReferral) ...[
                    const SizedBox(height: 10),
                    TextField(
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: "Referral Reason"),
                      onChanged: (val) => referralReason = val,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ApiService().submitDoctorHospitalizationAction(
                      admissionId: adm['id'],
                      treatmentNotes: treatmentNotes,
                      statusUpdate: statusUpdate,
                      referralReason: referralReason,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Treatment saved successfully")),
                    );
                    loadHospitalizations(); // refresh list
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hospitalization Appointments")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hospitalizations.isEmpty
              ? const Center(child: Text("No hospitalizations assigned"))
              : ListView.builder(
                  itemCount: hospitalizations.length,
                  itemBuilder: (context, index) {
                    final adm = hospitalizations[index];
                    final isExpanded = isExpandedList[index];

                    return Card(
                      margin: const EdgeInsets.all(8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Basic Info ---
                            Text(adm['patient_name'] ?? "Unknown",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                                "Age: ${adm['patient_age'] ?? '-'} | Gender: ${adm['gender'] ?? '-'}"),
                            Text(
                                "Contact: ${adm['contact_number'] ?? '-'} | Email: ${adm['email'] ?? '-'}"),
                            Text(
                                "Admission Date: ${adm['admission_date']?.split('T').first ?? 'N/A'}"),
                            Text("Reason: ${adm['reason_symptoms'] ?? '-'}"),
                            Text("Status: ${adm['status'] ?? '-'}"),
                            if (adm['bed_partition_id'] != null)
                              Text("Bed Partition ID: ${adm['bed_partition_id']}"),
                            const SizedBox(height: 6),

                            // --- Row with Treatment & Expand Buttons ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.medical_services),
                                  label: const Text("Treatment"),
                                  onPressed: () => openTreatmentForm(adm),
                                ),
                                TextButton.icon(
                                  icon: Icon(isExpanded
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down),
                                  label: Text(isExpanded ? "Collapse" : "Expand"),
                                  onPressed: () {
                                    setState(() {
                                      isExpandedList[index] = !isExpandedList[index];
                                    });
                                  },
                                ),
                              ],
                            ),

                            // --- Expanded Section ---
                            if (isExpanded) ...[
                              const Divider(),
                              Text("Allergies: ${adm['allergies'] ?? '-'}"),
                              Text("Past Surgeries: ${adm['past_surgeries'] ?? '-'}"),
                              Text(
                                  "Current Medications: ${adm['current_medications'] ?? '-'}"),
                              
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
