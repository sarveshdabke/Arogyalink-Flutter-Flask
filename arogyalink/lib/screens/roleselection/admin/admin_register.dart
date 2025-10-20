// lib/screens/roleselection/admin/admin_register_page.dart

// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:arogyalink/screens/roleselection/admin/admin_login.dart';

class AdminRegisterPage extends StatefulWidget {
  const AdminRegisterPage({super.key});

  @override
  State<AdminRegisterPage> createState() => _AdminRegisterPageState();
}

class _AdminRegisterPageState extends State<AdminRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Basic Info Controllers
  final _hospitalNameController = TextEditingController();
  String _hospitalType = 'Private';
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _alternateContactController = TextEditingController();
  final _upiIdController = TextEditingController();
  // Address
  final _addressSearchController = TextEditingController();
  final _fullAddressController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _landmarkController = TextEditingController();
  double? _latitude;
  double? _longitude;

  // Address Autocomplete variables
  Timer? _debounce;
  List<Map<String, dynamic>> _addressSuggestions = [];
  bool _isSearchingAddress = false;

  // Facility
  bool _emergencyAvailable = false;
  final _departmentsController = TextEditingController();
  bool _opdAvailable = false;
  final _opdStartController = TextEditingController();
  final _opdEndController = TextEditingController();
  
  // ✅ NEW FIELD: Admission Fees Controller
  final _admissionFeesController = TextEditingController();

  // Documents & Media
  final _licenseNumberController = TextEditingController();
  XFile? _registrationCertificate;
  XFile? _adminIdProof;
  XFile? _hospitalLogo;

  // Auth
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addressSearchController.addListener(_onAddressSearchChanged);
  }

  void _onAddressSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_addressSearchController.text.length > 2) {
        _searchAddress(_addressSearchController.text);
      } else {
        if (mounted) {
          setState(() {
            _addressSuggestions = [];
          });
        }
      }
    });
  }

  Future<void> _searchAddress(String query) async {
    if (!mounted) return;
    setState(() {
      _isSearchingAddress = true;
      _addressSuggestions = [];
    });

    try {
      final suggestions = await _apiService.searchAddress(query);
      if (mounted) {
        setState(() {
          _addressSuggestions = List<Map<String, dynamic>>.from(suggestions);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching address: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingAddress = false;
        });
      }
    }
  }

  void _selectAddress(Map<String, dynamic> suggestion) {
    if (!mounted) return;
    setState(() {
      _fullAddressController.text = suggestion['display_name'] ?? '';
      _addressSearchController.text = suggestion['display_name'] ?? '';

      // Populate individual address components from the 'address' sub-map
      final address = suggestion['address'] as Map<String, dynamic>?;
      _stateController.text = address?['state'] ?? '';
      _countryController.text = address?['country'] ?? '';
      _landmarkController.text =
          address?['road'] ?? address?['neighbourhood'] ?? '';

      _latitude = double.tryParse(suggestion['lat'] ?? '');
      _longitude = double.tryParse(suggestion['lon'] ?? '');
      _addressSuggestions = [];
    });
  }

  Future<XFile?> _pickFile(ImageSource source) async {
    final picker = ImagePicker();
    return await picker.pickImage(source: source);
  }

  void _registerAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if the mandatory documents are picked
    if (_registrationCertificate == null || _adminIdProof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all mandatory documents.')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select the hospital address using the search functionality.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final result = await _apiService.registerAdmin(
      hospitalName: _hospitalNameController.text,
      hospitalType: _hospitalType,
      ownerName: _ownerNameController.text,
      email: _emailController.text,
      contact: _contactNumberController.text,
      altContact: _alternateContactController.text,
      upiId: _upiIdController.text,
      address: _fullAddressController.text,
      landmark: _landmarkController.text,
      state: _stateController.text,
      country: _countryController.text,
      latitude: _latitude!,
      longitude: _longitude!,
      emergency: _emergencyAvailable,
      departments: _departmentsController.text,
      opdAvailable: _opdAvailable,
      opdStartTime: _opdStartController.text,
      opdEndTime: _opdEndController.text,
      licenseNumber: _licenseNumberController.text,
      password: _passwordController.text,
      admissionFees: _admissionFeesController.text, // ✅ Pass new field
      registrationCertificate: _registrationCertificate,
      adminIdProof: _adminIdProof,
      hospitalLogo: _hospitalLogo,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Something went wrong')),
    );

    if (result['success']) {
      // Update the message and navigation for the new workflow
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration submitted! Awaiting administrator approval.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      // Redirect to the login page after a slight delay
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminLogin()),
        );
      });
    }
  }

  @override
  void dispose() {
    _addressSearchController.removeListener(_onAddressSearchChanged);
    _debounce?.cancel();
    _hospitalNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _alternateContactController.dispose();
    _upiIdController.dispose(); 
    _addressSearchController.dispose();
    _fullAddressController.dispose();
    _landmarkController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _departmentsController.dispose();
    _opdStartController.dispose();
    _opdEndController.dispose();
    _licenseNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _admissionFeesController.dispose(); // ✅ Dispose new controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFD7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBFD7FF),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFBFD7FF),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Add the logo here at the top center
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Image.asset(
                    'assets/images/adminregister.png', // Correct path to your image
                    height: 160, // Adjust the size as needed
                  ),
                ),
              ),
              // New Container with "Registration for Hospital" text
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.black, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    "Registration for Hospital",
                    style: TextStyle(
                      fontFamily: 'Platypi Regular',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                children: [
                  _buildTextField(
                    _hospitalNameController,
                    "Hospital Name",
                    Icons.local_hospital,
                  ),
                  _buildDropdown(
                    "Hospital Type",
                    ["Private", "Government", "Clinic", "Multi-specialty"],
                    _hospitalType,
                    (v) => setState(() => _hospitalType = v!),
                    Icons.category,
                  ),
                  _buildTextField(
                    _ownerNameController,
                    "Owner/Administrator Name",
                    Icons.person,
                  ),
                  _buildTextField(
                    _emailController,
                    "Email",
                    Icons.email,
                    type: TextInputType.emailAddress,
                  ),
                  _buildTextField(
                    _contactNumberController,
                    "Contact Number",
                    Icons.phone,
                    type: TextInputType.phone,
                  ),
                  _buildTextField(
                    _alternateContactController,
                    "Alternate Contact Number (optional)",
                    Icons.phone_android,
                    validator: (v) => null,
                  ),
                  _buildTextField(
                    _upiIdController,
                    "UPI ID",
                    Icons.account_balance_wallet,
                    type: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "UPI ID is required";
                      }
                      if (!RegExp(r'^[\w.\-]+@[\w]+$').hasMatch(v)) {
                        return "Enter valid UPI ID (e.g. name@bank)";
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Hospital Address"),
              _buildSection(
                children: [
                  _buildAddressSearchField(),
                  if (_isSearchingAddress)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (_addressSuggestions.isNotEmpty)
                    _buildAddressSuggestions(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _fullAddressController,
                    "Full Address",
                    Icons.location_on,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Address is required" : null,
                    readOnly: true,
                  ),
                  _buildTextField(
                    _landmarkController,
                    "Landmark (optional)",
                    Icons.place,
                    validator: (v) => null,
                    readOnly: true,
                  ),
                  _buildTextField(
                    _stateController,
                    "State",
                    Icons.map,
                    readOnly: true,
                  ),
                  _buildTextField(
                    _countryController,
                    "Country",
                    Icons.public,
                    readOnly: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Facility Details"),
              _buildSection(
                children: [
                  _buildSwitchListTile(
                    title: "Emergency Room Available",
                    value: _emergencyAvailable,
                    onChanged: (v) => setState(() => _emergencyAvailable = v),
                    icon: Icons.emergency,
                  ),
                  _buildTextField(
                    _departmentsController,
                    "Departments Offered (comma-separated)",
                    Icons.medical_services,
                    validator: (v) => null,
                  ),
                  _buildSwitchListTile(
                    title: "OPD Available",
                    value: _opdAvailable,
                    onChanged: (v) => setState(() => _opdAvailable = v),
                    icon: Icons.schedule,
                  ),
                  if (_opdAvailable) ...[
                    _buildTextField(
                      _opdStartController,
                      "OPD Start Time (e.g., 09:00 AM)",
                      Icons.access_time,
                      validator: (v) => null,
                    ),
                    _buildTextField(
                      _opdEndController,
                      "OPD End Time (e.g., 05:00 PM)",
                      Icons.access_time_filled,
                      validator: (v) => null,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Documents & Credentials"),
              _buildSection(
                children: [
                  // ✅ NEW TEXT FIELD FOR ADMISSION FEES
                  _buildTextField(
                    _admissionFeesController,
                    "Admission Fees (INR)",
                    Icons.attach_money,
                    type: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Admission Fees is required";
                      }
                      // Basic check for number format
                      if (double.tryParse(v) == null) {
                        return "Enter a valid number for fees";
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    _licenseNumberController,
                    "License Number",
                    Icons.badge,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "License Number is required";
                      }
                      final regex = RegExp(
                        r'^(MH\/HSP\/\d{4}\/\d{4}|BMC\/Hospital\/\d{5}|CEA\/MH\/\d{4}\/\d{5})$',
                      );
                      if (!regex.hasMatch(v)) {
                        return "Invalid format. E.g., MH/HSP/2025/1234";
                      }
                      return null;
                    },
                  ),
                  _buildImagePicker(
                    "Hospital Registration Certificate*",
                    (file) => setState(() => _registrationCertificate = file),
                    _registrationCertificate,
                    Icons.file_copy,
                    mandatory: true,
                  ),
                  _buildImagePicker(
                    "Admin ID Proof*",
                    (file) => setState(() => _adminIdProof = file),
                    _adminIdProof,
                    Icons.person,
                    mandatory: true,
                  ),
                  _buildImagePicker(
                    "Hospital Logo (optional)",
                    (file) => setState(() => _hospitalLogo = file),
                    _hospitalLogo,
                    Icons.image,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Account Details"),
              _buildSection(
                children: [
                  _buildPasswordTextField(
                    _passwordController,
                    "Password",
                    obscureText: !_isPasswordVisible,
                  ),
                  _buildPasswordTextField(
                    _confirmPasswordController,
                    "Confirm Password",
                    obscureText: !_isPasswordVisible,
                  ),
                  _buildShowPasswordCheckbox(),
                ],
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.teal),
                    )
                  : SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _registerAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.teal.shade200,
                        ),
                        child: const Text(
                          "Register Hospital",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // The updated _buildSection method without the Container
  Widget _buildSection({required List<Widget> children}) {
    return Column(
      children: children,
    );
  }

  Widget _buildAddressSearchField() {
    return _buildOutlinedFieldContainer(
      child: TextFormField(
        controller: _addressSearchController,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: "Search for Hospital Address",
          labelStyle: const TextStyle(color: Colors.black),
          prefixIcon: Icon(Icons.search, color: Colors.teal.shade600),
          suffixIcon: _isSearchingAddress
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildAddressSuggestions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _addressSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _addressSuggestions[index];
          return ListTile(
            leading: const Icon(Icons.location_on, color: Colors.teal),
            title: Text(
              suggestion['display_name'] ?? 'No Name',
              style: const TextStyle(color: Colors.black),
            ),
            onTap: () => _selectAddress(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return _buildOutlinedFieldContainer(
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        readOnly: readOnly,
        style: const TextStyle(color: Colors.black),
        validator: validator ??
            (v) {
              if (v == null || v.isEmpty) {
                if (controller == _addressSearchController) {
                  return null;
                }
                return "$label is required";
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          prefixIcon: Icon(icon, color: Colors.teal.shade600),
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildPasswordTextField(
    TextEditingController controller,
    String label, {
    required bool obscureText,
  }) {
    return _buildOutlinedFieldContainer(
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.black),
        validator: (v) {
          if (v == null || v.isEmpty) return "$label is required";
          if (label == "Confirm Password" && v != _passwordController.text) {
            return "Passwords do not match";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          prefixIcon: Icon(Icons.lock, color: Colors.teal.shade600),
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> options,
    String? value,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return _buildOutlinedFieldContainer(
      child: DropdownButtonFormField<String>(
        value: value,
        items: options
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(color: Colors.black),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          prefixIcon: Icon(icon, color: Colors.teal.shade600),
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildSwitchListTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return _buildOutlinedFieldContainer(
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.black),
        ),
        secondary: Icon(icon, color: Colors.teal.shade600),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.teal.shade600,
        activeTrackColor: Colors.teal.shade400,
        inactiveTrackColor: Colors.grey.shade300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildImagePicker(
    String label,
    Function(XFile?) onFilePicked,
    XFile? file,
    IconData icon, {
    bool mandatory = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4),
            child: RichText(
              text: TextSpan(
                text: label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
                children: mandatory
                    ? [
                        TextSpan(
                          text: '*',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final pickedFile = await _pickFile(ImageSource.gallery);
              onFilePicked(pickedFile);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: file != null
                        ? Colors.teal.shade600
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      file != null ? file.name : "Tap to select file...",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: file != null
                            ? Colors.teal.shade600
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (file != null)
                    Icon(Icons.check_circle, color: Colors.teal.shade600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A new helper widget to wrap fields with the desired styling
  Widget _buildOutlinedFieldContainer({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildShowPasswordCheckbox() {
    return Row(
      children: [
        Theme(
          data: ThemeData(unselectedWidgetColor: Colors.grey.shade400),
          child: Checkbox(
            value: _isPasswordVisible,
            onChanged: (v) => setState(() => _isPasswordVisible = v!),
            activeColor: Colors.teal.shade600,
          ),
        ),
        Text(
          "Show Passwords",
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    );
  }
}