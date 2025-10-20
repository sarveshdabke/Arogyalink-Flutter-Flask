import 'package:arogyalink/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Make sure you have the intl package in pubspec.yaml

class HospitalizationScreen extends StatefulWidget {
  final Map<String, dynamic> appt;
  const HospitalizationScreen({super.key, required this.appt});

  @override
  State<HospitalizationScreen> createState() => _HospitalizationScreenState();
}

class _HospitalizationScreenState extends State<HospitalizationScreen> {
  List<Map<String, dynamic>> hospitals = [];
  Map<String, dynamic>? selectedHospital;
  Map<String, dynamic>? patientProfile;
  String referringDoctorName = 'Loading...'; // For displaying doctor name

  bool isLoading = true; // For hospitals
  bool isProfileLoading = true; // For patient profile
  bool isDoctorLoading = true; // For doctor name

  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Global Keys for Form Validation per step
  final _patientFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  final _specialInstructionsFormKey = GlobalKey<FormState>();

  // --- Admission Details ---
  DateTime? _admissionDate;
  final TextEditingController _admissionDateController = TextEditingController(); 
  // Reason controller is removed as the field is removed from UI

  // --- Insurance / Payment ---
  final TextEditingController _insuranceProviderController =
      TextEditingController();
  final TextEditingController _policyNumberController = TextEditingController();
  String _paymentMode = 'Cash';

