import 'package:arogyalink/screens/appointment/Hospitalization_analysis_Bydoctor.dart';
import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:arogyalink/screens/appointment/appointment_details_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:badges/badges.dart' as badges; // For badge widget

// Helper widget to display a single admission list
class _AdmissionListView extends StatelessWidget {
  final List<dynamic> admissions;
  final String emptyMessage;

  const _AdmissionListView({
    required this.admissions,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (admissions.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: admissions.length,
      itemBuilder: (context, index) {
        final admission = admissions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.bed, color: Colors.blue),
            title: Text(
              'Patient: ${admission['patient_name'] ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Reason: ${admission['reason_symptoms'] ?? 'No reason provided'}\n'
              'Status: ${admission['status'] ?? 'Pending'}\n',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Date:',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  '${admission['admission_date']?.split('T').first ?? 'N/A'}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentDetailsScreen(
                    admissionId: admission['id'], 
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Main screen widget
class HospitalViewAppointmentsScreen extends StatefulWidget {
  const HospitalViewAppointmentsScreen({super.key});

  @override
  State<HospitalViewAppointmentsScreen> createState() =>
      _HospitalViewAppointmentsScreenState();
}

class _HospitalViewAppointmentsScreenState
    extends State<HospitalViewAppointmentsScreen> {
  late Future<List<dynamic>> _admissionsFuture;
  final ApiService _apiService = ApiService();
  int _unseenCount = 0; // 🔹 Badge count

  @override
  void initState() {
    super.initState();
    _admissionsFuture = _fetchAdmissions();
    _fetchUnseenCount();
  }

  Future<List<dynamic>> _fetchAdmissions() async {
    try {
      final result = await _apiService.getHospitalizationAdmissions();
      if (result['success'] == true) {
        return result['data'] ?? [];
      } else {
        throw Exception(result['message'] ?? 'Failed to fetch admissions');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching admissions: $e');
      throw Exception('Network Error: $e');
    }
  }

  Future<void> _fetchUnseenCount() async {
    try {
      final count = await _apiService.getUnseenTreatmentCount();
      setState(() => _unseenCount = count);
    } catch (e) {
      if (kDebugMode) print('Error fetching unseen count: $e');
    }
  }

  Map<String, List<dynamic>> _filterAdmissions(List<dynamic> allAdmissions) {
    final Map<String, List<dynamic>> filtered = {
      'Requested': [],
      'Admitted': [],
      'Past': [],
      'Rejected': [],
    };

    for (var admission in allAdmissions) {
      final status = (admission['status'] as String?)?.toLowerCase();
      if (status == 'pending') {
        filtered['Requested']!.add(admission);
      } else if (status == 'admitted' || status == 'approved') {
        filtered['Admitted']!.add(admission);
      } else if (status == 'discharged' || status == 'completed') {
        filtered['Past']!.add(admission);
      } else if (status == 'rejected' || status == 'cancelled') {
        filtered['Rejected']!.add(admission);
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Row(
            children: [
              // FIX: Wrap Text in Expanded to prevent overflow on small screens
              Expanded( 
                child: const Text(
                  "Hospitalization Admissions",
                  // Consider adjusting font size if needed for better fit
                  style: TextStyle(fontSize: 18), 
                ),
              ),
              const Spacer(),
              IconButton(
                icon: badges.Badge(
                  showBadge: _unseenCount > 0,
                  badgeContent: Text(
                    '$_unseenCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.white),
                ),
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorTreatmentAnalysisScreen(),
                    ),
                  );
                  // Mark all as seen
                  await _apiService.markTreatmentAsSeen();
                  setState(() => _unseenCount = 0);
                },
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Requested"),
              Tab(text: "Admitted"),
              Tab(text: "Past"),
              Tab(text: "Rejected"),
            ],
          ),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _admissionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("No hospitalization admissions found."),
              );
            } else {
              final allAdmissions = snapshot.data!;
              final filtered = _filterAdmissions(allAdmissions);

              return TabBarView(
                children: [
                  _AdmissionListView(
                    admissions: filtered['Requested']!,
                    emptyMessage: "No pending hospitalization requests.",
                  ),
                  _AdmissionListView(
                    admissions: filtered['Admitted']!,
                    emptyMessage: "No patients are currently admitted.",
                  ),
                  _AdmissionListView(
                    admissions: filtered['Past']!,
                    emptyMessage: "No past/discharged admissions.",
                  ),
                  _AdmissionListView(
                    admissions: filtered['Rejected']!,
                    emptyMessage: "No rejected hospitalization requests.",
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}