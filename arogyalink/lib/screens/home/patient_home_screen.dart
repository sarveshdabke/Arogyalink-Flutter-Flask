// ignore_for_file: deprecated_member_use, prefer_final_fields, unused_field, use_build_context_synchronously, prefer_const_constructors

import 'dart:convert';
import 'dart:typed_data';
import 'package:arogyalink/screens/roleselection/patient/pay_bills.dart';
import 'package:arogyalink/screens/roleselection/patient/view_opd_report.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:arogyalink/screens/roleselection/patient/patient_login.dart';
import 'package:arogyalink/screens/hospitals/nearby_hospitals.dart';
import 'package:arogyalink/screens/records/health_records_screen.dart';
import 'package:arogyalink/screens/profile/profile_screen.dart';
import 'package:arogyalink/screens/profile/aboutus.dart';
import 'package:arogyalink/screens/profile/feedback.dart';
import 'package:arogyalink/screens/appointment/my_appointments.dart';
import 'package:arogyalink/screens/roleselection/patient/patient_opd_appointment_view.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final ApiService _apiService = ApiService();
  String _username = 'Guest';
  String? _profileImageBase64;
  String _email = 'N/A';
  String _contact = 'N/A';
  bool _isLoadingProfile = true;
  int? _patientId;

  // 👇 Appointment data
  List<Map<String, dynamic>> _appointments = [];

  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _fetchAppointments();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPageIndex) {
        setState(() {
          _currentPageIndex = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final response = await _apiService.getProfile();
      if (response['success'] && response['data'] != null) {
        final profileData = response['data'];
        setState(() {
          _username =
              profileData['full_name'] ?? profileData['username'] ?? 'Guest';
          _profileImageBase64 = profileData['profile_image_base64'];
          _email = profileData['email'] ?? 'N/A';
          _contact = profileData['mobile_number'] ?? 'N/A';
          _patientId = profileData['id'] as int?;
        });
      }
    } catch (e) {
      print('Error fetching patient profile: $e');
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  /// Fetches the latest OPD appointment and updates the screen with token data.
  Future<void> _fetchAppointments() async {
    try {
      final response = await _apiService.getOPDAppointments();
      if (response['success'] && response['appointments'] != null) {
        final data = List<Map<String, dynamic>>.from(response['appointments']);

        // 👇 Filter only today's appointments that are not completed
        final today = DateTime.now();
        final todayStr = today.toIso8601String().substring(0, 10);

        final List<Map<String, dynamic>> todaysAppointments =
            data.where((appt) {
          final apptDate = appt['appointment_date'].toString();
          final status = appt['status']?.toString().toLowerCase() ?? '';
          return apptDate == todayStr && status != 'completed';
        }).toList();

        // 👇 Sort by start_time
        todaysAppointments.sort((a, b) {
          return a['start_time'].compareTo(b['start_time']);
        });

        setState(() {
          _appointments = todaysAppointments;
        });
      }
    } catch (e) {
      print("Error fetching appointments: $e");
    }
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PatientLogin()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _onMenuItemSelected(String value) async {
    switch (value) {
      case 'about_us':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AboutUsScreen()));
        break;
      case 'feedback':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const FeedbackScreen()));
        break;
      case 'logout':
        _logout();
        break;
    }
  }
  
  void _navigateToProfile() async {
     await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ProfileScreen()));
      _fetchProfileData();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarChild;
    if (_isLoadingProfile) {
      avatarChild = const CircleAvatar(
        backgroundColor: Colors.blueGrey,
        radius: 20,
        child: CircularProgressIndicator(strokeWidth: 2.0),
      );
    } else if (_profileImageBase64 != null) {
      try {
        final Uint8List bytes = base64Decode(_profileImageBase64!);
        avatarChild = CircleAvatar(
          radius: 20,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        avatarChild = const CircleAvatar(
          backgroundColor: Colors.blueGrey,
          radius: 20,
          child: Icon(Icons.person, color: Colors.white),
        );
      }
    } else {
      avatarChild = const CircleAvatar(
        backgroundColor: Colors.blueGrey,
        radius: 20,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFADD),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 112, 147, 207),
        elevation: 4,
        // 1. Updated: Logo inside a white circle
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.asset('assets/images/logo.png'),
            ),
          ),
        ),
        title: Text(
          'Welcome, $_username',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _onMenuItemSelected,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'about_us',
                child: Text('About Us'),
              ),
              const PopupMenuItem<String>(
                value: 'feedback',
                child: Text('Feedback'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 2. Updated: Wrapped the entire container with GestureDetector
              GestureDetector(
                onTap: _navigateToProfile,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    children: [
                      // Removed internal GestureDetector
                      avatarChild,
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _username,
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _email,
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _contact,
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Quick Action'),
              const SizedBox(height: 16),
              _buildQuickActionsContainer(),
              const SizedBox(height: 32),
              _buildSectionTitle("Today's Appointment Tracker"),
              const SizedBox(height: 16),
              // Conditional rendering of token trackers
              _buildTokenTrackers(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsContainer() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionCard(
              title: 'Health Record',
              imagePath: 'assets/images/records.png',
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HealthRecordScreen()));
              },
            ),
            const SizedBox(width: 16),
            _buildQuickActionCard(
              title: 'Nearby Hospitals',
              imagePath: 'assets/images/nearbylocation.png',
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NearbyHospitalsScreen()));
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // REPLACED 'Book Appointment' with 'View All Appointments'
            _buildQuickActionCard(
              title: 'View All Appointments',
              imagePath: 'assets/images/book_appointment.png', // Reusing image
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyAppointmentsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            _buildQuickActionCard(
              title: 'My OPD Appointments',
              imagePath: 'assets/images/my_appointments.png',
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const PatientOpdAppointmentView()));
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 👇 New row for added Quick Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionCard(
              title: 'Check OPD Reports',
              imagePath: 'assets/images/opd_reports.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ViewOpdReportScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            _buildQuickActionCard(
              title: 'Pay Bills',
              imagePath: 'assets/images/pay_bills.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PayBillsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // 👇 Token Tracker List Widget
  Widget _buildTokenTrackers() {
    if (_appointments.isEmpty) {
      return Center(
        child: Text("No active appointments for today",
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w500)),
      );
    }

    return Column(
      children: _appointments.map((appointment) {
        final doctorName = appointment['doctor_name'] ?? "Unknown Doctor";
        final tokenNumber = appointment['token_number'] ?? 0;
        final totalTokens = appointment['total_tokens'] ?? 10;
        final startTime = appointment['start_time'] ?? "";
        final endTime = appointment['end_time'] ?? "";
        final currentToken = appointment['current_token'] ?? 0;
        final positionInQueue = appointment['position_in_queue'] ?? 0;

        final progress =
            totalTokens > 0 ? currentToken / totalTokens : 0.0;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Doctor: $doctorName",
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
              const SizedBox(height: 12),
              Text("Current Token: $currentToken",
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Text("Your Token: $tokenNumber",
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Text("Your Position in Queue: $positionInQueue",
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Text("Total Tokens: $totalTokens",
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Text("Appointment Time: $startTime - $endTime",
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w400)),
            ],
          ),
        );
      }).toList(),
    );
  }
}