  // --- Special Instructions / Allergies / Past surgeries / Medications ---
  final TextEditingController _specialInstructionsController =
      TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _pastSurgeriesController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _insuranceProviderController.dispose();
    _policyNumberController.dispose();
    _specialInstructionsController.dispose();
    _allergiesController.dispose();
    _pastSurgeriesController.dispose();
    _medicationsController.dispose();
    _admissionDateController.dispose(); 
    super.dispose();
  }

  Future<void> _loadAllData() async {
    // Run all data fetching concurrently
    await Future.wait([
      _loadHospitals(),
      _loadPatientProfile(),
      _loadReferringDoctorName(),
    ]);

    setState(() {
      isLoading = false;
      isProfileLoading = false;
      isDoctorLoading = false;
    });

    // Pre-fill fields from fetched patient profile medical history
    if (patientProfile != null) {
      _allergiesController.text = patientProfile!['known_allergies'] ?? '';
      _pastSurgeriesController.text = patientProfile!['past_surgeries'] ?? '';
      _medicationsController.text = patientProfile!['current_medications'] ?? '';
    }
  }

  Future<void> _loadHospitals() async {
    setState(() => isLoading = true);
    var response = await ApiService().fetchAllHospitals();
    if (response['success'] == true) {
      hospitals = List<Map<String, dynamic>>.from(response['data']);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response['message'] ?? 'Failed to fetch hospitals')),
        );
      }
    }
  }
  
  // FIX for Doctor Name: Extracting name from appt data
  Future<void> _loadReferringDoctorName() async {
    setState(() => isDoctorLoading = true);
    // Assuming 'doctor_name' is the key holding the doctor's name who made the referral
    final name = widget.appt['doctor_name'] ?? 'Doctor Name Not Available (Key Missing)'; 
    setState(() {
      referringDoctorName = name;
    });
  }

  Future<void> _loadPatientProfile() async {
    setState(() => isProfileLoading = true);
    var response = await ApiService().getProfile();
    if (response['success'] == true) {
      patientProfile = response['data']; 
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(response['message'] ?? 'Failed to fetch patient profile')),
        );
      }
    }
  }

  Future<void> _selectAdmissionDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _admissionDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _admissionDate = picked;
        _admissionDateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  void _nextStep() {
    bool isValid = false;
    GlobalKey<FormState> currentKey;

    if (_currentStep == 0) {
      currentKey = _patientFormKey;
    } else if (_currentStep == 1) {
      currentKey = _paymentFormKey;
    } else {
      currentKey = _specialInstructionsFormKey;
    }

    if (currentKey.currentState!.validate()) {
      isValid = true;

      // Additional validation specific to Step 1 (Patient Details)
      if (_currentStep == 0) {
        if (selectedHospital == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a hospital')));
          isValid = false;
        } else if (_admissionDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select an Admission Date')));
          isValid = false;
        }
      }
    }

    if (isValid) {
      if (_currentStep < 2) {
        _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
        setState(() => _currentStep++);
      } else {
        _submitForm();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  void _submitForm() async {
    if (_specialInstructionsFormKey.currentState!.validate() == false ||
        patientProfile == null) {
      return;
    }
    if (selectedHospital == null || _admissionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing required admission details')));
      return;
    }

    // 1. Get Referring Doctor ID from OPD Appointment data (Crucial step)
    final referringDoctorId = widget.appt['doctor_id']; 

    if (referringDoctorId == null) {
      // Safety check: Should not happen if the patient was referred.
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Referring Doctor ID is missing from OPD appointment data.')),
      );
      return;
    }
    
    // Use referral_reason from widget.appt as the admission reason
    final admissionReason = widget.appt['referral_reason'] ?? 'Referred for Hospitalization';

    final hospitalizationData = {
      'hospital_id': selectedHospital!['id'],
      'opd_appointment_id': widget.appt['id'], 

      // ✅ NEW: Add the referring doctor ID to the data sent to the API
      'referring_doctor_id': referringDoctorId, // <<< CHANGED HERE

      // --- Using Patient Profile Data ---
      'patient_name': patientProfile!['username'],
      'age': patientProfile!['age']?.toString(),
      'gender': patientProfile!['gender'],
      'contact': patientProfile!['mobile_number'],
      'email': patientProfile!['email'],

      'admission_date': _admissionDate?.toIso8601String(),
      'reason': admissionReason, // Using referral reason
      'insurance_provider': _insuranceProviderController.text.trim(),
      'policy_number': _policyNumberController.text.trim(),
      'payment_mode': _paymentMode,

      // --- Using Patient Profile Emergency Contact Data ---
      'emergency_name': patientProfile!['emergency_contact_name'],
      'emergency_relation': 'Guardian/Next of Kin', 
      'emergency_contact': patientProfile!['emergency_contact_number'],

      // --- Optional/Pre-filled data ---
      'special_instructions': _specialInstructionsController.text.trim(),
      'allergies': _allergiesController.text.trim(),
      'past_surgeries': _pastSurgeriesController.text.trim(),
      'medications': _medicationsController.text.trim(),
    };

    // Call API
    final response = await ApiService().createHospitalization(
      patientId: widget.appt['patient_id'], 
      admissionData: hospitalizationData,
    );

    if (response['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ ${response['message']}")),
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${response['message']}")),
      );
    }
}
  Widget _buildPatientProfileCard() {
    if (isProfileLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(8.0),
        child: LinearProgressIndicator(),
      ));
    }

    if (patientProfile == null) {
      return const Card(
        color: Colors.redAccent,
        margin: EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          title: Text("Profile Load Error", style: TextStyle(color: Colors.white)),
          subtitle: Text("Failed to load patient profile data.", style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.lightBlue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("👤 Patient Profile (Auto-filled)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Divider(),
            _buildProfileRow("Name", patientProfile!['username'] ?? 'N/A'),
            _buildProfileRow("Age/Gender", 
                "${patientProfile!['age'] ?? 'N/A'} / ${patientProfile!['gender'] ?? 'N/A'}"),
            _buildProfileRow("Contact", patientProfile!['mobile_number'] ?? 'N/A'),
            _buildProfileRow("Email", patientProfile!['email'] ?? 'N/A'),
            _buildProfileRow("Address", patientProfile!['residential_address'] ?? 'N/A'),
            const Divider(height: 15),
            const Text("🚨 Emergency Contact",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
            _buildProfileRow("Name", patientProfile!['emergency_contact_name'] ?? 'N/A'),
            _buildProfileRow("Contact", patientProfile!['emergency_contact_number'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPatientStep() {
    final referralReason = widget.appt['referral_reason'] ?? 'N/A';
    final symptoms = widget.appt['symptoms'] ?? 'N/A';
    final prescription = widget.appt['prescription_details'] ?? 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _patientFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Referral Details
            const Text("👨‍⚕️ Doctor Referral Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: isDoctorLoading
                    ? const Text("Referring Doctor: Loading...", style: TextStyle(fontWeight: FontWeight.bold))
                    : Text("Referring Doctor: $referringDoctorName", 
                           style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Referral Reason: $referralReason"),
                    Text("Symptoms: $symptoms"),
                    Text("Prescription: $prescription"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // Patient Profile Card
            _buildPatientProfileCard(),

              // Hospital Selection
            const Text("🏥 Select Hospital",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<Map<String, dynamic>>(
              isExpanded: true,
              hint: const Text("Select a hospital *"),
              initialValue: selectedHospital,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), contentPadding: EdgeInsets.all(12)),
              validator: (value) => value == null ? 'Please select a hospital' : null,

              // FIX: Use selectedItemBuilder to control how the selected value is displayed.
              selectedItemBuilder: (context) {
                return hospitals.map((hospital) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      // Only display the Hospital Name to prevent overflow in the main field
                      hospital['hospital_name'] ?? 'Unknown Hospital',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
              
              items: hospitals.map((hospital) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: hospital,
                  child: Align(
                    alignment: Alignment.centerLeft, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center, 
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        Text(
                          hospital['hospital_name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Address is limited to one line in the dropdown list
                        Text(
                          hospital['address'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1, // Changed from 2 back to 1 for better list view fit
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (hospital) {
                setState(() {
                  selectedHospital = hospital;
                });
              },
            ),
            if (selectedHospital != null) ...[
              const SizedBox(height: 10),
              // Hospital details card for verification
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: ${selectedHospital!['hospital_name']}"),
                      Text("Address: ${selectedHospital!['address'] ?? 'N/A'}"),
                      Text("Available Beds: ${selectedHospital!['available_beds'] ?? 0}"),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Admission Details
            const Text("📅 Admission Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            
            // FIX: Admission Date UI
            TextFormField(
              controller: _admissionDateController,
              decoration: InputDecoration(
                labelText: "Admission Date *",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectAdmissionDate(context),
                ),
              ),
              readOnly: true, 
              onTap: () => _selectAdmissionDate(context), 
              validator: (value) => value!.isEmpty ? 'Admission date is required' : null,
            ),

            // Removed: Reason / Symptoms field

            const SizedBox(height: 20),

            // Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                    onPressed: _nextStep, child: const Text("Next (Payment)")),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _paymentFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Insurance / Payment
            const Text("💳 Insurance / Payment (Optional)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextFormField(
                controller: _insuranceProviderController,
                decoration: const InputDecoration(labelText: "Insurance Provider")),
            TextFormField(
                controller: _policyNumberController,
                decoration: const InputDecoration(labelText: "Policy Number")),
            DropdownButtonFormField<String>(
              initialValue: _paymentMode,
              decoration: const InputDecoration(labelText: "Payment Mode *"),
              items: ['Cash', 'Card', 'Online', 'Insurance']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) => setState(() => _paymentMode = val ?? 'Cash'),
              validator: (value) =>
                  value == null ? 'Payment mode is required' : null,
            ),
            const SizedBox(height: 20),

            // Emergency Contact (Read-only from Profile)
            const Text("📞 Emergency Contact (From Profile)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.yellow.shade100,
              child: ListTile(
                title: Text("Name: ${patientProfile?['emergency_contact_name'] ?? 'N/A'}"),
                subtitle: Text("Contact: ${patientProfile?['emergency_contact_number'] ?? 'N/A'}"),
              ),
            ),
            
            const SizedBox(height: 20),

            // Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(onPressed: _previousStep, child: const Text("Back")),
                ElevatedButton(onPressed: _nextStep, child: const Text("Next (Instructions)")),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _specialInstructionsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "📝 Special Instructions / History (Optional)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextFormField(
                controller: _specialInstructionsController,
                decoration: const InputDecoration(labelText: "Special Instructions")),
            // Pre-filled fields
            TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(labelText: "Allergies (Pre-filled from profile)")),
            TextFormField(
                controller: _pastSurgeriesController,
                decoration: const InputDecoration(labelText: "Past Surgeries (Pre-filled from profile)")),
            TextFormField(
                controller: _medicationsController,
                decoration: const InputDecoration(labelText: "Current Medications (Pre-filled from profile)")),
            const SizedBox(height: 20),

            // Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(onPressed: _previousStep, child: const Text("Back")),
                ElevatedButton(
                    onPressed: _nextStep,
                    child: const Text("Book Hospitalization")),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a single CircularProgressIndicator while all data is loading
    final isAnyLoading = isLoading || isProfileLoading || isDoctorLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text("Book Hospitalization (Step ${_currentStep + 1} of 3)"),
      ),
      body: isAnyLoading
          ? const Center(child: CircularProgressIndicator())
          : PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPatientStep(),
                _buildPaymentStep(),
                _buildSpecialStep(),
              ],
            ),
    );
  }
}