import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class ApiService {
  // Base URL for the API server. This needs to be updated for a production environment.
  final String _baseUrl = 'http://192.168.215.196:5000/api';

  /// Saves the JWT authentication token to shared preferences.
  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  /// Retrieves the JWT authentication token from shared preferences.
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
 // This method now handles saving the doctor-specific token
  Future<void> _saveDoctorToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('doctor_token', token);
  }

  // This method now handles retrieving the doctor-specific token
  Future<String?> _getDoctorToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('doctor_token');
  }

  /// Clears the authentication token, effectively logging the user out.
   Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('doctor_token');
    await prefs.remove('jwt_token'); // Keep this to clear other tokens if needed
  }

  /// Registers a new patient with optional personal and medical details.
  Future<Map<String, dynamic>> registerPatient({
    required String username,
    required String email,
    required String password,
    String? dateOfBirth,
    String? age, // Added age field
    String? gender,
    String? mobileNumber,
    String? residentialAddress,
    String? state, // Added state field
    String? country, // Added country field
    String? emergencyContactName,
    String? emergencyContactNumber,
    String? bloodGroup,
    String? knownAllergies,
    String? chronicIllnesses,
    String? currentMedications,
    String? pastSurgeries,
    String? vaccinationDetails,
  }) async {
    final url = Uri.parse('$_baseUrl/patient/register');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
          "date_of_birth": dateOfBirth,
          "age": age, // Included age in the request body
          "gender": gender,
          "mobile_number": mobileNumber,
          "residential_address": residentialAddress,
          "state": state, // Included in the request body
          "country": country, // Included in the request body
          "emergency_contact_name": emergencyContactName,
          "emergency_contact_number": emergencyContactNumber,
          "blood_group": bloodGroup,
          "known_allergies": knownAllergies,
          "chronic_illnesses": chronicIllnesses,
          "current_medications": currentMedications,
          "past_surgeries": pastSurgeries,
          "vaccination_details": vaccinationDetails,
        }),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      if (kDebugMode) print("RegisterPatient Exception: $e");
      return {'success': false, 'message': 'An exception occurred: $e'};
    }
  }

  /// Authenticates a patient using their email/username and password.
  Future<Map<String, dynamic>> loginPatient({
    required String identifier,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/patient/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'identifier': identifier, 'password': password}),
      );

      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        final String token = responseBody['access_token'];
        if (kDebugMode) print("🟢 Token received: $token");

        await _saveAuthToken(token);
        if (kDebugMode) print("✅ Token saved successfully");

        return {'success': true, 'token': token, 'user': responseBody['user']};
      } else {
        if (kDebugMode) print("❌ Login failed: ${responseBody['message']}");
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      if (kDebugMode) print("❌ Network error: $e");
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Requests a password reset OTP for a patient via email.
  Future<Map<String, dynamic>> requestPasswordResetOtp(String email) async {
    final url = Uri.parse('$_baseUrl/forgot-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseBody['message']};
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to send OTP.',
        };
      }
    } catch (e) {
      if (kDebugMode) print("RequestPasswordResetOtp Exception: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Verifies the OTP sent to the user's email.
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse('$_baseUrl/verify-otp');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseBody['message']};
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Invalid or expired OTP.',
        };
      }
    } catch (e) {
      if (kDebugMode) print("VerifyOtp Exception: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Registers a new hospital admin. This includes uploading files like
Future<Map<String, dynamic>> registerAdmin({
  required String hospitalName,
  required String email,
  required String password,
  required String upiId,
  required String admissionFees, // ✅ Added admissionFees
  String? hospitalType,
  String? ownerName,
  String? contact,
  String? altContact,
  String? address,
  String? landmark,
  String? state,
  String? country,
  required bool emergency,
  String? departments,
  required bool opdAvailable,
  String? opdStartTime,
  String? opdEndTime,
  String? licenseNumber,
  required double latitude,
  required double longitude,
  XFile? registrationCertificate,
  XFile? adminIdProof,
  XFile? hospitalLogo,
}) async {
  final url = Uri.parse('$_baseUrl/admin/register');

  try {
    var request = http.MultipartRequest('POST', url);

    request.fields['hospital_name'] = hospitalName;
    request.fields['hospital_type'] = hospitalType ?? '';
    request.fields['owner_name'] = ownerName ?? '';
    request.fields['email'] = email;
    request.fields['contact'] = contact ?? '';
    request.fields['alt_contact'] = altContact ?? '';
    request.fields['upi_id'] = upiId;
    request.fields['admission_fees'] = admissionFees; // ✅ send new field
    request.fields['address'] = address ?? '';
    request.fields['landmark'] = landmark ?? '';
    request.fields['state'] = state ?? '';
    request.fields['country'] = country ?? '';
    request.fields['emergency'] = emergency.toString();
    request.fields['departments'] = departments ?? '';
    request.fields['opd_available'] = opdAvailable.toString();
    request.fields['opd_start_time'] = opdStartTime ?? '';
    request.fields['opd_end_time'] = opdEndTime ?? '';
    request.fields['license_number'] = licenseNumber ?? '';
    request.fields['password'] = password;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();

    // Add files to the request if they are provided
    if (registrationCertificate != null) {
      request.files.add(
        await _createMultipartFile('registration_doc', registrationCertificate),
      );
    }

    if (adminIdProof != null) {
      request.files.add(
        await _createMultipartFile('admin_id', adminIdProof),
      );
    }

    if (hospitalLogo != null) {
      request.files.add(await _createMultipartFile('logo', hospitalLogo));
    }

    var response = await request.send();
    var responseBody = await http.Response.fromStream(response);
    var responseData = json.decode(responseBody.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'message': responseData['message']};
    } else {
      return {
        'success': false,
        'message': responseData['message'] ??
            'Registration failed with status: ${response.statusCode}',
      };
    }
  } catch (e) {
    if (kDebugMode) print("RegisterAdmin Exception: $e");
    return {'success': false, 'message': 'Network error: $e'};
  }
}

  /// Helper method to create a `MultipartFile` from an `XFile`.
  Future<http.MultipartFile> _createMultipartFile(
    String fieldName,
    XFile file,
  ) async {
    final fileBytes = await file.readAsBytes();
    final fileName = file.name;
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
    final mimeSplit = mimeType.split('/');

    return http.MultipartFile.fromBytes(
      fieldName,
      fileBytes,
      filename: fileName,
      contentType: MediaType(mimeSplit[0], mimeSplit[1]),
    );
  }

  /// Retrieves the stored JWT token.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (kDebugMode) print("📦 Loaded token: $token");
    return token;
  }

  /// Authenticates an admin using their email/username and password.
  Future<Map<String, dynamic>> loginAdmin({
    required String identifier,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/admin/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'identifier': identifier, 'password': password}),
      );
      // NEW: Log the full response for debugging
      if (kDebugMode) {
        print("Received response from backend:");
        print("Status Code: ${response.statusCode}");
        print("Response Body: ${response.body}");
      }
      
      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        if (kDebugMode) print("✅ Response status is 200 OK. Proceeding to parse token.");
        final String token = responseBody['access_token'];
        if (kDebugMode) print("🟢 Admin token received: $token");

        await _saveAuthToken(token);
        if (kDebugMode) print("✅ Admin token saved successfully");

        return {'success': true, 'token': token, 'user': responseBody['user']};
      } else {
        if (kDebugMode) {
          print("❌ Admin login failed: ${responseBody['message']}");
        }
        // The error message comes from the backend, so we return it directly
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      if (kDebugMode) print("❌ Admin login network error: $e");
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Fetches the profile data for the currently authenticated patient.
  Future<Map<String, dynamic>> getProfile() async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'message': 'Token not found'};
    }

    final url = Uri.parse('$_baseUrl/patient/profile');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Ensure the response data contains a 'data' key with the profile
        // The patient profile should include 'state' and 'country' fields
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch profile: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

