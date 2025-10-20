// ignore_for_file: prefer_final_fields, use_build_context_synchronously, prefer_const_constructors, deprecated_member_use, library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:arogyalink/services/api_service.dart';

class BookOPDScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;

  const BookOPDScreen({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
  });

  @override
  State<BookOPDScreen> createState() => _BookOPDScreenState();
}

class _BookOPDScreenState extends State<BookOPDScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  TextEditingController _patientNameController = TextEditingController();
  TextEditingController _patientAgeController = TextEditingController();
  TextEditingController _patientContactController = TextEditingController();
  TextEditingController _appointmentDateController = TextEditingController();
  TextEditingController _symptomsController = TextEditingController();
  TextEditingController _patientEmailController = TextEditingController();

  Map<String, dynamic>? _hospitalProfile;
  Map<String, dynamic>? _patientProfile;
  List<Map<String, dynamic>> _doctorsList = [];

  String? _selectedDoctor;
  String? _selectedGender;
  bool _isEmergency = false;
  bool _isLoading = true;
  bool _isFetchingSlots = false;

  String? _selectedAppointmentTime;
  List<String> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = ApiService();

      // Fetch hospital profile
      final hospitalResponse =
          await apiService.getHospitalProfile(widget.hospitalId);
      if (hospitalResponse['success']) {
        _hospitalProfile = hospitalResponse['data'];
      }

      // Fetch doctors
      final doctorsResponse =
          await apiService.getDoctorsByHospitalId(widget.hospitalId);
      if (doctorsResponse['success']) {
        _doctorsList = List<Map<String, dynamic>>.from(doctorsResponse['data']);
      }

      // Fetch patient profile
      final patientResponse = await apiService.getProfile();
      if (patientResponse['success']) {
        _patientProfile = patientResponse['data'];

        _patientNameController.text = _patientProfile?['username'] ?? '';
        _patientEmailController.text = _patientProfile?['email'] ?? '';
        _patientContactController.text = _patientProfile?['mobile_number'] ?? '';
        _selectedGender = _patientProfile?['gender'];
        
        // Use 'age' field if available, otherwise calculate from DOB
        if (_patientProfile?['age'] != null) {
          _patientAgeController.text = _patientProfile!['age'].toString();
        } else if (_patientProfile?['date_of_birth'] != null &&
            _patientProfile?['date_of_birth'] != '') {
          _patientAgeController.text = _calculateAgeFromDOB(
                  _patientProfile!['date_of_birth'].toString())
              .toString();
        }
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _calculateAgeFromDOB(String dob) {
    try {
      final birthDate = DateFormat('yyyy-MM-dd').parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _fetchAvailableSlots(String date) async {
    if (date.isEmpty || _selectedDoctor == null) return;

    setState(() {
      _isFetchingSlots = true;
      _availableSlots = [];
      _selectedAppointmentTime = null;
    });

    final apiService = ApiService();
    try {
      final response = await apiService.getOpdSlots(
        hospitalId: widget.hospitalId,
        doctorId: _selectedDoctor!,
        appointmentDate: date,
      );
      if (response['success']) {
        _availableSlots = (response['data'] as List)
            .map((slot) => "${slot['start_time']} - ${slot['end_time']}")
            .toList();
      } else {
        _availableSlots = [];
      }
    } catch (e) {
      print("Error fetching available slots: $e");
      _availableSlots = [];
    } finally {
      setState(() {
        _isFetchingSlots = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      _appointmentDateController.text =
          DateFormat('yyyy-MM-dd').format(picked);
      await _fetchAvailableSlots(_appointmentDateController.text);
    }
  }

  Future<void> _bookAppointment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final apiService = ApiService();
        final timeParts = _selectedAppointmentTime!.split(' - ');
        final startTime = timeParts[0];
        final endTime = timeParts[1];

        final response = await apiService.bookOpdAppointment(
          hospitalId: widget.hospitalId,
          patientName: _patientNameController.text,
          patientAge: int.parse(_patientAgeController.text),
          patientContact: _patientContactController.text,
          patientEmail: _patientEmailController.text,
          patientGender: _selectedGender!,
          appointmentDate: _appointmentDateController.text,
          startTime: startTime,
          endTime: endTime,
          doctorId: _selectedDoctor!,
          symptoms: _symptomsController.text,
          isEmergency: _isEmergency,
        );

        setState(() => _isLoading = false);

        if (response['success']) {
          final tokenNumber = response['token_number'];
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "${response['message'] ?? 'Appointment Booked!'}\nToken Number: $tokenNumber"),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(response['message'] ?? 'Failed to book appointment'),
            backgroundColor: Colors.red,
          ));
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book OPD Appointment', style: GoogleFonts.poppins()),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Patient Details Card (Tabbed View)
                    if (_patientProfile != null)
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(15)),
                                ),
                                child: const TabBar(
                                  labelColor: Colors.blueAccent,
                                  unselectedLabelColor: Colors.black54,
                                  indicatorColor: Colors.blueAccent,
                                  tabs: [
                                    Tab(
                                        icon: Icon(Icons.person),
                                        text: 'Personal Info'),
                                    Tab(
                                        icon: Icon(Icons.health_and_safety),
                                        text: 'Health Info'),
                                  ],
                                ),
                              ),
                              Container(
                                height: 250,
                                padding: const EdgeInsets.all(16),
                                child: TabBarView(
                                  children: [
                                    // 🧍 Personal Info
                                    SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildDetailRow(
                                              Icons.person,
                                              'Name',
                                              _patientProfile?['username'] ??
                                                  'N/A'),
                                          _buildDetailRow(
                                              Icons.email,
                                              'Email',
                                              _patientProfile?['email'] ??
                                                  'N/A'),
                                          _buildDetailRow(
                                              Icons.phone,
                                              'Mobile',
                                              _patientProfile?['mobile_number'] ??
                                                  'N/A'),
                                          _buildDetailRow(Icons.wc, 'Gender',
                                              _patientProfile?['gender'] ?? 'N/A'),
                                          
                                          // 🎂 UPDATED AGE DETAIL ROW
                                          _buildDetailRow(
                                              Icons.cake, 
                                              'Age', 
                                              _patientProfile?['age']?.toString() ?? 'N/A' // Directly use 'age' from profile
                                          ),
                                          
                                          _buildDetailRow(
                                              Icons.home,
                                              'Address',
                                              _patientProfile?['residential_address'] ??
                                                  'N/A'),
                                        ],
                                      ),
                                    ),

                                    // 🩺 Health Info
                                    SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildDetailRow(
                                              Icons.bloodtype,
                                              'Blood Group',
                                              _patientProfile?['blood_group'] ??
                                                  'N/A'),
                                          _buildDetailRow(
                                              Icons.local_hospital,
                                              'Allergies',
                                              _patientProfile?['known_allergies'] ??
                                                  'N/A'),
                                          _buildDetailRow(
                                              Icons.healing,
                                              'Chronic Diseases',
                                              _patientProfile?['chronic_illnesses'] ??
                                                  'N/A'),
                                          _buildDetailRow(
                                              Icons.medication,
                                              'Current Medications',
                                              _patientProfile?['current_medications'] ??
                                                  'N/A'),
                                          _buildDetailRow(
                                              Icons.health_and_safety,
                                              'Past Surgeries',
                                              _patientProfile?['past_surgeries'] ??
                                                  'N/A'),
                                          _buildDetailRow(
                                              Icons.numbers,
                                              'Vaccination Details',
                                              _patientProfile?['vaccination_details'] ??
                                                  'N/A'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // ✅ Hospital Details Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hospital Details',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            if (_hospitalProfile != null) ...[
                              _buildDetailRow(Icons.local_hospital,
                                  'Hospital Name', widget.hospitalName),
                              _buildDetailRow(Icons.info_outline,
                                  'Hospital Type', _hospitalProfile?['hospital_type'] ?? 'N/A'),
                              _buildDetailRow(Icons.phone, 'Contact',
                                  _hospitalProfile?['contact'] ?? 'N/A'),
                              _buildDetailRow(Icons.location_on, 'Address',
                                  _hospitalProfile?['address'] ?? 'N/A'),
                              _buildDetailRow(
                                  Icons.access_time,
                                  'OPD Time',
                                  '${_hospitalProfile?['opd_start_time'] ?? 'N/A'} - ${_hospitalProfile?['opd_end_time'] ?? 'N/A'}'),
                            ] else
                              const Text('Hospital details not available'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Doctor Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedDoctor,
                      decoration: InputDecoration(
                        labelText: 'Select Doctor',
                        prefixIcon: Icon(Icons.person_pin),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _doctorsList.map((doctor) {
                        return DropdownMenuItem<String>(
                          value: doctor['id'].toString(),
                          child: Text(
                              '${doctor['name']} - ${doctor['specialization']}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedDoctor = val);
                        if (_appointmentDateController.text.isNotEmpty) {
                          _fetchAvailableSlots(_appointmentDateController.text);
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Please select a doctor' : null,
                    ),
                    const SizedBox(height: 16),

                    // Appointment Date
                    TextFormField(
                      controller: _appointmentDateController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: InputDecoration(
                        labelText: 'Appointment Date',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty
                              ? 'Select appointment date'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Appointment Time Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedAppointmentTime,
                      decoration: InputDecoration(
                        labelText: 'Appointment Time',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        suffixIcon: _isFetchingSlots
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                      items: _availableSlots.map((slot) {
                        return DropdownMenuItem(
                          value: slot,
                          child: Text(slot),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedAppointmentTime = val),
                      validator: (value) =>
                          value == null ? 'Select appointment time' : null,
                    ),
                    const SizedBox(height: 16),

                    // Symptoms
                    TextFormField(
                      controller: _symptomsController,
                      decoration: InputDecoration(
                        labelText: 'Symptoms',
                        prefixIcon: Icon(Icons.medical_services),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      maxLines: 4,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please describe symptoms'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Checkbox(
                          value: _isEmergency,
                          onChanged: (v) =>
                              setState(() => _isEmergency = v ?? false),
                        ),
                        Text('Mark as Emergency Appointment',
                            style: GoogleFonts.poppins(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _bookAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Book OPD Appointment',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey[600])),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}