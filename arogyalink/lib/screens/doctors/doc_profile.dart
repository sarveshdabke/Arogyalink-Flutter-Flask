// C:\Users\Main\arogyalink\lib\screens\doctors\doc_profile.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class DoctorProfileScreen extends StatelessWidget {
  final Map<String, dynamic> doctorData;

  const DoctorProfileScreen({super.key, required this.doctorData});

  @override
  Widget build(BuildContext context) {
    // Determine the primary data points for the profile
    final String name = doctorData['name'] ?? 'Not available';
    final String specialization =
        doctorData['specialization'] ?? 'Not available';

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Light background for the body
      appBar: AppBar(
        title: const Text(
          'Doctor Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2), // A deep blue color
        iconTheme: const IconThemeData(color: Colors.white), // Ensure back arrow is white
        elevation: 0, // Remove shadow
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section (Simulating a banner/header)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 20, top: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1976D2),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Profile Picture/Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'DR',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Name and Specialization
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    specialization,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            // Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Contact Details Card
                  _buildProfileCard(
                    context,
                    title: 'Contact Information',
                    children: [
                      _buildProfileDetail(
                          icon: Icons.email,
                          label: 'Email',
                          value: doctorData['email']),
                      _buildProfileDetail(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: doctorData['phone']),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Professional Details Card
                  _buildProfileCard(
                    context,
                    title: 'Professional Details',
                    children: [
                      _buildProfileDetail(
                          icon: Icons.local_hospital,
                          label: 'Hospital',
                          value: doctorData['hospital_name']),
                      _buildProfileDetail(
                          icon: Icons.person_pin_circle,
                          label: 'Specialization',
                          value: doctorData['specialization']),
                      // You can add more professional details like experience, degrees, etc.
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build a card section
  Widget _buildProfileCard(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  // Helper function to build a single detail row
  Widget _buildProfileDetail(
      {required IconData icon, required String label, dynamic value}) {
    final String displayValue = value?.toString() ?? 'Not available';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}