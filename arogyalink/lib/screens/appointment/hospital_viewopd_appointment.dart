import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:arogyalink/services/api_service.dart';

class HospitalViewOpdAppointmentScreen extends StatefulWidget {
  const HospitalViewOpdAppointmentScreen({super.key});

  @override
  State<HospitalViewOpdAppointmentScreen> createState() =>
      _HospitalViewOpdAppointmentScreenState();
}

class _HospitalViewOpdAppointmentScreenState
    extends State<HospitalViewOpdAppointmentScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _appointments = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
    });

    final response = await ApiService().getOpdAppointmentsForHospital();

    if (response['success'] == true) {
      setState(() {
        _appointments = response['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = response['message'] ?? "Failed to load appointments.";
      });
    }
  }

  List<dynamic> _filterAppointments(String type) {
    final today = DateTime.now();
    final dateFormat = DateFormat("yyyy-MM-dd");

    return _appointments.where((appt) {
      final apptDate = DateTime.tryParse(appt['appointment_date'].toString());
      if (apptDate == null) return false;

      final apptDay = dateFormat.format(apptDate);
      final todayDay = dateFormat.format(today);

      if (type == "today") {
        return apptDay == todayDay;
      } else if (type == "upcoming") {
        return apptDate.isAfter(today);
      } else if (type == "past") {
        return apptDate.isBefore(today);
      }
      return false;
    }).toList();
  }

  Widget _buildAppointmentCard(dynamic appt) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(
          "${appt['patient_name']} (Token: ${appt['token_number']})",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Doctor: ${appt['doctor_name']}"),
            Text("Date: ${appt['appointment_date']}"),
            Text("Time: ${appt['start_time']} - ${appt['end_time']}"),
            Text("Status: ${appt['status']}"),
            Text("Symptoms: ${appt['symptoms']}"),
          ],
        ),
        trailing: Icon(
          appt['is_emergency'] == true
              ? Icons.warning
              : Icons.medical_services,
          color: appt['is_emergency'] == true ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hospital OPD Appointments"),
        backgroundColor: Colors.blueAccent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Today"),
            Tab(text: "Upcoming"),
            Tab(text: "Past"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Today
                    _filterAppointments("today").isEmpty
                        ? const Center(child: Text("No appointments today."))
                        : ListView(
                            children: _filterAppointments("today")
                                .map((appt) => _buildAppointmentCard(appt))
                                .toList(),
                          ),

                    // Upcoming
                    _filterAppointments("upcoming").isEmpty
                        ? const Center(
                            child: Text("No upcoming appointments."),
                          )
                        : ListView(
                            children: _filterAppointments("upcoming")
                                .map((appt) => _buildAppointmentCard(appt))
                                .toList(),
                          ),

                    // Past
                    _filterAppointments("past").isEmpty
                        ? const Center(
                            child: Text("No past appointments."),
                          )
                        : ListView(
                            children: _filterAppointments("past")
                                .map((appt) => _buildAppointmentCard(appt))
                                .toList(),
                          ),
                  ],
                ),
    );
  }
}