/// Fetches the profile data for the currently authenticated admin.
  Future<Map<String, dynamic>> getAdminProfile() async {
    final token = await _getAuthToken();
    if (token == null) {
      if (kDebugMode) print("❌ Token not found. Cannot fetch admin profile.");
      return {'success': false, 'message': 'Authentication token not found.'};
    }

    final url = Uri.parse('$_baseUrl/admin/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) print("🔹 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Safe parsing of nested fields
        final data = responseData['data'] ?? {};
        if (kDebugMode) print("🔹 Parsed data: $data");

        return {'success': true, 'data': data};
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (kDebugMode) print("❌ Error response: $responseData");
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to fetch admin profile.',
        };
      }
    } catch (e) {
      if (kDebugMode) print("❌ Network error fetching admin profile: $e");
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Updates the patient's profile with optional image upload.
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> updatedData, {
    Uint8List? imageBytes,
    String? imageFileName,
}) async {
    final token = await _getAuthToken();
    if (token == null) {
        return {'success': false, 'message': 'Token not found'};
    }

    final url = Uri.parse('$_baseUrl/patient/update_profile_with_image');

    try {
        var request = http.MultipartRequest('POST', url);
        request.headers['Authorization'] = 'Bearer $token';

        // ❌ REMOVED the redundant specific checks for 'state' and 'country'
        //    because the loop below handles all fields, including the new ones.

        // ✅ ADD ALL updated data fields to the request
        updatedData.forEach((key, value) {
            // Ensure values are sent as strings
            request.fields[key] = value.toString(); 
        });

        if (imageBytes != null) {
            final mimeType =
                lookupMimeType(imageFileName ?? 'profile_image.png') ?? 'image/png';
            final mimeSplit = mimeType.split('/');

            request.files.add(
                http.MultipartFile.fromBytes(
                    'profile_image',
                    imageBytes,
                    filename: imageFileName ?? 'profile_image.png',
                    contentType: MediaType(mimeSplit[0], mimeSplit[1]),
                ),
            );
        }

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        var responseBody = json.decode(response.body);

        if (response.statusCode == 200) {
            return {'success': true, 'message': responseBody['message']};
        } else {
            return {
                'success': false,
                'message': responseBody['message'] ?? 'Update failed',
            };
        }
    } catch (e) {
        if (kDebugMode) print("updateProfile Exception: $e");
        return {'success': false, 'message': 'Network error: $e'};
    }
}
  /// Fetches a list of all hospitals.
  Future<Map<String, dynamic>> fetchAllHospitals() async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'message': 'Token not found'};
    }
    final url = Uri.parse('$_baseUrl/patient/hospital');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['hospitals'] ?? []};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch all hospitals',
        };
      }
    } catch (e) {
      if (kDebugMode) print("fetchAllHospitals Exception: $e");
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Fetches detailed information for a single hospital by its ID.
  Future<Map<String, dynamic>> fetchHospitalDetails(int hospitalId) async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'message': 'Token not found'};
    }
    final url = Uri.parse('$_baseUrl/patient/hospital/$hospitalId');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to fetch hospital details.',
        };
      }
    } catch (e) {
      if (kDebugMode) print("fetchHospitalDetails Exception: $e");
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Searches for hospitals based on a query string.
  Future<Map<String, dynamic>> searchHospitals(String query) async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'message': 'Token not found'};
    }

    final url = Uri.parse('$_baseUrl/patient/search_hospital?name=$query');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['hospitals'] ?? []};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Search failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Fetches the profile data for a specific hospital (for patient view).
  Future<Map<String, dynamic>> getHospitalProfile(String hospitalId) async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'message': 'Token not found'};
    }

    final url = Uri.parse('$_baseUrl/patient/hospital/$hospitalId');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to fetch hospital profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Updates the hospital admin's profile with optional logo upload.
  Future<Map<String, dynamic>> updateAdminProfile(
    Map<String, dynamic> profileData, {
    XFile? hospitalLogo,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }

    final url = Uri.parse('$_baseUrl/admin/profile/update');

    var request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';

    profileData.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    if (hospitalLogo != null) {
      request.files.add(
        await _createMultipartFile('hospital_logo', hospitalLogo),
      );
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile updated successfully.',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile.',
        };
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error updating admin profile: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Resets a user's password using the OTP and new password.
  Future<Map<String, dynamic>> updatePassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final url = Uri.parse('$_baseUrl/reset-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': responseBody['message']};
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to update password.',
        };
      }
    } catch (e) {
      if (kDebugMode) print("UpdatePassword Exception: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Adds a new bed partition for a hospital.
  Future<Map<String, dynamic>> addBedPartition(
    Map<String, dynamic> data,
  ) async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }
    final url = Uri.parse('$_baseUrl/admin/bed_partitions');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );
      final responseData = json.decode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Partition added successfully!',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to add partition.',
        };
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error adding bed partition: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Updates an existing bed partition.
  Future<Map<String, dynamic>> updateBedPartition(
    int id,
    Map<String, dynamic> data,
  ) async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }
    final url = Uri.parse('$_baseUrl/admin/bed_partitions/$id');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );
      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Partition updated successfully!',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update partition.',
        };
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error updating bed partition: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Deletes a bed partition by its ID.
  Future<Map<String, dynamic>> deleteBedPartition(int id) async {
    final token = await _getAuthToken();

    if (kDebugMode) {
      print("Attempting to delete bed partition with ID: $id");
      print(
          "Retrieved token: ${token != null ? 'Token is present' : 'Token is null'}");
    }

    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }

    final url = Uri.parse('$_baseUrl/admin/bed_partitions/$id');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print("Response status code: ${response.statusCode}");
        print("Response headers: ${response.headers}");
        print("Response body: ${response.body}");
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        final responseData =
            response.body.isNotEmpty ? json.decode(response.body) : {};
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Partition deleted successfully!',
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Failed to delete partition. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error deleting bed partition: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Fetches all bed partitions for the authenticated admin's hospital.
  Future<Map<String, dynamic>> getBedPartitions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }

    final url = Uri.parse('$_baseUrl/admin/bed_partitions');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load bed partitions',
        };
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching bed partitions: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Searches for addresses and retrieves geocoding data using Nominatim API.
  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    if (query.length < 3) return [];

    final url = Uri.https("nominatim.openstreetmap.org", "/search", {
      "q": query,
      "format": "json",
      "addressdetails": "1",
      "limit": "5",
    });

    try {
      final response = await http.get(
        url,
        headers: {"User-Agent": "ArogyaLinkApp/1.0 (contact@arogyalink.com)"},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        if (kDebugMode) {
          print("Search failed with status: ${response.statusCode}");
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) print("❌ searchAddress Exception: $e");
      return [];
    }
  }

  /// Approves a pending admin account. This method should only be
  /// called by a super-admin with the correct permissions.
  Future<Map<String, dynamic>> approveAdmin({
    required int adminId,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }

    // The backend should have an endpoint specifically for this action.
    // We'll use a PUT request to update the admin's status.
    final url = Uri.parse('$_baseUrl/admin/approve/$adminId');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // The body can be empty or include a message like {'status': 'approved'}
        body: json.encode({'status': 'approved'}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Admin approved successfully.',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to approve admin.',
        };
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error approving admin: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
  Future<Map<String, dynamic>> getPatientAppointments() async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }

    final url = Uri.parse('$_baseUrl/patient/appointments');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'appointments': responseData['appointments']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch appointments.',
        };
      }
    } catch (e) {
      if (kDebugMode) print("❌ Network error fetching patient appointments: $e");
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
    // ✅ NEW: Method to send feedback to the API
  Future<Map<String, dynamic>> sendFeedback({
    required String feedbackType,
    required String feedbackText,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }

    final url = Uri.parse('$_baseUrl/feedback/submit');
    final Map<String, dynamic> body = {
      'feedbackType': feedbackType,
      'feedbackText': feedbackText,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send feedback.',
        };
      }
    } catch (e) {
      if (kDebugMode) print("sendFeedback Exception: $e");
      return {'success': false, 'message': 'An exception occurred: $e'};
    }
  }
  /// Books an OPD appointment by sending patient details to the backend.
  Future<Map<String, dynamic>> bookOpdAppointment({
    required String hospitalId,
    required String patientName,
    required int patientAge,
    required String patientContact,
    required String patientEmail,
    required String patientGender,
    required String appointmentDate,
    required String startTime, // ✅ Changed to startTime
    required String endTime, // ✅ Added endTime
    required String doctorId,
    required String symptoms,
    required bool isEmergency,
  }) async {
    final url = Uri.parse('$_baseUrl/patient/book_opd_appointment');
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication token not found.'};
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'hospital_id': hospitalId,
          'patientName': patientName,
          'patientAge': patientAge,
          'patientContact': patientContact,
          'patientEmail': patientEmail,
          'patientGender': patientGender,
          'appointmentDate': appointmentDate,
          'startTime': startTime, // ✅ Send start time directly
          'endTime': endTime, // ✅ Send end time directly
          'doctorId': doctorId,
          'symptoms': symptoms,
          'isEmergency': isEmergency,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'],
          'token_number': responseData['token_number'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to book appointment.',
        };
      }
    } catch (e) {
      if (kDebugMode) print('BookOpdAppointment Exception: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  // Function to add a doctor
 Future<Map<String, dynamic>> addDoctor({
  required String name,
  required String specialization,
  required String phone,
  required String email,
   required String password,
}) async {
  try {
    final token = await getToken(); // get saved token
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/doctors'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // attach token here
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'specialization': specialization,
        'phone': phone,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('API Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      return {'success': false, 'message': 'Failed. Status code: ${response.statusCode}'};
    }
  } catch (e) {
    print('Exception during addDoctor: $e');
    return {'success': false, 'message': 'Error: $e'};
  }
}

Future<Map<String, dynamic>> getDoctors() async {
  try {
    final token = await getToken(); // get token
    if (token == null) {
      return {'success': false, 'message': 'No token found. Please login again.'};
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/admin/doctors'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('API Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      return {
        'success': false,
        'message': 'Failed to fetch doctors. Status code: ${response.statusCode}'
      };
    }
  } catch (e) {
    print('Exception during getDoctors: $e');
    return {'success': false, 'message': 'Network error occurred: $e'};
  }
}

Future<Map<String, dynamic>> removeDoctor({required String doctorId}) async {
  try {
    final token = await getToken(); // get token
    if (token == null) {
      return {'success': false, 'message': 'No token found. Please login again.'};
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/admin/doctors/$doctorId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('API Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      return {
        'success': false,
        'message': 'Failed to remove doctor. Status code: ${response.statusCode}'
      };
    }
  } catch (e) {
    print('Exception during removeDoctor: $e');
    return {'success': false, 'message': 'Network error occurred: $e'};
  }
}
// Add this method to your ApiService class
Future<Map<String, dynamic>> getDoctorsByHospitalId(String hospitalId) async {
  try {
    // Construct the URL to fetch all doctors for the given hospitalId
    final url = Uri.parse("$_baseUrl/patient/hospital/$hospitalId/doctors");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      return {
        "success": false,
        "message": "Failed to fetch doctors. Status code: ${response.statusCode}"
      };
    }
  } catch (e) {
    if (kDebugMode) print("getDoctorsByHospitalId Exception: $e");
    return {"success": false, "message": "Network error: $e"};
  }
}
// Inside ApiService class
Future<Map<String, dynamic>> getBookedSlots(String hospitalId, String date, String doctorId) async {
  // Replace with your actual API endpoint
  final response = await http.get(Uri.parse('https://yourapi.com/bookedSlots?hospitalId=$hospitalId&date=$date'));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      'success': true,
      'data': data['slots'], // Make sure your API returns slots in a list
    };
  } else {
    return {
      'success': false,
      'data': [],
      'message': 'Failed to fetch booked slots'
    };
  }
}
 // Doctor Login
 Future<Map<String, dynamic>> doctorLogin({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$_baseUrl/doctor/login");
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
  'email': email.trim(),
  'password': password.trim(),
}),

      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        String jwtToken = data["access_token"];
        await _saveDoctorToken(jwtToken);
        return {'success': true, 'access_token': jwtToken};
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Login failed",
        };
      }
    } catch (e) {
      if (kDebugMode) print("Error during doctor login: $e");
      return {"success": false, "message": "Network error: $e"};
    }
  }
