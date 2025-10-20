// lib/screens/hospitals/hospital_search_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:arogyalink/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Assuming you have a detail screen for a hospital
import 'package:arogyalink/screens/hospitals/hospital_details_screen.dart';
import 'package:arogyalink/screens/hospitals/hospital_map_screen.dart';

class HospitalSearchScreen extends StatefulWidget {
  const HospitalSearchScreen({super.key});

  @override
  State<HospitalSearchScreen> createState() => _HospitalSearchScreenState();
}

class _HospitalSearchScreenState extends State<HospitalSearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allHospitals = [];
  List<dynamic> _filteredHospitals = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Start fetching all hospitals as soon as the screen is initialized
    _fetchAllHospitals();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiService.fetchAllHospitals();

      if (response['success']) {
        setState(() {
          _allHospitals = response['data'] ?? [];
          _filteredHospitals = _allHospitals;
        });
        if (kDebugMode) {
          print("✅ Fetched hospitals successfully: $_allHospitals");
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load hospitals.';
        });
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error fetching hospitals: $e");
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHospitals = _allHospitals.where((hospital) {
        final hospitalName = hospital['hospital_name']?.toLowerCase() ?? '';
        final address = hospital['address']?.toLowerCase() ?? '';
        final departments = hospital['departments']?.toLowerCase() ?? '';
        return hospitalName.contains(query) ||
            address.contains(query) ||
            departments.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Search Hospitals',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for hospitals...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              )
            else if (_filteredHospitals.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No hospitals found.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredHospitals.length,
                  itemBuilder: (context, index) {
                    final hospital = _filteredHospitals[index];
                    return HospitalCard(
                      hospital: hospital,
                      onTap: () {
                        // Navigate to a hospital details screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HospitalDetailsScreen(
                              hospitalId: hospital['id'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HospitalCard extends StatelessWidget {
  final Map<String, dynamic> hospital;
  final VoidCallback onTap;

  const HospitalCard({super.key, required this.hospital, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade50,
              child: const Icon(
                Icons.local_hospital_rounded,
                color: Colors.blueAccent,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospital['hospital_name'] ?? 'Hospital Name',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hospital['address'] ?? 'No address provided',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (hospital['emergency'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Emergency Available',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Available beds
                  Text(
                    "Available Beds: ${hospital['available_beds'] ?? 'N/A'}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Go map button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HospitalMapScreen(
                            latitude: hospital['latitude'],
                            longitude: hospital['longitude'],
                            hospitalName: hospital['hospital_name'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text("Go Map"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
