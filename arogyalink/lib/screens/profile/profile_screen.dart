// ignore_for_file: prefer_final_fields, use_build_context_synchronously, prefer_const_constructors, deprecated_member_use, library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arogyalink/services/api_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart'; // Import for DateFormat

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _profileData = {};
  bool _isLoading = true;
  XFile? _imageFile;

  // Controllers for all the editable text fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _residentialAddressController =
      TextEditingController();
  final TextEditingController _emergencyContactNameController =
      TextEditingController();
  final TextEditingController _emergencyContactNumberController =
      TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();

  // ✅ NEW: Add controllers for country and state
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  
  // ✅ NEW: Age Controller (for display only)
  final TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    _genderController.dispose();
    _mobileNumberController.dispose();
    _residentialAddressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    _bloodGroupController.dispose();
    // ✅ NEW: Dispose of the new controllers
    _countryController.dispose();
    _stateController.dispose();
    _ageController.dispose(); // Dispose the new controller
    super.dispose();
  }

  // Helper function to calculate age from DOB
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

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });
    final result = await _apiService.getProfile();
    // Add a print statement to inspect the data
    if (kDebugMode) {
      print('API Response for Profile: $result');
    }

    if (result['success']) {
      setState(() {
        _profileData = result['data'];
        _isLoading = false;
        
        // Populate controllers with fetched data
        _usernameController.text = _profileData['username'] ?? '';
        _emailController.text = _profileData['email'] ?? '';
        
        final dob = _profileData['date_of_birth'];
        _dateOfBirthController.text = dob ?? '';
        
        // Populate Age Controller
        if (dob != null && dob != '') {
          _ageController.text = _calculateAgeFromDOB(dob).toString();
        } else {
          _ageController.text = 'N/A';
        }
        
        _genderController.text = _profileData['gender'] ?? '';
        _mobileNumberController.text = _profileData['mobile_number'] ?? '';
        _residentialAddressController.text =
            _profileData['residential_address'] ?? '';
        _emergencyContactNameController.text =
            _profileData['emergency_contact_name'] ?? '';
        _emergencyContactNumberController.text =
            _profileData['emergency_contact_number'] ?? '';
        _bloodGroupController.text = _profileData['blood_group'] ?? '';
        
        // ✅ NEW: Populate the new controllers
        _countryController.text = _profileData['country'] ?? '';
        _stateController.text = _profileData['state'] ?? '';
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${result['message']}')));
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> updatedData = {
        'username': _usernameController.text,
        'email': _emailController.text,
        'date_of_birth': _dateOfBirthController.text,
        'gender': _genderController.text,
        'mobile_number': _mobileNumberController.text,
        'residential_address': _residentialAddressController.text,
        'emergency_contact_name': _emergencyContactNameController.text,
        'emergency_contact_number': _emergencyContactNumberController.text,
        'blood_group': _bloodGroupController.text,
        // ✅ NEW: Add the country and state data to the map
        'country': _countryController.text,
        'state': _stateController.text,
      };

      Uint8List? imageBytes;
      String? imageFileName;
      if (_imageFile != null) {
        imageBytes = await _imageFile!.readAsBytes();
        imageFileName = _imageFile!.name;
      }

      final result = await _apiService.updateProfile(
        updatedData,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
        await _fetchProfile(); // Refresh profile data after update

        // Call the callback to notify the home screen
        if (widget.onProfileUpdated != null) {
          widget.onProfileUpdated!();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: ${result['message']}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? profileImageProvider;

    // Check if a new image file has been selected
    if (_imageFile != null) {
      profileImageProvider = kIsWeb
          ? Image.network(_imageFile!.path).image
          : Image.file(File(_imageFile!.path)).image;
    } else {
      // If no new image, try to use the image from the fetched profile data
      final String? profileImageBase64 = _profileData['profile_image_base64'];
      if (profileImageBase64 != null) {
        try {
          final Uint8List bytes = base64Decode(profileImageBase64);
          profileImageProvider = MemoryImage(bytes);
        } catch (e) {
          if (kDebugMode) print('Error decoding Base64 image: $e');
        }
      }
    }

    // Fallback to a placeholder if no image is available
    profileImageProvider ??= const AssetImage(
      'assets/images/user_placeholder.png',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.white,
                            backgroundImage: profileImageProvider,
                            child: (profileImageProvider is AssetImage)
                                ? const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.blueAccent,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: const CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 20,
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 20.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProfileDetailRow(
                              'Username',
                              _usernameController,
                              icon: Icons.person,
                            ),
                            _buildProfileDetailRow(
                              'Email',
                              _emailController,
                              icon: Icons.email,
                            ),
                            _buildProfileDetailRow(
                              'Date of Birth',
                              _dateOfBirthController,
                              icon: Icons.calendar_today,
                            ),
                            
                            // ✅ NEW: Age Field (Read-only)
                            _buildProfileDetailRow(
                              'Age',
                              _ageController,
                              icon: Icons.cake,
                              readOnly: true, // Age is calculated, not edited directly
                            ),
                            
                            _buildProfileDetailRow(
                              'Gender',
                              _genderController,
                              icon: Icons.wc,
                            ),
                            _buildProfileDetailRow(
                              'Mobile Number',
                              _mobileNumberController,
                              icon: Icons.phone,
                            ),
                            _buildProfileDetailRow(
                              'Residential Address',
                              _residentialAddressController,
                              icon: Icons.home,
                            ),
                            // ✅ NEW: Add the Country field
                            _buildProfileDetailRow(
                              'Country',
                              _countryController,
                              icon: Icons.flag,
                            ),
                            // ✅ NEW: Add the State field
                            _buildProfileDetailRow(
                              'State',
                              _stateController,
                              icon: Icons.location_city,
                            ),
                            _buildProfileDetailRow(
                              'Emergency Contact Name',
                              _emergencyContactNameController,
                              icon: Icons.contact_emergency,
                            ),
                            _buildProfileDetailRow(
                              'Emergency Contact No.',
                              _emergencyContactNumberController,
                              icon: Icons.phone_android,
                            ),
                            _buildProfileDetailRow(
                              'Blood Group',
                              _bloodGroupController,
                              icon: Icons.bloodtype,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: const Text(
                        'Update Profile',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Modified _buildProfileDetailRow to accept a readOnly parameter
  Widget _buildProfileDetailRow(
      String label,
      TextEditingController controller, {
        IconData? icon,
        bool readOnly = false, // New parameter
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly, // Apply readOnly
        style: TextStyle(
          color: readOnly ? Colors.black54 : Colors.black, // Change text color for read-only fields
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey[700]),
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.blueAccent)
              : null,
          filled: true,
          fillColor: readOnly ? Colors.grey[200] : Colors.grey[100], // Change background color for read-only fields
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
        ),
      ),
    );
  }
}