Future<Map<String, dynamic>> getOpdSlots({
  required String hospitalId,
  required String doctorId,
  required String appointmentDate,
}) async {
  try {
    final token = await _getAuthToken();
    if (token == null) {
      return {"success": false, "message": "Authentication token not found."};
    }

    final uri = Uri.parse("$_baseUrl/patient/get_opd_slots").replace(
      queryParameters: {
        "hospital_id": hospitalId,
        "doctor_id": doctorId,
        "date": appointmentDate,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        "success": false,
        "message": "Failed to fetch slots: ${response.statusCode}",
      };
    }
  } catch (e) {
    return {"success": false, "message": "Network error: $e"};
  }
}
// New method to fetch logged-in doctor's details
 Future<Map<String, dynamic>> getLoggedInDoctorProfile() async {
    final token = await _getDoctorToken();
    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'message': 'Authentication token not found. Please login again.'
      };
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/doctor/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await logout();
        return {
          'success': false,
          'message': 'Session expired. Please login again.'
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to load data.'
        };
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching doctor profile: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
 // Get doctor slots for a particular date
  Future<List<dynamic>> getDoctorSlots(String token, String date) async {
    final url = Uri.parse("$_baseUrl/doctor/my-slots/$date");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // JWT token
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data']; // list of slots
      } else {
        return [];
      }
    } else {
      throw Exception("Failed to load slots: ${response.statusCode}");
    }
  }
 Future<Map<String, dynamic>> maintainDoctorSlots(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/doctor/maintain-slots'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'success': false, 'message': 'Failed to maintain slots'};
    }
  }
