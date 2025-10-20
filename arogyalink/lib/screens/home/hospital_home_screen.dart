// ignore_for_file: deprecated_member_use, unused_local_variable, use_build_context_synchronously, unused_element

import 'dart:convert';
import 'package:arogyalink/screens/appointment/hospital_viewopd_appointment.dart';
import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:arogyalink/screens/roleselection/admin/admin_login.dart';
import 'package:arogyalink/screens/roleselection/admin/admin_profile_screen.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:arogyalink/screens/hospitals/check_bed_availability_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arogyalink/screens/records/upload_record_screen.dart';
import 'package:arogyalink/screens/profile/aboutus.dart';
import 'package:arogyalink/screens/profile/feedback.dart';
import 'package:arogyalink/screens/appointment/hospital_view_appointment.dart';
import 'package:arogyalink/screens/doctors/add_doctor_screen.dart';

// --- Color Palette ---
const Color primaryBlue = Color(0xFF1E88E5);
const Color secondaryBlue = Color(0xFF64B5F6);
const Color backgroundColor = Color(0xFFFAFADD);
const Color cardColor = Color(0xFFFFFFFF);
const Color checkInGreen = Color(0xFF4CAF50);
const Color textColor = Color(0xFF000000);
const Color lightGrey = Color(0xFFE0E0E0);
const Color warningRed = Color(0xFFE00000);
const Color functionalCardColor = Color(0xFFBFD7FF);

// A list of distinct colors for the occupied beds
const List<Color> occupiedColors = [
  Color(0xFFDABAA5),
  Color(0xFFBE79DC),
  Color(0xFFCE5CA6),
  Color(0xFF727BB3),
];

// A list of distinct colors for the partitions (for available beds)
const List<Color> partitionColors = [
  Color(0xFFD5D5D5),
  Color(0xFFD5D5D5),
  Color(0xFFD5D5D5),
  Color(0xFFD5D5D5),
  Color(0xFFD5D5D5),
  Color(0xFFD5D5D5),
  Color(0xFFD5D5D5),
  Color(0xFFD5D5D5),
];

class HospitalHomeScreen extends StatefulWidget {
  const HospitalHomeScreen({super.key});

  @override
  State<HospitalHomeScreen> createState() => _HospitalHomeScreenState();
}

class _HospitalHomeScreenState extends State<HospitalHomeScreen> {
  final ApiService _apiService = ApiService();
  String? _hospitalLogoBase64;
  String _hospitalName = "Admin";
  bool _isLoadingLogo = true;
  bool _isLoadingData = true;

  double _availableBeds = 0;
  double _totalBeds = 0;
  List<dynamic> _bedPartitions = [];


