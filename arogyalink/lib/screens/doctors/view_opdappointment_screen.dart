// ignore_for_file: use_build_context_synchronously

import 'package:arogyalink/screens/doctors/doctor_hospitalizations_screen.dart';
import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';

class ViewOPDAppointmentScreen extends StatefulWidget {
  final String token;
  const ViewOPDAppointmentScreen({super.key, required this.token});

  @override
  State<ViewOPDAppointmentScreen> createState() =>
      _ViewOPDAppointmentScreenState();
}

class _ViewOPDAppointmentScreenState extends State<ViewOPDAppointmentScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> appointments = {};
  bool isLoading = true;
  late TabController tabController;

  // 🔹 Badge count for unseen hospitalizations
  int unseenCount = 0;

  @override
  void initState() {
    super.initState();
    loadAppointments();
    loadUnseenCount(); // Load badge count
  }

  Future<void> loadAppointments() async {
    setState(() => isLoading = true);
    try {
      final apiService = ApiService();
      final data = await apiService.getDoctorAppointments(widget.token);
      setState(() {
        appointments = data;
        isLoading = false;
      });

      // Initialize TabController after appointments are loaded
      final dates = appointments.keys.toList()..sort();
      final today = DateTime.now();
      final todayStr =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      int initialIndex = dates.indexOf(todayStr);
      if (initialIndex == -1) initialIndex = 0;

      tabController = TabController(
        length: dates.length,
        vsync: this,
        initialIndex: initialIndex,
      );
    } catch (e) {
      print("Error fetching appointments: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> loadUnseenCount() async {
    final api = ApiService();
    final count = await api.getUnseenAdmissionsCount();
    setState(() {
      unseenCount = count;
    });
  }

  Future<void> updateAppointmentStatus(int appointmentId, String status,
      {String? referralReason}) async {
    try {
      final api = ApiService();
      await api.updateAppointmentStatus(
        widget.token,
        appointmentId,
        status,
        referralReason: referralReason,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment marked as $status')),
      );
      loadAppointments(); // refresh after status update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update appointment: $e')),
      );
    }
  }

  void showActionSheet(Map<String, dynamic> appt) {
    if (appt['status'] == 'Completed' ||
        appt['status'] == 'Cancelled' ||
        appt['status'] == 'Referred') {
      return; // no action if already handled
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Mark Complete'),
            onTap: () {
              updateAppointmentStatus(appt['id'], 'Completed');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('Cancel Appointment'),
            onTap: () {
              updateAppointmentStatus(appt['id'], 'Cancelled');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_hospital, color: Colors.blue),
            title: const Text('Refer Patient'),
            onTap: () {
              Navigator.pop(context);
              showReferralDialog(appt['id']);
            },
          ),
        ],
      ),
    );
  }

  void showReferralDialog(int appointmentId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Referral Reason"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: "Enter reason for referral",
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                updateAppointmentStatus(
                  appointmentId,
                  'Referred',
                  referralReason: reason,
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reason is required")),
                );
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dates = appointments.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Appointments"),
        bottom: TabBar(
          controller: tabController,
          isScrollable: true,
          tabs: dates.map((d) => Tab(text: d)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final today = DateTime.now();
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: today,
                firstDate: DateTime(2023, 1),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );

              if (pickedDate != null) {
                final pickedStr =
                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                if (appointments.containsKey(pickedStr)) {
                  final index = dates.indexOf(pickedStr);
                  if (index != -1) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      tabController.animateTo(index);
                    });
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("No appointments on selected date")),
                  );
                }
              }
            },
          ),
          // 🔹 Bed icon with badge
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.bed),
                if (unseenCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unseenCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              // Navigate to doctor hospitalizations screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DoctorHospitalizationsScreen(token: widget.token),
                ),
              );

              // 🔹 Mark all as seen after opening
              final api = ApiService();
              await api.markAdmissionsSeen();
              setState(() {
                unseenCount = 0;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Instructional banner
          Container(
            width: double.infinity,
            color: Colors.yellow[100],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: const Text(
              "ℹ️ Double-tap or long-press on a card to update appointment status.",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 🔹 TabBarView with appointments
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: dates.map((date) {
                final appts = List<Map<String, dynamic>>.from(appointments[date]);
                appts.sort((a, b) =>
                    (a['token_number'] ?? 0).compareTo(b['token_number'] ?? 0));

                return ListView.builder(
                  itemCount: appts.length,
                  itemBuilder: (context, index) {
                    final appt = appts[index];
                    return GestureDetector(
                      onLongPress: () => showActionSheet(appt),
                      onDoubleTap: () => showActionSheet(appt),
                      child: Card(
                        margin: const EdgeInsets.all(8.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appt['patient_name'] ?? "Unknown",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                  "Age: ${appt['patient_age'] ?? '-'} | Gender: ${appt['gender'] ?? '-'}"),
                              Text(
                                  "Contact: ${appt['patient_contact'] ?? '-'} | Email: ${appt['patient_email'] ?? '-'}"),
                              Text(
                                  "Time: ${appt['start_time'] ?? '-'} - ${appt['end_time'] ?? '-'}"),
                              Text("Symptoms: ${appt['symptoms'] ?? '-'}"),
                              Text("Token No: ${appt['token_number'] ?? '-'}"),
                              Text("Status: ${appt['status'] ?? '-'}"),
                              if (appt['referral_reason'] != null &&
                                  appt['referral_reason'].toString().isNotEmpty)
                                Text("Referral Reason: ${appt['referral_reason']}"),
                              if (appt['is_emergency'] ?? false)
                                const Text(
                                  "⚠️ Emergency",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }
}