Future<Map<String, dynamic>> getDoctorAppointments(String token) async {
  final url = Uri.parse("$_baseUrl/doctor/appointments");

  final response = await http.get(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token", // JWT token
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return data['data']; // Map<String, dynamic> -> date: [appointments]
    } else {
      return {};
    }
  } else {
    throw Exception("Failed to load appointments: ${response.statusCode}");
  }
}
 // Edit slot
  Future<void> editSlot(String token, int slotId, String startTime, String endTime) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/doctor/slot/$slotId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'start_time': startTime, 'end_time': endTime}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to edit slot');
    }
  }

  // Delete slot
  Future<void> deleteSlot(String token, int slotId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/doctor/slot/$slotId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete slot');
    }
  }
Future<Map<String, dynamic>> createDoctorSlot(String token, Map<String, String> slotData) async {
  final url = Uri.parse('$_baseUrl/doctor/slot');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(slotData),
  );

  if (response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to create slot: ${response.body}');
  }
}
Future<void> updateAppointmentStatus(
  String token,
  int appointmentId,
  String status, {
  String? referralReason, // optional parameter
}) async {
  final url = Uri.parse('$_baseUrl/doctor/appointment/$appointmentId/status');

  // prepare body
  final Map<String, dynamic> body = {'status': status};
  if (status == 'Referred' && referralReason != null && referralReason.isNotEmpty) {
    body['referral_reason'] = referralReason;
  }

  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to update appointment status');
  }
}
 Future<Map<String, dynamic>> getDoctorReferredAppointments(String token) async {
    final url = Uri.parse('$_baseUrl/doctor/appointments/referred');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch referred appointments');
    }
  }
