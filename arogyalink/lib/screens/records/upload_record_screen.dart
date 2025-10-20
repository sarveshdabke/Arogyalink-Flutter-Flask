// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arogyalink/services/api_service.dart';

class UploadRecordScreen extends StatefulWidget {
  const UploadRecordScreen({super.key});

  @override
  State<UploadRecordScreen> createState() => _UploadRecordScreenState();
}

class _UploadRecordScreenState extends State<UploadRecordScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _approvedAdmissionsFuture;

  // Track expanded state
  final Map<int, bool> _expandedCards = {}; 

  // Controllers
  final Map<int, TextEditingController> _roomFeeController = {};
  final Map<int, TextEditingController> _doctorFeeController = {};
  final Map<int, Map<int, TextEditingController>> _treatmentFeeControllers = {}; // treatment_id -> controller
  final Map<int, TextEditingController> _medicineFeeController = {};
  final Map<int, TextEditingController> _diagnosticFeeController = {};
  final Map<int, TextEditingController> _miscFeeController = {};
  final Map<int, TextEditingController> _insuranceCoveredController = {};

  @override
  void initState() {
    super.initState();
    _approvedAdmissionsFuture =
        _apiService.getDischargedHospitalizationAdmissions();
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "N/A";
    try {
      DateTime parsedDate = DateTime.parse(dateString);
      return "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString.split(" ").first; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Generate Hospitalization Bills',
          style: GoogleFonts.poppins(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _approvedAdmissionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!['success'] == false) {
            return Center(
              child: Text(snapshot.data?['message'] ?? 'No data found.'),
            );
          } else {
            final List admissions = snapshot.data!['data'];
            if (admissions.isEmpty) {
              return const Center(child: Text('No approved admissions found.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: admissions.length,
              itemBuilder: (context, index) {
                final admission = admissions[index];
                final admissionId = admission['id'];

                _expandedCards[admissionId] ??= false;
                _roomFeeController[admissionId] ??= TextEditingController(text: "2000");
                _doctorFeeController[admissionId] ??= TextEditingController(text: "1000");
                _medicineFeeController[admissionId] ??= TextEditingController(text: "500");
                _diagnosticFeeController[admissionId] ??= TextEditingController(text: "0");
                _miscFeeController[admissionId] ??= TextEditingController(text: "200");
                _insuranceCoveredController[admissionId] ??= TextEditingController(text: "0");
                _treatmentFeeControllers[admissionId] ??= {};

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Patient Info
                          Text(
                            admission['patient_name'] ?? "Unknown",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("Admission: ${admission['admission_date']?.split('T').first ?? 'N/A'}"),
                          Text("Discharge: ${_formatDate(admission['discharge_date'])}"),
                          Text("Status: ${admission['status'] ?? 'N/A'}"),
                          Text("Reason: ${admission['reason_symptoms'] ?? 'N/A'}"),

                          const SizedBox(height: 12),
                          // Toggle Expand
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _expandedCards[admissionId] = !_expandedCards[admissionId]!;
                                });
                              },
                              child: Text(
                                _expandedCards[admissionId]! ? "Close Bill Form" : "Generate Bill",
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                          ),

                          // Expanded Form
                          if (_expandedCards[admissionId]!)
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _apiService.fetchTreatmentHistory(admissionId),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final treatments = snapshot.data!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    // Room Charges
                                    TextField(
                                      controller: _roomFeeController[admissionId],
                                      decoration: const InputDecoration(
                                        labelText: "Room Charges",
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 8),
                                    // Doctor Fees
                                    TextField(
                                      controller: _doctorFeeController[admissionId],
                                      decoration: const InputDecoration(
                                        labelText: "Doctor Fees",
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 8),
                                    // Medicine Charges
                                    TextField(
                                      controller: _medicineFeeController[admissionId],
                                      decoration: const InputDecoration(
                                        labelText: "Medicine Charges",
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 8),
                                    // Diagnostic Charges
                                    TextField(
                                      controller: _diagnosticFeeController[admissionId],
                                      decoration: const InputDecoration(
                                        labelText: "Diagnostic Charges",
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 8),
                                    // Misc Charges
                                    TextField(
                                      controller: _miscFeeController[admissionId],
                                      decoration: const InputDecoration(
                                        labelText: "Misc Charges",
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 8),
                                    // Insurance Covered
                                    TextField(
                                      controller: _insuranceCoveredController[admissionId],
                                      decoration: const InputDecoration(
                                        labelText: "Insurance Covered",
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 12),
                                    // Treatments
                                    ...treatments.map((treatment) {
                                      final tId = treatment['id'];
                                      _treatmentFeeControllers[admissionId]![tId] ??= TextEditingController();

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Treatment Note: ${treatment['treatment_notes'] ?? 'N/A'}",
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              "Status Update: ${treatment['status_update'] ?? 'N/A'}",
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(height: 4),
                                            TextField(
                                              controller: _treatmentFeeControllers[admissionId]![tId],
                                              decoration: const InputDecoration(
                                                labelText: "Enter Fee for this Treatment",
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          // Collect all fees
                                          double roomCharges = double.tryParse(_roomFeeController[admissionId]!.text) ?? 0;
                                          double doctorFees = double.tryParse(_doctorFeeController[admissionId]!.text) ?? 0;
                                          double medicineCharges = double.tryParse(_medicineFeeController[admissionId]!.text) ?? 0;
                                          double diagnosticCharges = double.tryParse(_diagnosticFeeController[admissionId]!.text) ?? 0;
                                          double miscCharges = double.tryParse(_miscFeeController[admissionId]!.text) ?? 0;
                                          double insuranceCovered = double.tryParse(_insuranceCoveredController[admissionId]!.text) ?? 0;

                                          double treatmentCharges = 0;
                                          _treatmentFeeControllers[admissionId]!.forEach((k, controller) {
                                            treatmentCharges += double.tryParse(controller.text) ?? 0;
                                          });

                                          // Call API to generate bill
                                          final billData = await _apiService.generateHospitalizationBill(
                                            admissionId,
                                            roomCharges: roomCharges,
                                            doctorFees: doctorFees,
                                            treatmentCharges: treatmentCharges,
                                            medicineCharges: medicineCharges,
                                            diagnosticCharges: diagnosticCharges,
                                            miscCharges: miscCharges,
                                            insuranceCovered: insuranceCovered,
                                          );

                                          if (billData != null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("Bill Generated Successfully! Total: ${billData['net_payable']}"),
                                              ),
                                            );
                                            setState(() {
                                              _expandedCards[admissionId] = false;
                                            });
                                          }
                                        },
                                        child: const Text("Submit Bill"),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
