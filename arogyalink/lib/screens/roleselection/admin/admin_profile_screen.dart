// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:convert'; // Import for base64Decode
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isEditing = false;
  Map<String, dynamic>? _adminData;
  String _errorText = '';

  Uint8List? _hospitalLogoBytes;
  XFile? _hospitalLogoFile;

  String? _hospitalLogoBase64;

  // Use late to initialize in initState
  late TextEditingController _hospitalNameController;
  late TextEditingController _emailController;
  late TextEditingController _ownerNameController;
  late TextEditingController _hospitalTypeController;
  late TextEditingController _contactController;
  late TextEditingController _altContactController;
  late TextEditingController _addressController;
  late TextEditingController _landmarkController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _licenseNumberController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty text initially
    _hospitalNameController = TextEditingController();
    _emailController = TextEditingController();
    _ownerNameController = TextEditingController();
    _hospitalTypeController = TextEditingController();
    _contactController = TextEditingController();
    _altContactController = TextEditingController();
    _addressController = TextEditingController();
    _landmarkController = TextEditingController();
    _stateController = TextEditingController();
    _countryController = TextEditingController();
    _licenseNumberController = TextEditingController();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _hospitalNameController.dispose();
    _emailController.dispose();
    _ownerNameController.dispose();
    _hospitalTypeController.dispose();
    _contactController.dispose();
    _altContactController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
      _errorText = '';
    });
    try {
      final response = await _apiService.getAdminProfile();
      if (response['success']) {
        setState(() {
          _adminData = response['data'];
          _isLoading = false;
          _hospitalLogoBase64 = _adminData!['hospital_logo'];
        });
        _updateControllers();
      } else {
        setState(() {
          _errorText = response['message'] ?? 'Failed to load profile data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _updateControllers() {
    if (_adminData != null) {
      _hospitalNameController.text = _adminData!['hospital_name'] ?? '';
      _emailController.text = _adminData!['email'] ?? '';
      _ownerNameController.text = _adminData!['owner_name'] ?? '';
      _hospitalTypeController.text = _adminData!['hospital_type'] ?? '';
      _contactController.text = _adminData!['contact'] ?? '';
      _altContactController.text = _adminData!['alt_contact'] ?? '';
      _addressController.text = _adminData!['address'] ?? '';
      _landmarkController.text = _adminData!['landmark'] ?? '';
      _stateController.text = _adminData!['state'] ?? '';
      _countryController.text = _adminData!['country'] ?? '';
      _licenseNumberController.text = _adminData!['license_number'] ?? '';
    }
  }

  Future<void> _pickHospitalLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _hospitalLogoFile = image;
        _hospitalLogoBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final updatedData = {
      'hospital_name': _hospitalNameController.text,
      'email': _emailController.text,
      'owner_name': _ownerNameController.text,
      'hospital_type': _hospitalTypeController.text,
      'contact': _contactController.text,
      'alt_contact': _altContactController.text,
      'address': _addressController.text,
      'landmark': _landmarkController.text,
      'state': _stateController.text,
      'country': _countryController.text,
      'license_number': _licenseNumberController.text,
    };

    try {
      final response = await _apiService.updateAdminProfile(
        updatedData,
        hospitalLogo: _hospitalLogoFile,
      );

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        setState(() {
          _isEditing = false;
          _hospitalLogoFile = null;
          _hospitalLogoBytes = null;
        });
        _fetchProfileData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to update profile.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _hospitalLogoFile = null;
        _hospitalLogoBytes = null;
        _updateControllers(); // Reset controllers to original fetched data
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Admin Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading && _adminData != null)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.save : Icons.edit,
                color: Colors.white,
              ),
              onPressed: _isEditing ? _saveProfile : _toggleEdit,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorText.isNotEmpty
              ? Center(child: Text(_errorText))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileHeader(
                        hospitalName: _adminData!['hospital_name'] ?? 'N/A',
                        hospitalLogoBase64: _hospitalLogoBase64,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  sectionTitle('Hospital Information'),
                                  _buildField(
                                    label: 'Hospital Name',
                                    icon: Icons.local_hospital,
                                    controller: _hospitalNameController,
                                  ),
                                  _buildField(
                                    label: 'Email',
                                    icon: Icons.email,
                                    controller: _emailController,
                                  ),
                                  _buildField(
                                    label: 'Owner Name',
                                    icon: Icons.person,
                                    controller: _ownerNameController,
                                  ),
                                  _buildField(
                                    label: 'Hospital Type',
                                    icon: Icons.category,
                                    controller: _hospitalTypeController,
                                  ),
                                  _buildField(
                                    label: 'License Number',
                                    icon: Icons.badge,
                                    controller: _licenseNumberController,
                                  ),
                                  const SizedBox(height: 16),
                                  sectionTitle('Contact & Address'),
                                  _buildField(
                                    label: 'Contact',
                                    icon: Icons.phone,
                                    controller: _contactController,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  _buildField(
                                    label: 'Alternate Contact',
                                    icon: Icons.phone_android,
                                    controller: _altContactController,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  _buildField(
                                    label: 'Address',
                                    icon: Icons.location_on,
                                    controller: _addressController,
                                  ),
                                  _buildField(
                                    label: 'Landmark',
                                    icon: Icons.place,
                                    controller: _landmarkController,
                                  ),
                                  _buildField(
                                    label: 'State',
                                    icon: Icons.location_city,
                                    controller: _stateController,
                                  ),
                                  _buildField(
                                    label: 'Country',
                                    icon: Icons.public,
                                    controller: _countryController,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue[900],
        ),
      ),
    );
  }

  Widget _buildProfileHeader({
    required String hospitalName,
    String? hospitalLogoBase64,
  }) {
    ImageProvider? avatarImage;

    // First, check if a new image has been selected by the user
    if (_hospitalLogoBytes != null) {
      avatarImage = MemoryImage(_hospitalLogoBytes!);
    }
    // If not, check if the backend has provided a Base64 string
    else if (hospitalLogoBase64 != null && hospitalLogoBase64.isNotEmpty) {
      try {
        // Decode the Base64 string into bytes
        final bytes = base64Decode(hospitalLogoBase64);
        avatarImage = MemoryImage(bytes);
      } catch (e) {
        // In case of a malformed Base64 string, log the error and use a placeholder
        print('Error decoding Base64 image from backend: $e');
        print('Failed Base64 String: $hospitalLogoBase64');
        avatarImage = null; // Fallback to the default icon
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blueAccent.shade700, Colors.blueAccent.shade400],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isEditing ? _pickHospitalLogo : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Icon(
                          Icons.local_hospital,
                          size: 60,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.blueAccent,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hospitalName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.verified, size: 28, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent, size: 28),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        subtitle: Text(
          value.isNotEmpty ? value : 'Not provided',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableItem({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          filled: true,
          fillColor: Colors.blue[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    // The email field should not be editable.
    if (label == 'Email') {
      return _buildProfileItem(
        icon: icon,
        label: label,
        value: controller.text.isNotEmpty ? controller.text : 'N/A',
      );
    }

    if (_isEditing) {
      return _buildEditableItem(
        controller: controller,
        label: label,
        icon: icon,
        keyboardType: keyboardType,
      );
    } else {
      return _buildProfileItem(
        icon: icon,
        label: label,
        value: controller.text.isNotEmpty ? controller.text : 'N/A',
      );
    }
  }
}