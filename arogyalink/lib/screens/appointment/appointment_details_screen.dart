// lib/screens/appointment/appointment_details_screen.dart

// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final int admissionId;

  const AppointmentDetailsScreen({super.key, required this.admissionId});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _admissionFuture;

  // State for Change Ward dialog
  List<Map<String, dynamic>> _availableWards = [];
  String? _selectedWardId;

  // State for Approve Doctor dropdown
  List<Map<String, dynamic>> _hospitalDoctors = [];
  String? _selectedDoctorId;

  @override
  void initState() {
    super.initState();
    _refreshAdmissionDetails();
  }

  void _refreshAdmissionDetails() {
    setState(() {
      _admissionFuture = _apiService.getAdmissionDetails(widget.admissionId);
    });
  }

  // ✅ Fetch available wards
  Future<List<Map<String, dynamic>>> _fetchAvailableWards() async {
    final response = await _apiService.getBedPartitions();
    if (response['success'] == true && response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      throw response['message'] ?? 'Failed to load bed partitions.';
    }
  }

  // ✅ Fetch hospital doctors for approval dropdown
  Future<List<Map<String, dynamic>>> _fetchHospitalDoctors() async {
    final response = await _apiService.getDoctors();
    if (response['success'] == true && response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      throw response['message'] ?? 'Failed to load doctors.';
    }
  }

  // ✅ Approve admission with doctor selection
  void _approveAdmission() async {
    try {
      // 1️⃣ Fetch doctors
      _hospitalDoctors = await _fetchHospitalDoctors();
      if (_hospitalDoctors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No doctors available to assign.')),
        );
        return;
      }

      // 2️⃣ Show dialog for selecting doctor
      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              _selectedDoctorId ??= _hospitalDoctors.first['id'].toString();
              return AlertDialog(
                title: const Text('Assign Doctor'),
                content: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Select Doctor',
                  ),
                  value: _selectedDoctorId,
                  items: _hospitalDoctors.map((doc) {
                    final displayName =
                        '${doc['name']} (${doc['specialization']})';
                    return DropdownMenuItem<String>(
                      value: doc['id'].toString(),
                      child: Text(displayName),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setDialogState(() {
                      _selectedDoctorId = newValue;
                    });
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _selectedDoctorId == null
                        ? null
                        : () async {
                            Navigator.pop(context); // close dialog
                            try {
                              final result = await _apiService.updateAdmissionStatus(
                                admissionId: widget.admissionId,
                                action: "approve",
                                doctorId: int.parse(_selectedDoctorId!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? 'Approved'),
                                ),
                              );
                              _refreshAdmissionDetails();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                    child: const Text('Assign & Approve'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching doctors: $e')),
      );
    }
  }

  // ✅ Reject
  void _rejectAdmission() async {
    final TextEditingController reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Rejection Reason'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: "Reason for rejection",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reason cannot be empty')),
                );
                return;
              }
              Navigator.pop(context);
              try {
                final result = await _apiService.updateAdmissionStatus(
                  admissionId: widget.admissionId,
                  action: "reject",
                  rejectionReason: reason,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? 'Rejected')),
                );
                _refreshAdmissionDetails();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // ✅ Discharge
  void _dischargePatient() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Discharge'),
            content: const Text(
                'Are you sure you want to discharge this patient?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm')),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      final result = await _apiService.updateAdmissionStatus(
        admissionId: widget.admissionId,
        action: "discharge",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Patient Discharged')),
      );
      _refreshAdmissionDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error discharging patient: $e')),
      );
    }
  }

  // ✅ Change Ward dialog
  void _showChangeWardDialog() async {
    try {
      final partitions = await _fetchAvailableWards();
      setState(() {
        _availableWards = partitions;
        _selectedWardId = _availableWards.isNotEmpty
            ? _availableWards.first['id']?.toString()
            : null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching wards: $e')),
      );
      return;
    }

    if (_availableWards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available wards/beds found.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Ward/Bed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select a new Ward/Bed:'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Ward / Bed',
                ),
                value: _selectedWardId,
                items: _availableWards.map((partition) {
                  final name = partition['partition_name'] ?? 'Partition N/A';
                  final availableBeds =
                      partition['available_beds']?.toString() ?? 'N/A';
                  return DropdownMenuItem<String>(
                    value: partition['id'].toString(),
                    child: Text('$name (Available: $availableBeds)'),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setDialogState(() {
                    _selectedWardId = newValue;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
                onPressed: _selectedWardId == null
                    ? null
                    : () => _shiftPatientWard(context, _selectedWardId!),
                child: const Text('Shift')),
          ],
        ),
      ),
    );
  }

  void _shiftPatientWard(BuildContext dialogContext, String newWardId) async {
    Navigator.pop(dialogContext);
    try {
      final result = await _apiService.updateWardForAdmission(
        admissionId: widget.admissionId,
        newWardId: int.parse(newWardId),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Patient shifted successfully!')),
      );
      _refreshAdmissionDetails();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error shifting patient: $e')));
    }
  }

  // ----------------------------------------------------------------------
  // ✅ NEW WIDGET: Referring Doctor Card
  // ----------------------------------------------------------------------
  Widget _buildReferringDoctorCard(Map<String, dynamic> admission) {
    // Assuming the Flask backend provides these keys now:
    final doctorName = admission['referring_doctor_name'] ?? 'N/A';
    final specialization = admission['referring_doctor_specialization'] ?? 'N/A';
    final hospitalName = admission['referring_doctor_hospital_name'] ?? 'N/A';
    final referralReason = admission['referral_reason'] ?? 'N/A';
    final referralSymptoms = admission['referral_symptoms'] ?? 'N/A';
    final referralPrescription = admission['referral_prescription_details'] ?? 'N/A';

    if (doctorName == 'N/A' && hospitalName == 'N/A') {
      return Container(); // Hide the card if no referral data is present
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Doctor Referral Details'),
        Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (Doctor Name)
                Text(
                  'Referred by: Dr. $doctorName',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange),
                ),
                const Divider(),
                
                // Hospital and Specialization
                _buildDetailRow('Hospital', hospitalName),
                _buildDetailRow('Specialization', specialization),
                const SizedBox(height: 10),

                // Referral Notes
                _buildDetailRow('Referral Reason', referralReason),
                _buildDetailRow('Initial Symptoms', referralSymptoms),
                _buildDetailRow('Prescription', referralPrescription),
              ],
            ),
          ),
        ),
        const Divider(height: 30),
      ],
    );
  }
  // ----------------------------------------------------------------------


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admission Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _admissionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data found.'));
          } else {
            final admission = snapshot.data!;
            final admissionStatus = admission['status'];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ✅ NEW: Referring Doctor Card Integration ---
                  _buildReferringDoctorCard(admission),
                  // --- END NEW WIDGET ---

                  // --- Sections (Patient, Admission, Insurance, Emergency, Medical Notes)
                  _buildSectionTitle('Patient Details'),
                  _buildDetailRow('Name', admission['patient_name']),
                  _buildDetailRow('Age', admission['patient_age'].toString()),
                  _buildDetailRow('Gender', admission['gender']),
                  _buildDetailRow('Contact', admission['contact_number']),
                  _buildDetailRow('Email', admission['email'] ?? 'N/A'),
                  const Divider(height: 30),

                  _buildSectionTitle('Admission Details'),
                  _buildDetailRow(
                    'Admission Date',
                    admission['admission_date'] != null
                        ? DateFormat('yyyy-MM-dd')
                            .format(DateTime.parse(admission['admission_date']))
                        : 'N/A',
                  ),
                  _buildDetailRow('Reason / Symptoms', admission['reason_symptoms']),
                  _buildDetailRow('Status', admissionStatus),
                  if (admissionStatus == "Rejected" &&
                      admission['rejection_reason'] != null)
                    _buildDetailRow('Rejection Reason', admission['rejection_reason']),
                  const Divider(height: 30),

                  _buildSectionTitle('Insurance / Payment'),
                  _buildDetailRow('Provider', admission['insurance_provider'] ?? 'N/A'),
                  _buildDetailRow('Policy Number', admission['insurance_policy_number'] ?? 'N/A'),
                  _buildDetailRow('Payment Mode', admission['payment_mode'] ?? 'N/A'),
                  const Divider(height: 30),

                  _buildSectionTitle('Emergency Contact'),
                  _buildDetailRow('Guardian Name', admission['guardian_name'] ?? 'N/A'),
                  _buildDetailRow('Relationship', admission['guardian_relationship'] ?? 'N/A'),
                  _buildDetailRow('Contact', admission['guardian_contact_number'] ?? 'N/A'),
                  const Divider(height: 30),

                  _buildSectionTitle('Medical Notes'),
                  _buildDetailRow('Special Instructions', admission['special_instructions'] ?? 'N/A'),
                  _buildDetailRow('Allergies', admission['allergies'] ?? 'N/A'),
                  _buildDetailRow('Past Surgeries', admission['past_surgeries'] ?? 'N/A'),
                  _buildDetailRow('Current Medications', admission['current_medications'] ?? 'N/A'),
                  const SizedBox(height: 30),

                  // --- Buttons
                  Visibility(
                    visible: admissionStatus == "Pending",
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _approveAdmission,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Approve', style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          onPressed: _rejectAdmission,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Reject', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: admissionStatus == "Approved",
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _showChangeWardDialog,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text('Change Ward', style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          onPressed: _dischargePatient,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                          child: const Text('Discharge', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 16),
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      );

  Widget _buildDetailRow(String key, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: Text('$key:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Expanded(flex: 5, child: Text(value, style: const TextStyle(fontSize: 16))),
          ],
        ),
      );
}