  @override
  void initState() {
    super.initState();
    // 💡 FIX 1: _checkSetupStatus call ko initState se hata diya gaya hai.
    // Ab yeh call _fetchDashboardData() ke finally block mein hoga.
    _fetchDashboardData();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

   Future<void> _checkSetupStatus() async {
    final response = await _apiService.checkHospitalSetupStatus(); 
    
    // Debugging ke liye: Console mein response check karein
    print('Setup Status Response: $response'); 

    if (response['success'] == true) {
      final bool isSetupComplete = response['setup_complete'] ?? true;
      final data = response['data']; 

      bool hasDoctor = true;
      bool hasPartition = true;

      // Case 1: Agar 'data' key mojud hai (jaisa API ko bhejni chahiye)
      if (data != null) { 
        hasDoctor = data['has_doctor'] ?? false;
        hasPartition = data['has_partition'] ?? false;

      // Case 2: Agar 'data' key missing hai, par 'setup_complete' false hai (Aapka case)
      } else if (isSetupComplete == false) {
        
        final message = response['message']?.toString().toLowerCase() ?? '';
        
        // Message ke aadhar par missing items ka anumaan lagana:
        if (message.contains('doctor') && message.contains('partition')) {
             hasDoctor = false;
             hasPartition = false;
        } else if (message.contains('doctor')) {
            // Aapke response ke liye: hasDoctor = false, hasPartition = true
            hasDoctor = false;
            hasPartition = true;
        } else if (message.contains('partition') || message.contains('bed')) {
            hasDoctor = true;
            hasPartition = false;
        } else {
            // Agar message generic hai, toh dono ko missing maan lo (Failsafe)
            hasDoctor = false;
            hasPartition = false;
        }
      }
      
      // Agar Doctor ya Partition missing hai, toh ab alert dikhega
      if (!hasDoctor || !hasPartition) {
        _showSetupAlert(hasDoctor, hasPartition);
      }
      
    } else {
      // optional: show a snackbar if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Failed to check setup')),
      );
    }
  }
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoadingLogo = true;
      _isLoadingData = true;
    });

    try {
      // Use Future.wait to fetch both profile and appointment data concurrently
      final profileResponse = await _apiService.getAdminProfile();

      // Process profile data
      if (profileResponse['success'] && profileResponse['data'] != null) {
        final profileData = profileResponse['data'];
        final logoData = profileData['hospital_logo'];
        final hospitalName = profileData['hospital_name'] ?? "Admin";
        final List<dynamic> fetchedPartitions =
            profileData['bed_partitions'] ?? [];

        final double totalBedsSum = fetchedPartitions.fold<double>(
          0.0,
          (sum, partition) => sum + (partition['total_beds'] as num).toDouble(),
        );

        final double availableBedsSum = fetchedPartitions.fold<double>(
          0.0,
          (sum, partition) =>
              sum + (partition['available_beds'] as num).toDouble(),
        );

        setState(() {
          _hospitalLogoBase64 = logoData;
          _hospitalName = hospitalName;
          _totalBeds = totalBedsSum;
          _availableBeds = availableBedsSum;
          _bedPartitions = fetchedPartitions;
        });
      }

      // Appointment data fetching and processing removed.
      
    } catch (e) {
      print('Failed to fetch dashboard data: $e');
    } finally {
      setState(() {
        _isLoadingLogo = false;
        _isLoadingData = false;
      });
      
      // 💡 FIX 3: Dashboard data fetch aur UI updates ke baad status check karein.
      // Yeh ensure karta hai ki context stable hai aur pop-up dikhega.
      _checkSetupStatus(); 
    }
  }

  // REMOVED: _processAppointmentCounts function

  void _logout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AdminLogin()),
        (Route<dynamic> route) => false,
      );
    }
  }
  
 void _showSetupAlert(bool hasDoctor, bool hasPartition) {
    String missingItems = '';
    if (!hasDoctor && !hasPartition) {
      missingItems = 'doctors and bed partitions';
    } else if (!hasDoctor) {
      missingItems = 'doctors';
    } else if (!hasPartition) {
      missingItems = 'bed partitions';
    }

    showDialog(
      context: context,
      // 💡 MODIFICATION: dialogue ko dismiss hone se rokne ke liye
      barrierDismissible: false, 
      builder: (context) => AlertDialog(
        title: const Text(
          'Setup Incomplete',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Please complete hospital setup by adding $missingItems to continue.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          // REMOVED: 'Later' button was here.
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (!hasDoctor) {
                _navigateToAddDoctor();
              } else {
                _navigateToManageBeds();
              }
            },
            child: const Text('Go to Setup'),
          ),
        ],
      ),
    );
  }
  
  void _navigateToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminProfileScreen()),
    );
    _fetchDashboardData();
  }

  void _navigateToManageBeds() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckBedAvailabilityScreen(),
      ),
    );
    _fetchDashboardData();
  }

  void _navigateToUploadHealthRecord() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UploadRecordScreen(),
      ),
    );
  }

  void _navigateToViewHospitalization() {
      Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HospitalViewAppointmentsScreen(),
      ),
    );
  }

  void _navigateToViewOpdAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HospitalViewOpdAppointmentScreen(),
      ),
    );
  }
  
  // New method to navigate to the AddDoctorScreen
  void _navigateToAddDoctor() async {
    // 💡 FIX: 'await' ka upyog karein
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorScreen()),
    );
    // 💡 FIX: Screen par wapas aane ke baad dashboard data aur setup status dobara check karein
    _fetchDashboardData(); 
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    Color cardBgColor = cardColor,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 36, color: iconColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // REFACTORED: Single widget for Quick Action Cards
  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 80, // Reduced height for better fit
              decoration: BoxDecoration(
                color: functionalCardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 40,
                color: primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildBedAvailabilityGauge() {
    if (_totalBeds == 0) {
      return const Center(
        child: Text(
          "No beds configured. Please add bed partitions to get started.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Colors.black,
          ),
        ),
      );
    }
    return SizedBox(
      height: 200,
      width: 200,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            startAngle: 180,
            endAngle: 360,
            minimum: 0,
            maximum: _totalBeds,
            showLabels: false,
            showTicks: false,
            axisLineStyle: const AxisLineStyle(
              thickness: 0.2,
              color: lightGrey,
              thicknessUnit: GaugeSizeUnit.factor,
            ),
            ranges: <GaugeRange>[
              GaugeRange(
                startValue: 0,
                endValue: _availableBeds,
                color: checkInGreen.withOpacity(0.8),
                startWidth: 0.2,
                endWidth: 0.2,
                sizeUnit: GaugeSizeUnit.factor,
              ),
              GaugeRange(
                startValue: _availableBeds,
                endValue: _totalBeds,
                color: warningRed.withOpacity(0.8),
                startWidth: 0.2,
                endWidth: 0.2,
                sizeUnit: GaugeSizeUnit.factor,
              ),
            ],
            pointers: <GaugePointer>[
              NeedlePointer(
                value: _availableBeds,
                enableAnimation: true,
                needleEndWidth: 5,
                needleStartWidth: 1,
                knobStyle: const KnobStyle(
                  color: primaryBlue,
                  knobRadius: 0.08,
                  sizeUnit: GaugeSizeUnit.factor,
                ),
                needleColor: primaryBlue,
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_availableBeds.toInt()}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const Text(
                      'of Beds Available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                angle: 90,
                positionFactor: 0.5,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartitionVerticalBarChart() {
    final filteredPartitions = _bedPartitions
        .where((p) => (p['total_beds'] as num) > 0)
        .toList();

    double maxTotalBeds = filteredPartitions.fold<double>(
      0.0,
      (max, partition) => (partition['total_beds'] as num).toDouble() > max
          ? (partition['total_beds'] as num).toDouble()
          : max,
    );

    if (filteredPartitions.isEmpty || maxTotalBeds == 0) {
      return const SizedBox.shrink();
    }

    const double chartMaxHeight = 180.0;
    const double barWidth = 40.0;
    const double barBorderRadius = 8.0;

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(filteredPartitions.length, (index) {
            final partition = filteredPartitions[index];
            final color = partitionColors[index % partitionColors.length];
            final occupiedColor = occupiedColors[index % occupiedColors.length];
            final String partitionName =
                partition['partition_name']?.toString() ?? 'N/A';
            final String displayableName = (partitionName.toUpperCase() == 'NA')
                ? 'Unspecified'
                : partitionName;
            double totalBeds = (partition['total_beds'] as num).toDouble();
            double availableBeds =
                (partition['available_beds'] as num).toDouble();
            double occupiedBeds = totalBeds - availableBeds;

            double totalBarHeight = (totalBeds / maxTotalBeds) * chartMaxHeight;
            double availableBarHeight =
                (availableBeds / totalBeds) * totalBarHeight;
            double occupiedBarHeight = totalBarHeight - availableBarHeight;

            if (occupiedBeds > 0 && occupiedBarHeight < 5) {
              occupiedBarHeight = 5;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${availableBeds.toInt()}/${totalBeds.toInt()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: barWidth,
                    height: totalBarHeight,
                    decoration: BoxDecoration(
                      color: occupiedColor,
                      borderRadius: BorderRadius.circular(barBorderRadius),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (availableBeds > 0)
                          Container(
                            height: availableBarHeight,
                            width: barWidth,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD5D5D5),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(barBorderRadius),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: barWidth + 10,
                    child: Text(
                      displayableName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCombinedBedView() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: functionalCardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hotel, size: 36, color: checkInGreen),
                SizedBox(width: 12),
                Text(
                  "Bed Availability & Occupancy",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_totalBeds == 0)
              const Center(
                child: Text(
                  "No beds configured. Please add bed partitions to get started.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(child: _buildBedAvailabilityGauge()),
                  const SizedBox(width: 20),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPartitionVerticalBarChart(),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: _navigateToManageBeds,
                icon: const Icon(Icons.bed, color: primaryBlue),
                label: const Text(
                  "Manage Beds",
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: primaryBlue),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;

    ImageProvider? avatarImage;
    if (_hospitalLogoBase64 != null) {
      try {
        final bytes = base64Decode(_hospitalLogoBase64!);
        avatarImage = MemoryImage(bytes);
      } catch (e) {
        print('Error decoding logo for home screen: $e');
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEECACA),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _navigateToProfile,
            child: _isLoadingLogo
                ? const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  )
                : CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? const Icon(
                            Icons.account_circle,
                            color: primaryBlue,
                            size: 30,
                          )
                        : null,
                  ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Welcome, $_hospitalName",
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.verified,
                color: primaryBlue,
                size: 20,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _navigateToProfile();
                  break;
                case 'about':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutUsScreen()),
                  );
                  break;
                case 'feedback':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FeedbackScreen()),
                  );
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.black),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'about',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.black),
                      SizedBox(width: 8),
                      Text('About Us'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'feedback',
                  child: Row(
                    children: [
                      Icon(Icons.feedback, color: Colors.black),
                      SizedBox(width: 8),
                      Text('Feedback'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.black),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      // REMOVED: FloatingActionButton from the Stack
      body: SingleChildScrollView( 
        // MODIFICATION: Reduced vertical padding from 20.0 to 12.0
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quick Overview",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            isLargeScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded( // _buildCombinedBedView now takes the full width on large screens
                        child: SizedBox(
                          height: 400.0,
                          child: _buildCombinedBedView(),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildCombinedBedView(),
                    ],
                  ),
            // MODIFICATION: Reduced spacing from 30 to 16
            const SizedBox(height: 16), 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
        
                // Row 1: Appointments
                Row(
                  children: [
                    _buildQuickActionCard(
                      title: "View Hospitalization",
                      icon: Icons.local_hospital_outlined,
                      onTap: _navigateToViewHospitalization,
                    ),
                    const SizedBox(width: 20),
                    _buildQuickActionCard(
                      title: "View OPD Appointments",
                      icon: Icons.calendar_today_outlined,
                      onTap: _navigateToViewOpdAppointment,
                    ),
                  ],
                ),
        
                // MODIFICATION: Reduced spacing from 20 to 12
                const SizedBox(height: 12),
        
                // Row 2: Management/Records
                Row(
                  children: [
                    _buildQuickActionCard(
                      title: " Generate Hospitalization Bills",
                      icon: Icons.upload_file_outlined,
                      onTap: _navigateToUploadHealthRecord,
                    ),
                    const SizedBox(width: 20),
                    _buildQuickActionCard(
                      title: "Add and Manage Doctors",
                      icon: Icons.person_add_alt_1_outlined,
                      onTap: _navigateToAddDoctor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      // The Stack and FloatingActionButton are removed entirely
    );
  }
}

class HospitalCard extends StatelessWidget {
  final Map<String, dynamic> hospital;

  const HospitalCard({super.key, required this.hospital});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade50,
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.blueAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital['hospital_name'] ?? 'Hospital Name Not Available',
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              Text(
                "Beds: ${hospital['available_beds'] ?? 'N/A'}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}