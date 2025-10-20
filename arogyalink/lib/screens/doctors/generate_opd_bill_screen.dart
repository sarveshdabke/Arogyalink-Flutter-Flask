// lib/screens/doctors/generate_opd_bill_screen.dart

import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';

class GenerateOPDBillScreen extends StatefulWidget {
  final String token; // JWT token
  const GenerateOPDBillScreen({super.key, required this.token});

  @override
  State<GenerateOPDBillScreen> createState() => _GenerateOPDBillScreenState();
}

class _GenerateOPDBillScreenState extends State<GenerateOPDBillScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> patients = [];
  Map<String, dynamic>? selectedPatient;

  final TextEditingController visitingFeeController = TextEditingController();
  final TextEditingController checkupFeeController = TextEditingController();
  final TextEditingController taxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPatientsForBill();
  }

  Future<void> loadPatientsForBill() async {
    setState(() => isLoading = true);
    try {
      final api = ApiService();
      final data = await api.getPatientsForBill(widget.token);
      if (!mounted) return;

      setState(() {
        patients = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load patients: $e')));
    }
  }
void generateBill() async {
  if (selectedPatient == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Select a patient first')),
    );
    return;
  }

  final visitingFee = double.tryParse(visitingFeeController.text) ?? 0.0;
  final checkupFee = double.tryParse(checkupFeeController.text) ?? 0.0;
  final tax = double.tryParse(taxController.text) ?? 0.0;
  final total = visitingFee + checkupFee + tax;

  final billData = {
    "appointment_id": selectedPatient!['id'],  // appointment ID
    "visiting_fee": visitingFee,
    "checkup_fee": checkupFee,
    "tax_percent": tax,
  };

  try {
    final api = ApiService();
    await api.createOPDBill(widget.token, billData);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bill saved for ${selectedPatient!['patient_name']} | Total: ₹${total.toStringAsFixed(2)}',
        ),
      ),
    );

    // Clear fields after saving
    visitingFeeController.clear();
    checkupFeeController.clear();
    taxController.clear();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save bill: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate OPD Bill'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : patients.isEmpty
              ? const Center(child: Text('No patients available for billing'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPatientDropdown(),
                      const SizedBox(height: 20),
                      if (selectedPatient != null) ...[
                        _buildPatientDetailsCard(selectedPatient!),
                        const SizedBox(height: 20),
                        _buildFeeInputFields(),
                        const SizedBox(height: 20),
                        _buildGenerateBillButton(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildPatientDropdown() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButton<Map<String, dynamic>>(
          isExpanded: true,
          value: selectedPatient,
          hint: const Text('Select a patient', style: TextStyle(color: Colors.grey)),
          underline: const SizedBox(),
          items: patients.map((patient) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: patient,
              child: Text(
                patient['patient_name'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedPatient = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPatientDetailsCard(Map<String, dynamic> patient) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            _buildDetailRow(
                Icons.person_outline, 'Name', patient['patient_name']),
            _buildDetailRow(
                Icons.cake_outlined, 'Age', patient['patient_age']),
            _buildDetailRow(Icons.phone_outlined, 'Contact',
                patient['patient_contact']),
            _buildDetailRow(
                Icons.email_outlined, 'Email', patient['patient_email']),
            _buildDetailRow(
                Icons.transgender, 'Gender', patient['gender']),
            _buildDetailRow(
                Icons.medical_services_outlined, 'Symptoms', patient['symptoms']),
            _buildDetailRow(
                Icons.description_outlined, 'Prescription', patient['prescription_details']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(value?.toString() ?? '-')),
        ],
      ),
    );
  }

  Widget _buildFeeInputFields() {
    return Column(
      children: [
        _buildCustomTextFormField(
          controller: visitingFeeController,
          label: 'Visiting Fee',
          icon: Icons.attach_money,
        ),
        const SizedBox(height: 15),
        _buildCustomTextFormField(
          controller: checkupFeeController,
          label: 'Checkup Fee',
          icon: Icons.receipt_long,
        ),
        const SizedBox(height: 15),
        _buildCustomTextFormField(
          controller: taxController,
          label: 'Tax / Additional Charges',
          icon: Icons.payments,
        ),
      ],
    );
  }

  Widget _buildCustomTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildGenerateBillButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: generateBill,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          elevation: 5,
        ),
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text(
          'Generate Bill',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}