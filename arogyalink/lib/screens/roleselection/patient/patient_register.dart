// ignore_for_file: deprecated_member_use, prefer_const_constructors, use_build_context_synchronously, library_private_types_in_public_api

import 'package:arogyalink/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:arogyalink/screens/roleselection/patient/patient_login.dart';
import 'package:arogyalink/screens/roleselection/role_selection_screen.dart';

class PatientRegister extends StatefulWidget {
  const PatientRegister({super.key});

  @override
  State<PatientRegister> createState() => _PatientRegisterState();
}

class _PatientRegisterState extends State<PatientRegister> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  // New controller for Age
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyNumberController =
      TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _illnessesController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _surgeriesController = TextEditingController();
  final TextEditingController _vaccinationController = TextEditingController();

  // New controllers for State and Country
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _dobFocusNode = FocusNode();
  // New focus node for Age
  final FocusNode _ageFocusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _emergencyNameFocusNode = FocusNode();
  final FocusNode _emergencyNumberFocusNode = FocusNode();
  final FocusNode _bloodGroupFocusNode = FocusNode();
  final FocusNode _allergiesFocusNode = FocusNode();
  final FocusNode _illnessesFocusNode = FocusNode();
  final FocusNode _medicationsFocusNode = FocusNode();
  final FocusNode _surgeriesFocusNode = FocusNode();
  final FocusNode _vaccinationFocusNode = FocusNode();

  // New focus nodes for State and Country
  final FocusNode _stateFocusNode = FocusNode();
  final FocusNode _countryFocusNode = FocusNode();

  String? _selectedGender;
  String? _selectedState;
  String? _selectedCountry;

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Lists for dropdown menus
  final List<String> _indianStates = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana",
    "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal",
    "Andaman and Nicobar Islands", "Chandigarh", "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi", "Jammu and Kashmir", "Ladakh", "Lakshadweep", "Puducherry"
  ];

  final List<String> _countries = [
    "India", "United States", "United Kingdom", "Canada", "Australia",
    "Germany", "France", "Japan"
  ];

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(_onFocusChange);
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
    _dobFocusNode.addListener(_onFocusChange);
    _ageFocusNode.addListener(_onFocusChange); // Added Age Focus Node
    _mobileFocusNode.addListener(_onFocusChange);
    _addressFocusNode.addListener(_onFocusChange);
    _stateFocusNode.addListener(_onFocusChange);
    _countryFocusNode.addListener(_onFocusChange);
    _emergencyNameFocusNode.addListener(_onFocusChange);
    _emergencyNumberFocusNode.addListener(_onFocusChange);
    _bloodGroupFocusNode.addListener(_onFocusChange);
    _allergiesFocusNode.addListener(_onFocusChange);
    _illnessesFocusNode.addListener(_onFocusChange);
    _medicationsFocusNode.addListener(_onFocusChange);
    _surgeriesFocusNode.addListener(_onFocusChange);
    _vaccinationFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _ageController.dispose(); // Disposed Age Controller
    _mobileController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _emergencyNameController.dispose();
    _emergencyNumberController.dispose();
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _illnessesController.dispose();
    _medicationsController.dispose();
    _surgeriesController.dispose();
    _vaccinationController.dispose();

    _nameFocusNode.removeListener(_onFocusChange);
    _emailFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);
    _dobFocusNode.removeListener(_onFocusChange);
    _ageFocusNode.removeListener(_onFocusChange); // Removed Age Focus Node Listener
    _mobileFocusNode.removeListener(_onFocusChange);
    _addressFocusNode.removeListener(_onFocusChange);
    _stateFocusNode.removeListener(_onFocusChange);
    _countryFocusNode.removeListener(_onFocusChange);
    _emergencyNameFocusNode.removeListener(_onFocusChange);
    _emergencyNumberFocusNode.removeListener(_onFocusChange);
    _bloodGroupFocusNode.removeListener(_onFocusChange);
    _allergiesFocusNode.removeListener(_onFocusChange);
    _illnessesFocusNode.removeListener(_onFocusChange);
    _medicationsFocusNode.removeListener(_onFocusChange);
    _surgeriesFocusNode.removeListener(_onFocusChange);
    _vaccinationFocusNode.removeListener(_onFocusChange);

    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _dobFocusNode.dispose();
    _ageFocusNode.dispose(); // Disposed Age Focus Node
    _mobileFocusNode.dispose();
    _addressFocusNode.dispose();
    _stateFocusNode.dispose();
    _countryFocusNode.dispose();
    _emergencyNameFocusNode.dispose();
    _emergencyNumberFocusNode.dispose();
    _bloodGroupFocusNode.dispose();
    _allergiesFocusNode.dispose();
    _illnessesFocusNode.dispose();
    _medicationsFocusNode.dispose();
    _surgeriesFocusNode.dispose();
    _vaccinationFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String username = _nameController.text;
      final String email = _emailController.text;
      final String password = _passwordController.text;
      final String? gender = _selectedGender;
      final String dob = _dobController.text;
      final String age = _ageController.text; // Get age
      final String mobileNumber = _mobileController.text;
      final String residentialAddress = _addressController.text;
      // State and Country from the dropdowns/controllers
      final String? state = _selectedState;
      final String? country = _selectedCountry;

      final String emergencyContactName = _emergencyNameController.text;
      final String emergencyContactNumber = _emergencyNumberController.text;
      final String bloodGroup = _bloodGroupController.text;
      final String knownAllergies = _allergiesController.text;
      final String chronicIllnesses = _illnessesController.text;
      final String currentMedications = _medicationsController.text;
      final String pastSurgeries = _surgeriesController.text;
      final String vaccinationDetails = _vaccinationController.text;

      try {
        final apiService = ApiService();
        final result = await apiService.registerPatient(
          username: username,
          email: email,
          password: password,
          dateOfBirth: dob,
          age: age, // Passed age to API
          gender: gender,
          mobileNumber: mobileNumber,
          residentialAddress: residentialAddress,
          state: state, // Passed state to API
          country: country, // Passed country to API
          emergencyContactName: emergencyContactName,
          emergencyContactNumber: emergencyContactNumber,
          bloodGroup: bloodGroup,
          knownAllergies: knownAllergies,
          chronicIllnesses: chronicIllnesses,
          currentMedications: currentMedications,
          pastSurgeries: pastSurgeries,
          vaccinationDetails: vaccinationDetails,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (result['success']) {
            _showSnackBar("Registration successful! Please log in.", Colors.green);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PatientLogin()),
            );
          } else {
            _showErrorDialog(result['message'] ?? "Registration failed.");
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorDialog("An error occurred: $e");
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error!"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Try again"),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Function to calculate age from DOB and set it in _ageController
  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        // Calculate age and update the age controller
        final int age = _calculateAge(picked);
        _ageController.text = age.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFD7FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 100.0, left: 24.0, right: 24.0, bottom: 40.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildRegisterCard(context),
              _buildHeaderImage(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildBackButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
    );
  }

  Widget _buildRegisterCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24.0, 90.0, 24.0, 40.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFADD),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              children: [
                TextSpan(text: "Hey! Welcome To "),
                TextSpan(
                  text: "Arogya",
                  style: TextStyle(color: Color(0xFF0A8F13)),
                ),
                TextSpan(
                  text: "Link",
                  style: TextStyle(color: Color(0xFF656565)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildRegisterForm(),
          const SizedBox(height: 14),
          _buildLoginText(),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildNameField(),
          const SizedBox(height: 16),
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 16),
          _buildDobField(),
          const SizedBox(height: 16),
          _buildAgeField(), // Added Age Field
          const SizedBox(height: 16),
          _buildGenderDropdown(),
          const SizedBox(height: 16),
          _buildMobileField(),
          const SizedBox(height: 16),
          _buildAddressField(),
          const SizedBox(height: 16),
          _buildStateDropdown(),
          const SizedBox(height: 16),
          _buildCountryDropdown(),
          const SizedBox(height: 16),
          _buildEmergencyContactNameField(),
          const SizedBox(height: 16),
          _buildEmergencyContactNumberField(),
          const SizedBox(height: 16),
          _buildBloodGroupField(),
          const SizedBox(height: 16),
          _buildAllergiesField(),
          const SizedBox(height: 16),
          _buildIllnessesField(),
          const SizedBox(height: 16),
          _buildMedicationsField(),
          const SizedBox(height: 16),
          _buildSurgeriesField(),
          const SizedBox(height: 16),
          _buildVaccinationField(),
          const SizedBox(height: 20),
          _buildRegisterButton(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: "Full Name",
        hintText: "Enter your full name",
        prefixIcon: const Icon(Icons.person_outline, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your full name';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: "Email",
        hintText: "Enter your email",
        prefixIcon: const Icon(Icons.email_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: "Password",
        hintText: "Create your password",
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.blueAccent),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
  }

  Widget _buildDobField() {
    return TextFormField(
      controller: _dobController,
      focusNode: _dobFocusNode,
      readOnly: true,
      onTap: () => _selectDate(context),
      decoration: InputDecoration(
        labelText: "Date of Birth",
        hintText: "Select your date of birth",
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your date of birth';
        }
        return null;
      },
    );
  }

  // New Widget for Age Field
  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      focusNode: _ageFocusNode,
      readOnly: true, // Making it read-only as it's calculated from DOB
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: "Age",
        hintText: "Your age (calculated from DOB)",
        prefixIcon: const Icon(Icons.cake_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (_dobController.text.isEmpty) {
          // Validation is primarily on DOB, but keeping a check for consistency
          return 'Age will be calculated upon selecting DOB';
        }
        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Gender",
        prefixIcon: const Icon(Icons.person_2_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedGender,
      items: ['Male', 'Female', 'Other']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedGender = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your gender';
        }
        return null;
      },
    );
  }

  Widget _buildMobileField() {
    return TextFormField(
      controller: _mobileController,
      focusNode: _mobileFocusNode,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: "Mobile Number",
        hintText: "Enter your mobile number",
        prefixIcon: const Icon(Icons.phone, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your mobile number';
        }
        if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
          return 'Please enter a valid 10-digit number';
        }
        return null;
      },
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      focusNode: _addressFocusNode,
      keyboardType: TextInputType.multiline,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: "Residential Address",
        hintText: "Enter your full address",
        prefixIcon: const Icon(Icons.home_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your address';
        }
        return null;
      },
    );
  }

  Widget _buildStateDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "State",
        prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedState,
      items: _indianStates.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedState = newValue;
          _stateController.text = newValue ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your state';
        }
        return null;
      },
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Country",
        prefixIcon: const Icon(Icons.flag_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _selectedCountry,
      items: _countries.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCountry = newValue;
          _countryController.text = newValue ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your country';
        }
        return null;
      },
    );
  }

  Widget _buildEmergencyContactNameField() {
    return TextFormField(
      controller: _emergencyNameController,
      focusNode: _emergencyNameFocusNode,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: "Emergency Contact Name",
        hintText: "Enter emergency contact name",
        prefixIcon: const Icon(Icons.person_search_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an emergency contact name';
        }
        if (RegExp(r'\d').hasMatch(value)) {
          return 'Name cannot contain numbers';
        }
        return null;
      },
    );
  }

  Widget _buildEmergencyContactNumberField() {
    return TextFormField(
      controller: _emergencyNumberController,
      focusNode: _emergencyNumberFocusNode,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: "Emergency Contact Number",
        hintText: "Enter emergency contact number",
        prefixIcon: const Icon(Icons.phone_in_talk_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an emergency contact number';
        }
        if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
          return 'Please enter a valid 10-digit number';
        }
        return null;
      },
    );
  }

  Widget _buildBloodGroupField() {
    return TextFormField(
      controller: _bloodGroupController,
      focusNode: _bloodGroupFocusNode,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: "Blood Group",
        hintText: "e.g., A+",
        prefixIcon: const Icon(Icons.bloodtype_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your blood group';
        }
        return null;
      },
    );
  }

  Widget _buildAllergiesField() {
    return TextFormField(
      controller: _allergiesController,
      focusNode: _allergiesFocusNode,
      keyboardType: TextInputType.multiline,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: "Known Allergies",
        hintText: "e.g., Penicillin, Peanuts",
        prefixIcon: const Icon(Icons.warning_amber_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildIllnessesField() {
    return TextFormField(
      controller: _illnessesController,
      focusNode: _illnessesFocusNode,
      keyboardType: TextInputType.multiline,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: "Chronic Illnesses",
        hintText: "e.g., Diabetes, Hypertension",
        prefixIcon: const Icon(Icons.local_hospital_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMedicationsField() {
    return TextFormField(
      controller: _medicationsController,
      focusNode: _medicationsFocusNode,
      keyboardType: TextInputType.multiline,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: "Current Medications",
        hintText: "e.g., Metformin (500mg daily)",
        prefixIcon: const Icon(Icons.medication_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSurgeriesField() {
    return TextFormField(
      controller: _surgeriesController,
      focusNode: _surgeriesFocusNode,
      keyboardType: TextInputType.multiline,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: "Past Surgeries",
        hintText: "e.g., Appendectomy (2018)",
        prefixIcon: const Icon(Icons.healing_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildVaccinationField() {
    return TextFormField(
      controller: _vaccinationController,
      focusNode: _vaccinationFocusNode,
      keyboardType: TextInputType.multiline,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: "Vaccination Details",
        hintText: "e.g., COVID-19 (Pfizer, 2 doses)",
        prefixIcon: const Icon(Icons.vaccines_outlined, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              "Register",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildLoginText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Already have an account?",
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PatientLogin()),
            );
          },
          child: Text(
            "Login here",
            style: TextStyle(
              color: Colors.blueAccent.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderImage() {
    return Positioned(
      top: -100,
      left: 25,
      child: Image.asset(
        'assets/images/patient_top_image.png',
        width: 150,
        height: 150,
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black87),
      onPressed: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      ),
    );
  }
}