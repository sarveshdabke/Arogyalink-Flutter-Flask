// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:arogyalink/screens/doctors/view_opdappointment_screen.dart';
import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:arogyalink/screens/doctors/doctor_login.dart';
import 'package:arogyalink/screens/doctors/doc_profile.dart';
import 'package:arogyalink/screens/doctors/manage_opd_slots.dart';

// Import screens for the new buttons
import 'package:arogyalink/screens/doctors/refer_hospitalization_screen.dart';
import 'package:arogyalink/screens/doctors/prescription_upload_screen.dart';
import 'package:arogyalink/screens/doctors/generate_opd_bill_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  final String token;
  const DoctorHomeScreen({super.key, required this.token});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  Map<String, dynamic>? _doctorData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctorProfile();
    _maintainSlots();
  }

  Future<void> _fetchDoctorProfile() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getLoggedInDoctorProfile();

      if (response['success']) {
        setState(() {
          _doctorData = response['data'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load doctor data.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error fetching doctor profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _maintainSlots() async {
    try {
      final apiService = ApiService();
      final response = await apiService.maintainDoctorSlots(widget.token);

      if (response['success']) {
        print("✅ Slots maintained successfully");
      } else {
        print("⚠ Failed to maintain slots: ${response['message']}");
      }
    } catch (e) {
      print("❌ Error maintaining slots: $e");
    }
  }
  
  /// Handles the navigation to the Doctor Profile screen.
  void _navigateToProfile() {
    if (_doctorData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorProfileScreen(
            doctorData: _doctorData!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Profile data not available. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handles the logout process.
  Future<void> _logout() async {
    await ApiService().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DoctorLoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the list of action buttons
    final List<Widget> actionButtons = [
      _buildActionButton(
        icon: Icons.calendar_today,
        label: 'View Appointments',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ViewOPDAppointmentScreen(token: widget.token),
            ),
          );
        },
      ),
      _buildActionButton(
        icon: Icons.schedule,
        label: 'Manage OPD Slots',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ManageOPDSlotsScreen(token: widget.token),
            ),
          );
        },
      ),
      _buildActionButton(
        icon: Icons.local_hospital,
        label: 'Refer Hospitalization',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReferHospitalizationScreen(
                  token: widget.token),
            ),
          );
        },
      ),
      _buildActionButton(
        icon: Icons.receipt_long,
        label: 'Prescription Upload',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrescriptionUploadScreen(
                  token: widget.token),
            ),
          );
        },
      ),
      _buildActionButton(
        icon: Icons.monetization_on,
        label: 'Generate OPD Bill',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GenerateOPDBillScreen(
                  token: widget.token),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFACB6D9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(105),
        child: AppBar(
          backgroundColor: const Color(0xFFD9D9D9),
          toolbarHeight: 105,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(200),
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.0),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(200)),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _doctorData?['name'] ?? "Dr. Name",
                style: const TextStyle(
                  fontFamily: 'Lobster',
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            // --- START: POPUP MENU ---
            PopupMenuButton<String>(
              onSelected: (String result) {
                switch (result) {
                  case 'profile':
                    _navigateToProfile();
                    break;
                  case 'logout':
                    _logout();
                    break;
                }
              },
              icon: const Icon(
                Icons.more_vert, // Three dots icon
                color: Colors.black,
                size: 30,
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8), // Adjusted padding
            // --- END: POPUP MENU ---
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Profile Banner
                    GestureDetector(
                      onTap: _navigateToProfile,
                      child: Container(
                        width: double.infinity,
                        height: 80,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(46),
                          border: Border.all(color: Colors.black, width: 1.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: Text(
                                _doctorData?['specialization'] != null
                                    ? "Specialization: ${_doctorData!['specialization']}"
                                    : "Specialization: Not available",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            const VerticalDivider(
                              color: Colors.black,
                              thickness: 1,
                            ),
                            Expanded(
                              child: Text(
                                _doctorData?['hospital_name'] != null
                                    ? "Hospital: ${_doctorData!['hospital_name']}"
                                    : "Hospital: Not available",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Custom 2x2 grid layout using Column and Rows
                    Column(
                      children: [
                        // ROW 1: Card 1 and Card 2
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: actionButtons[0]), // View Appointments
                            const SizedBox(width: 16),
                            Expanded(child: actionButtons[1]), // Manage OPD Slots
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ROW 2: Card 3 and Card 4
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: actionButtons[2]), // Refer Hospitalization
                            const SizedBox(width: 16),
                            Expanded(child: actionButtons[3]), // Prescription Upload
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ROW 3: Card 5 (Centered)
                        // Use a Center widget with a fixed width to ensure it is centered
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400), // Max width for a single card
                            child: actionButtons[4], // Generate OPD Bill
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // The helper function remains the same, but it's now wrapped in Expanded widgets
  // or a Center widget in the build method for better layout control.
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    // This widget now serves as the content of the card.
    return InkWell(
      onTap: onPressed,
      child: Container(
        // Removed fixed width/height to allow Expanded to manage size in Rows
        height: 150, // Set a consistent height for visual balance
        decoration: BoxDecoration(
          color: const Color(0xFFC9D6ED),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blueAccent),
            const SizedBox(height: 8),
            Container(
              // Using Mediaquery or LayoutBuilder might be better, but retaining 
              // a large fixed width here is risky, so I'll simplify the label container
              // to be a percentage of the button's width.
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}