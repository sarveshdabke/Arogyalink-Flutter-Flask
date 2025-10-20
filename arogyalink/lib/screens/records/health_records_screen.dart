// lib/screens/patient/health_record_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arogyalink/services/api_service.dart';

class HealthRecordScreen extends StatefulWidget {
  const HealthRecordScreen({super.key});

  @override
  State<HealthRecordScreen> createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen> {
  final ApiService apiService = ApiService();

  final TextEditingController _knownAllergiesController =
      TextEditingController();
  final TextEditingController _chronicIllnessesController =
      TextEditingController();
  final TextEditingController _currentMedicationsController =
      TextEditingController();
  final TextEditingController _pastSurgeriesController =
      TextEditingController();
  final TextEditingController _vaccinationDetailsController =
      TextEditingController();

  bool _loading = true;
  String? _error;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadHealthRecords();
  }

  @override
  void dispose() {
    _knownAllergiesController.dispose();
    _chronicIllnessesController.dispose();
    _currentMedicationsController.dispose();
    _pastSurgeriesController.dispose();
    _vaccinationDetailsController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthRecords() async {
    final response = await apiService.getProfile();
    if (response['success']) {
      final data = response['data'];
      if (mounted) {
        setState(() {
          _knownAllergiesController.text = data['known_allergies'] ?? 'N/A';
          _chronicIllnessesController.text = data['chronic_illnesses'] ?? 'N/A';
          _currentMedicationsController.text =
              data['current_medications'] ?? 'N/A';
          _pastSurgeriesController.text = data['past_surgeries'] ?? 'N/A';
          _vaccinationDetailsController.text =
              data['vaccination_details'] ?? 'N/A';
          _loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _error = response['message'];
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateHealthRecords() async {
    setState(() {
      _loading = true;
    });

    final Map<String, dynamic> updatedData = {
      'known_allergies': _knownAllergiesController.text,
      'chronic_illnesses': _chronicIllnessesController.text,
      'current_medications': _currentMedicationsController.text,
      'past_surgeries': _pastSurgeriesController.text,
      'vaccination_details': _vaccinationDetailsController.text,
    };

    final result = await apiService.updateProfile(updatedData);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health records updated successfully!')),
        );
        setState(() {
          _isEditing = false;
        });
        await _loadHealthRecords(); // Refresh data
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update records: ${result['message']}'),
          ),
        );
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F2F2),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        body: Center(
          child: Text(
            "Error: $_error",
            style: GoogleFonts.poppins(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Health Records' : 'Health Records',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateHealthRecords();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHealthRecordCard(
              'Known Allergies',
              _knownAllergiesController,
              Icons.warning,
              const Color(0xFFFEE2E2), // Lighter red
              const Color(0xFFDC2626), // Darker red
            ),
            _buildHealthRecordCard(
              'Chronic Illnesses',
              _chronicIllnessesController,
              Icons.local_hospital,
              const Color(0xFFDBEAFE), // Lighter blue
              const Color(0xFF2563EB), // Darker blue
            ),
            _buildHealthRecordCard(
              'Current Medications',
              _currentMedicationsController,
              Icons.medication,
              const Color(0xFFD1FAE5), // Lighter green
              const Color(0xFF059669), // Darker green
            ),
            _buildHealthRecordCard(
              'Past Surgeries',
              _pastSurgeriesController,
              Icons.healing,
              const Color(0xFFFEF3C7), // Lighter orange
              const Color(0xFFF59E0B), // Darker orange
            ),
            _buildHealthRecordCard(
              'Vaccination Details',
              _vaccinationDetailsController,
              Icons.vaccines,
              const Color(0xFFEDE9FE), // Lighter purple
              const Color(0xFF7C3AED), // Darker purple
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRecordCard(
    String title,
    TextEditingController controller,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Icon with a colored background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isEditing
                      ? TextFormField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 5, // Allow multiple lines
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            isDense: true,
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            hintText: 'Enter $title',
                          ),
                        )
                      : Text(
                          controller.text,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
