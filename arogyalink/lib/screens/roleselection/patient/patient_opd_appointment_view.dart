// ignore_for_file: prefer_final_fields, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:intl/intl.dart';

class PatientOpdAppointmentView extends StatefulWidget {
  const PatientOpdAppointmentView({super.key});

  @override
  State<PatientOpdAppointmentView> createState() =>
      _PatientOpdAppointmentViewState();
}

class _PatientOpdAppointmentViewState extends State<PatientOpdAppointmentView> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _opdAppointmentsFuture;
  Map<String, List<dynamic>> _groupedAppointments = {};

  @override
  void initState() {
    super.initState();
    _opdAppointmentsFuture = _apiService.getOPDAppointments().then((data) {
      if (data['success'] && data['appointments'] != null) {
        final appointments = data['appointments'] as List;
        _groupedAppointments = _groupAppointmentsByDate(appointments);
        return data;
      }
      return data;
    });
  }

  Map<String, List<dynamic>> _groupAppointmentsByDate(List appointments) {
    final Map<String, List<dynamic>> grouped = {};
    for (var appointment in appointments) {
      final date = appointment['appointment_date'] ?? 'N/A';
      final parsedDate = DateTime.tryParse(date);
      final formattedDate = parsedDate != null
          ? DateFormat('EEEE, MMMM d, y').format(parsedDate)
          : date;

      if (!grouped.containsKey(formattedDate)) {
        grouped[formattedDate] = [];
      }
      grouped[formattedDate]!.add(appointment);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFADD),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 112, 147, 207),
        elevation: 4,
        title: Text(
          'My OPD Appointments',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _opdAppointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
              ),
            );
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            if (data['success'] && data['appointments'] != null) {
              final appointments = data['appointments'] as List;
              if (appointments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You have no OPD appointments booked.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700]),
                      ),
                    ],
                  ),
                );
              }

              final dates = _groupedAppointments.keys.toList();
              return DefaultTabController(
                length: dates.length,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      labelColor: const Color(0xFF4A6FA5),
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: const Color(0xFF4A6FA5),
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: dates.map((date) => Tab(text: date)).toList(),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: dates.map((date) {
                          final appointmentsForDate = _groupedAppointments[date]!;
                          return ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: appointmentsForDate.length,
                            itemBuilder: (context, index) {
                              final appointment = appointmentsForDate[index];
                              return _buildAppointmentCard(appointment);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    data['message'] ?? 'Failed to load appointments.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                  ),
                ),
              );
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final hospitalName = appointment['hospital_name'] ?? 'N/A';
    final appointmentDate = appointment['appointment_date'] ?? 'N/A';
    final startTime = appointment['start_time'] ?? 'N/A';
    final endTime = appointment['end_time'] ?? 'N/A';
    final tokenNumber = appointment['token_number']?.toString() ?? 'N/A';
    final status = appointment['status'] ?? 'N/A';
    final symptoms = appointment['symptoms'] ?? 'N/A';
    final isEmergency = appointment['is_emergency'] == true ? 'Yes' : 'No';

    final parsedDate = DateTime.tryParse(appointmentDate);
    final formattedDate = parsedDate != null
        ? DateFormat('EEEE, MMMM d, y').format(parsedDate)
        : appointmentDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏥 Hospital Name
            Row(
              children: [
                const Icon(Icons.local_hospital_outlined,
                    color: Color(0xFF4A6FA5), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hospitalName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A6FA5),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),

            // Appointment Date
            _buildAppointmentDetail(Icons.calendar_today_outlined, 'Date', formattedDate),

            // Time Slot
            _buildAppointmentDetail(Icons.access_time_outlined, 'Time', '$startTime - $endTime'),

            // Token Number
            _buildAppointmentDetail(Icons.confirmation_number_outlined, 'Token Number', tokenNumber),

            // Status
            _buildAppointmentDetail(Icons.info_outline, 'Status', status),

            // Symptoms
            _buildAppointmentDetail(Icons.sick_outlined, 'Symptoms', symptoms),

            // Emergency Flag
            _buildAppointmentDetail(Icons.warning_amber_rounded, 'Emergency', isEmergency),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentDetail(
      IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}