// lib/screens/doctors/health_records_screen.dart

import 'package:flutter/material.dart';

class HealthRecordsScreen extends StatelessWidget {
  const HealthRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records'),
        backgroundColor: Colors.blueAccent,
      ),
      body: const Center(
        child: Text(
          'Health Records Screen Content',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}