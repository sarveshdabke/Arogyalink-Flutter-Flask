import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';

class HospitalProfileScreen extends StatefulWidget {
  final int hospitalId;

  const HospitalProfileScreen({super.key, required this.hospitalId});

  @override
  State<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> {
  Map<String, dynamic>? hospitalData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHospitalProfile();
  }

  Future<void> fetchHospitalProfile() async {
    try {
      // ApiService ka instance create karke method call
      var data = await ApiService().getHospitalProfile(
        widget.hospitalId.toString(),
      );

      setState(() {
        hospitalData = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching hospital profile: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hospital Profile")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hospitalData == null
          ? const Center(child: Text("Hospital data not found"))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospitalData!['hospital_name'] ?? "No name",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("Type: ${hospitalData!['hospital_type'] ?? 'N/A'}"),
                  const SizedBox(height: 8),
                  Text("Owner: ${hospitalData!['owner_name'] ?? 'N/A'}"),
                  const SizedBox(height: 8),
                  Text("Contact: ${hospitalData!['contact'] ?? 'N/A'}"),
                  const SizedBox(height: 8),
                  Text("Address: ${hospitalData!['address'] ?? 'N/A'}"),
                  const SizedBox(height: 8),
                  Text(
                    "Available Beds: ${hospitalData!['available_beds']?.toString() ?? '0'}",
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ICU Beds: ${hospitalData!['icu_beds']?.toString() ?? '0'}",
                  ),
                ],
              ),
            ),
    );
  }
}
