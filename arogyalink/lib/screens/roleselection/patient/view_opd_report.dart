// ignore_for_file: library_private_types_in_public_api

import 'package:arogyalink/screens/appointment/book_appointment.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arogyalink/services/api_service.dart';

class ViewOpdReportScreen extends StatefulWidget {
  const ViewOpdReportScreen({super.key});

  @override
  _ViewOpdReportScreenState createState() => _ViewOpdReportScreenState();
}

class _ViewOpdReportScreenState extends State<ViewOpdReportScreen> {
  bool isLoading = true;
  dynamic reportData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) {
        setState(() {
          errorMessage = "Token not found. Please login again.";
          isLoading = false;
        });
        return;
      }

      var data = await ApiService().fetchOpdReport(token);

      setState(() {
        reportData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching OPD report: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My OPD Reports"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📝 Note below AppBar
                    Container(
                      width: double.infinity,
                      color: Colors.yellow.shade100,
                      padding: const EdgeInsets.all(10),
                      child: const Text(
                        "Note: Your reports will be displayed after the prescription has been generated.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    // 🩺 Report List Section
                    Expanded(
                      child: reportData is Map &&
                              reportData.containsKey("message")
                          ? Center(child: Text(reportData["message"]))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: reportData.length,
                              itemBuilder: (context, index) {
                                var appt = reportData[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // 👉 Left Content
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Appointment Date: ${appt['appointment_date']} ${appt['start_time']} - ${appt['end_time']}",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                    "Doctor: ${appt['doctor_name'] ?? appt['doctor_id']}"),
                                                Text(
                                                    "Symptoms: ${appt['symptoms']}"),
                                                const SizedBox(height: 6),
                                                Text(
                                                  "Status: ${appt['status'] ?? 'Pending'}",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                                if (appt['status']
                                                            ?.toLowerCase() ==
                                                        'referred' &&
                                                    appt['referral_reason'] !=
                                                        null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "Referral Reason: ${appt['referral_reason']}",
                                                    style: const TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                ],
                                                const SizedBox(height: 6),
                                                Text(
                                                  "Prescription Details:",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                  appt['prescription_details'] ??
                                                      "N/A",
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // 👉 Right Side Button (only if referred)
                                        if (appt['status']?.toLowerCase() ==
                                            'referred')
                                          SizedBox(
                                            width: 140,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        HospitalizationScreen(
                                                            appt: appt),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.redAccent,
                                                shape:
                                                    const RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(10.0),
                                                    bottomRight:
                                                        Radius.circular(10.0),
                                                    topLeft: Radius.zero,
                                                    bottomLeft: Radius.zero,
                                                  ),
                                                ),
                                              ),
                                              child: const RotatedBox(
                                                quarterTurns: -1,
                                                child: Text(
                                                  "Book Hospitalization",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
