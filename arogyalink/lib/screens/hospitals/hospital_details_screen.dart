// lib/screens/hospitals/hospital_details_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Assuming you have an ApiService to fetch hospital details
// import 'package:arogyalink/services/api_service.dart';

class HospitalDetailsScreen extends StatefulWidget {
  final int hospitalId;

  const HospitalDetailsScreen({super.key, required this.hospitalId});

  @override
  State<HospitalDetailsScreen> createState() => _HospitalDetailsScreenState();
}

class _HospitalDetailsScreenState extends State<HospitalDetailsScreen> {
  // Uncomment this when your ApiService is ready to fetch single hospital details
  // final ApiService _apiService = ApiService();
  // Map<String, dynamic>? _hospitalDetails;
  // bool _isLoading = true;
  // String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // This is where you would call a function to fetch the hospital details
    // For now, it's a placeholder. Uncomment the code below to implement it.
    // _fetchHospitalDetails();
  }

  // Future<void> _fetchHospitalDetails() async {
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = '';
  //   });
  //
  //   try {
  //     final response = await _apiService.fetchHospitalDetails(widget.hospitalId);
  //     if (response['success']) {
  //       setState(() {
  //         _hospitalDetails = response['data'];
  //       });
  //     } else {
  //       setState(() {
  //         _errorMessage = response['message'] ?? 'Failed to load hospital details.';
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _errorMessage = 'An error occurred. Please try again.';
  //     });
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // This is a placeholder UI. Once you have the data, you can build a detailed view.
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Hospital Details',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital_rounded,
              size: 80,
              // ignore: deprecated_member_use
              color: Colors.blueAccent.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Hospital ID: ${widget.hospitalId}',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Details coming soon...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