Future<Map<String, dynamic>> getOPDAppointments() async {
  final token = await _getAuthToken(); // Assuming you have a function to get saved token
  if (token == null) {
    return {'success': false, 'message': 'Authentication token not found.'};
  }

  final url = Uri.parse('$_baseUrl/patient/opd_appointments');
  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final Map<String, dynamic> responseData = json.decode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      return {'success': true, 'appointments': responseData['data']};
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to fetch OPD appointments.',
      };
    }
  } catch (e) {
    if (kDebugMode) print("❌ Network error fetching OPD appointments: $e");
    return {'success': false, 'message': 'Network error: $e'};
  }
}
// Fetch all completed appointments for the logged-in doctor
Future<List<Map<String, dynamic>>> getCompletedAppointments(String token) async {
  final url = Uri.parse("$_baseUrl/doctor/appointments/completed");

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        // Return list of appointments
        return List<Map<String, dynamic>>.from(data['appointments']);
      } else {
        throw Exception(data['message'] ?? "Failed to fetch appointments");
      }
    } else {
      throw Exception("Error: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Network error: $e");
  }
}
// Send prescription details for a completed appointment
Future<void> addPrescription(
    String token, int appointmentId, Map<String, dynamic> prescriptionData) async {
  final url = Uri.parse("$_baseUrl/doctor/appointment/$appointmentId/prescription");

  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(prescriptionData),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? "Failed to add prescription");
    }
  } catch (e) {
    throw Exception("Network error: $e");
  }
}
// Fetch patients for bill generation
Future<List<Map<String, dynamic>>> getPatientsForBill(String token) async {
  final url = Uri.parse("$_baseUrl/doctor/appointments/bill_pending");

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['appointments']);
      } else {
        throw Exception(data['message'] ?? "Failed to fetch appointments");
      }
    } else {
      throw Exception("Error: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Network error: $e");
  }
}
Future<void> createOPDBill(String token, Map<String, dynamic> billData) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/doctor/appointments/generate_bill'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(billData),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to generate bill: ${response.body}');
  }
}
 Future<dynamic> fetchOpdReport(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/patient/patients/opd_report'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey("message")) {
        return {"message": data["message"]}; // jab prescription abhi nahi bana
      } else {
        return data; // appointments list
      }
    } else {
      throw Exception("Failed to fetch OPD report");
    }
  }
  Future<Map<String, dynamic>> fetchBillReport(String token) async {
  final response = await http.get(
    // NOTE: Check your final endpoint URL. 
    // Using the path you provided:
    Uri.parse('$_baseUrl/patient/patients/bill_report'), 
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    },
  );

  final dynamic responseData = jsonDecode(response.body);

  if (response.statusCode == 200) {
    // Case 1: Backend sends a message (e.g., "Bill not generated yet")
    if (responseData is Map && responseData.containsKey("message")) {
      return {"success": true, "message": responseData["message"], "data": []};
    } 
    // Case 2: Backend sends the list of bills directly
    else if (responseData is List) {
      return {"success": true, "data": responseData, "message": "Bills fetched successfully"}; 
    } 
    // Case 3: Invalid format
    else {
        return {"success": false, "message": "Invalid response format from server", "data": []};
    }
  } else if (response.statusCode == 404) {
    // Handle 404 (e.g., "No appointments found")
    return {"success": true, "message": responseData["message"] ?? "No appointments found", "data": []};
  } else {
    // Handle generic errors (401, 500, etc.)
    final errorMessage = responseData is Map && (responseData.containsKey("error") || responseData.containsKey("message")) 
                         ? responseData['error'] ?? responseData['message'] 
                         : "Failed to fetch bill report (Status: ${response.statusCode})";

    return {"success": false, "message": errorMessage, "data": []};
  }
}
  Future<dynamic> payBill(String token, int billId, String paymentMode) async {
  final response = await http.post(
    Uri.parse("$_baseUrl/patient/pay_bill/$billId"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "payment_mode": paymentMode, // "cash" or "upi"
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body); // expects {"success": true, "upi_info": {...}}
  } else {
    throw Exception("Failed to pay bill");
  }
}
/// Create Hospitalization Admission
Future<Map<String, dynamic>> createHospitalization({
  required int patientId,
  required Map<String, dynamic> admissionData,
}) async {
  final token = await _getAuthToken();
  if (token == null) {
    return {'success': false, 'message': 'Token not found'};
  }

  final url = Uri.parse('$_baseUrl/patient/patients/$patientId/hospitalization');

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(admissionData),
    );

    final Map<String, dynamic> responseData = json.decode(response.body);

    if (response.statusCode == 201) {
      return {
        'success': true,
        'message': responseData['message'],
        'hospitalization_id': responseData['hospitalization_id'],
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to create hospitalization'
      };
    }
  } catch (e) {
    return {'success': false, 'message': 'Network error: $e'};
  }
}
/// Fetches all hospitalization admissions for the authenticated hospital admin.
Future<Map<String, dynamic>> getHospitalizationAdmissions() async {
    // Correctly use the established method to get the admin's token
    final token = await _getAuthToken(); // This uses 'jwt_token' from prefs

    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }

    final url = Uri.parse("$_baseUrl/admin/hospitalization_admissions");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // The backend returns {'success': true, 'data': admissions_list}
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ??
              "Failed to load admissions: Status ${response.statusCode}"
        };
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching hospitalization admissions: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
Future<Map<String, dynamic>> getAdmissionDetails(int admissionId) async {
  await SharedPreferences.getInstance();
  final token = await _getAuthToken(); 

  if (token == null) {
    throw Exception("Token not found. Please login again.");
  }

  final response = await http.get(
    Uri.parse("$_baseUrl/admin/hospitalization_admissions/$admissionId"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  final Map<String, dynamic> jsonData = json.decode(response.body);

  if (response.statusCode == 200 && jsonData['success'] == true) {
    return jsonData['data'];
  } else {
    throw Exception(
      "Failed to load admission details: ${jsonData['message'] ?? response.body}"
    );
  }
}
 // ✅ Approve / Reject Admission
Future<Map<String, dynamic>> updateAdmissionStatus({
  required int admissionId,
  required String action, // "approve", "reject", or "discharge"
  String? rejectionReason,
  int? doctorId, // required if action is approve
}) async {
  final token = await _getAuthToken(); 
  if (token == null) {
    throw Exception("Token not found. Please login again.");
  }

  // Prepare body
  final Map<String, dynamic> body = {
    'action': action.toLowerCase(),
  };

  if (action.toLowerCase() == "approve") {
    if (doctorId == null) {
      throw Exception("Doctor ID is required to approve admission.");
    }
    body['doctor_id'] = doctorId; // ✅ must match backend key
  } else if (action.toLowerCase() == "reject") {
    if (rejectionReason == null || rejectionReason.trim().isEmpty) {
      throw Exception("Rejection reason is required to reject admission.");
    }
    body['rejection_reason'] = rejectionReason;
  }

  final response = await http.put(
    Uri.parse("$_baseUrl/admin/hospitalization_admissions/$admissionId/action"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
    body: json.encode(body),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception(
        "Failed to update admission status: ${response.statusCode} ${response.body}");
  }
}

Future<int?> getAdminHospitalId() async {
    final prefs = await SharedPreferences.getInstance();
    // Use the key you used to store the Admin ID during admin login
    return prefs.getInt('admin_id'); 
  }

  Future<Map<String, dynamic>> getOpdAppointmentsForHospital() async {
  final token = await _getAuthToken(); // JWT token prefs se le raha hai

  if (token == null) {
    return {'success': false, 'message': 'Authentication token not found.'};
  }

  final url = Uri.parse("$_baseUrl/admin/opd_appointments");

  try {
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    final responseData = json.decode(response.body);

    if (response.statusCode == 200) {
      return responseData; // {'success': true, 'data': [...] }
    } else {
      return {
        'success': false,
        'message': responseData['message'] ??
            "Failed to load OPD appointments: Status ${response.statusCode}"
      };
    }
  } catch (e) {
    if (kDebugMode) {
      print("❌ Error fetching OPD appointments: $e");
    }
    return {'success': false, 'message': 'An error occurred: $e'};
  }
}
 // ✅ NEW METHOD: To handle the patient ward shift using the new backend endpoint
  Future<Map<String, dynamic>> updateWardForAdmission({
    required int admissionId,
    required int newWardId, // The ID of the new Bed/Partition
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      return {'message': 'Authentication token not found.'};
    }

    // Backend endpoint: /admissions/<int:admission_id>/shift_ward (PUT request)
    final url = Uri.parse('$_baseUrl/admin/admissions/$admissionId/shift_ward');
    
    final body = <String, dynamic>{
      'new_bed_partition_id': newWardId, // Matches the backend's expected key
    };

    try {
      final response = await http.put( // Using PUT method as per common REST practice for updates
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Success response from backend
        return responseData; // Expects {'success': True, 'message': 'Patient successfully shifted...'}
      } else {
        // Handle 400/404/500 errors
        throw responseData['message'] ?? 'Failed to shift patient ward.';
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error shifting ward for admission $admissionId: $e");
      // Throw an exception so the UI's catch block can show the error message.
      rethrow; 
    }
  }
Future<Map<String, dynamic>> getDischargedHospitalizationAdmissions() async {
  final token = await _getAuthToken(); // JWT token shared prefs से ले रहे हैं

  if (token == null) {
    return {'success': false, 'message': 'Authentication token not found.'};
  }

  final url = Uri.parse("$_baseUrl/admin/hospitalization_admissions/discharged");

  try {
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    final responseData = json.decode(response.body);

    if (response.statusCode == 200) {
      return responseData; // {'success': true, 'data': [...] }
    } else {
      return {
        'success': false,
        'message': responseData['message'] ??
            "Failed to load discharged admissions: Status ${response.statusCode}"
      };
    }
  } catch (e) {
    if (kDebugMode) {
      print("❌ Error fetching discharged admissions: $e");
    }
    return {'success': false, 'message': 'An error occurred: $e'};
  }
}

Future<List<Map<String, dynamic>>> getDoctorHospitalizations(String token) async {
  final response = await http.get(
    Uri.parse("$_baseUrl/doctor/hospitalization_admissions"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch hospitalizations');
    }
  } else {
    throw Exception("Failed to fetch hospitalizations: ${response.statusCode} ${response.body}");
  }
}
Future<Map<String, dynamic>> submitDoctorHospitalizationAction({
  required int admissionId,
  required String treatmentNotes,
  required String statusUpdate,
  String? referralReason,
}) async {
  final token = await _getDoctorToken();
  if (token == null) throw Exception("Token not found. Please login again.");

  final response = await http.put(
    Uri.parse("$_baseUrl/doctor/hospitalization_admissions/$admissionId/doctor_action"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
    body: json.encode({
      "doctor_treatment_notes": treatmentNotes,
      "doctor_status_update": statusUpdate,
      if (statusUpdate == "Referred") "doctor_referral_reason": referralReason,
    }),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception(
        "Failed to submit doctor action: ${response.statusCode} ${response.body}");
  }
}
  // Fetch doctor treatment history for admin
  Future<Map<String, dynamic>> getDoctorTreatmentHistory() async {
    final token = await _getAuthToken();

    if (token == null) {
      return {'success': false, 'message': 'Authentication token not found.'};
    }

    final url = Uri.parse("$_baseUrl/admin/doctor_treatment_history");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Backend returns {'success': true, 'data': [...] }
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ??
              "Failed to load doctor treatment history: Status ${response.statusCode}"
        };
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching doctor treatment history: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
Future<int> getUnseenTreatmentCount() async {
  final token = await _getAuthToken();
  if (token == null) return 0;

  final url = Uri.parse("$_baseUrl/admin/treatment/unseen_count");

  try {
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    });

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['unseen_count'] ?? 0;
    }
  } catch (e) {
    debugPrint("Error fetching unseen count: $e");
  }
  return 0;
}

Future<bool> markTreatmentAsSeen() async {
  final token = await _getAuthToken();
  if (token == null) return false;

  final url = Uri.parse("$_baseUrl/admin/treatment/mark_seen");

  try {
    final response = await http.put(url, headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    });

    final data = json.decode(response.body);
    return response.statusCode == 200 && data['success'] == true;
  } catch (e) {
    debugPrint("Error marking seen: $e");
    return false;
  }
}
Future<Map<String, dynamic>> markAdmissionsSeen() async {
  try {
    final token = await _getDoctorToken();  // ✅ yaha token fetch
    final response = await http.put(
      Uri.parse('$_baseUrl/doctor/admissions/mark_seen'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',  // 🔑 token use kiya
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {"success": false, "message": "Failed to mark admissions as seen"};
    }
  } catch (e) {
    return {"success": false, "message": e.toString()};
  }
}
Future<int> getUnseenAdmissionsCount() async {
  try {
    final token = await _getDoctorToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/doctor/admissions/unseen_count'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['unseen_count'] ?? 0;
    } else {
      return 0;
    }
  } catch (e) {
    return 0;
  }
}
/// GET request for patient hospitalizations
// Remove 'static' here
Future<List<dynamic>> getMyHospitalizations() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  // Ensure you are using the _getAuthToken helper if it exists, 
  // or stick to the direct prefs access as you did:
  final String? token = prefs.getString('jwt_token'); 

  // Accessing _baseUrl is now valid because the method is not static
  final Uri url = Uri.parse('$_baseUrl/patient/my_hospitalizations'); 

  final response = await http.get(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    // The server returns: {"success": True, "data": admissions_list}
    final data = json.decode(response.body);
    // Return the list from the 'data' key
    return data['data']; 
  } else if (response.statusCode == 404) {
    return []; // No records found
  } else {
    throw Exception('Failed to fetch hospitalizations with status: ${response.statusCode}');
  }
}
Future<List<Map<String, dynamic>>> fetchTreatmentHistory(int admissionId) async {
  final token = await _getAuthToken();
  final response = await http.get(
    Uri.parse('$_baseUrl/admin/hospitalization/$admissionId/treatments'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
  }
  return [];
}
Future<Map<String, dynamic>?> generateHospitalizationBill(
  int admissionId, {
  double? roomCharges,
  double? doctorFees,
  double? treatmentCharges,
  double? medicineCharges,
  double? diagnosticCharges,
  double? miscCharges,
  double? insuranceCovered,
}) async {
  final token = await _getAuthToken();
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/hospitalization_bills/generate/$admissionId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'room_charges': roomCharges,
      'doctor_fees': doctorFees,
      'treatment_charges': treatmentCharges,
      'medicine_charges': medicineCharges,
      'diagnostic_charges': diagnosticCharges,
      'misc_charges': miscCharges,
      'insurance_covered': insuranceCovered,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) return data['data'];
  }
  return null;
}
Future<Map<String, dynamic>> fetchHospitalizationBills(String token) async {
  final token = await _getAuthToken();
  final response = await http.get(
    Uri.parse('$_baseUrl/patient/hospitalization_bills'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Failed to fetch hospitalization bills');
  }
}
Future<dynamic> payHospitalizationBill(
  String token,
  int billId,
  String paymentMode,
) async {
  final response = await http.post(
    Uri.parse("$_baseUrl/patient/pay_hospitalization_bill/$billId"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "payment_mode": paymentMode, // "cash" or "upi"
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to pay hospitalization bill: ${response.body}");
  }
}
Future<List<dynamic>> getPatientBills(int patientId, String token) async {
  final url = Uri.parse('$_baseUrl/patient/hospitalization_bills/$patientId');

  final response = await http.get(
    url,
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to fetch bills');
  }
}
Future<bool> markBillAsSeen(int billId, String token) async {
  final url = Uri.parse('$_baseUrl/patient/hospitalization_bills/mark_seen/$billId');

  final response = await http.patch(
    url,
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}
/// Fetches the count of doctors associated with the currently authenticated admin's hospital.
Future<Map<String, dynamic>> getDoctorCount() async {
  final token = await _getAuthToken();
  if (token == null) {
    if (kDebugMode) print("❌ Token not found. Cannot fetch doctor count.");
    return {'success': false, 'message': 'Authentication token not found.'};
  }

  // URL must match the new backend route: /admin/doctor_count
  final url = Uri.parse('$_baseUrl/admin/doctor_count'); 
  try {
    // ... (rest of the API call logic as provided in the previous response)
    // ...
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final data = responseData['data'] ?? {};
      return {'success': true, 'data': data};
    } 
    // ... (error handling)
  } catch (e) {
    // ... (catch block)
  }
  return {'success': false, 'message': 'Unknown error.'};
}
Future<Map<String, dynamic>> checkHospitalSetupStatus() async {
  final token = await _getAuthToken();
  if (token == null) {
    return {'success': false, 'message': 'Token not found'};
  }

  final url = Uri.parse('$_baseUrl/admin/check_setup_status');

  try {
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'setup_complete': data['setup_complete'],
        'message': data['message'],
      };
    } else {
      return {'success': false, 'message': data['message'] ?? 'Failed to check setup status'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Network error: $e'};
  }
}
}