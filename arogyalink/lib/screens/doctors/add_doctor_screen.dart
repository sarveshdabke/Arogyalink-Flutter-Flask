// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    final response = await _apiService.getDoctors();

    if (response['success']) {
      setState(() {
        _doctors = response['data'] ?? []; // Assuming API returns { success, doctors: [] }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch doctors: ${response['message']}')),
      );
    }
  }

  Future<void> _addDoctorDialog() async {
    final formKey = GlobalKey<FormState>();
    String name = "", specialization = "", phone = "", email = "", password = ""; // Added password variable

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Doctor"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Name"),
                    validator: (val) => val!.isEmpty ? "Enter name" : null,
                    onSaved: (val) => name = val!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Specialization"),
                    validator: (val) => val!.isEmpty ? "Enter specialization" : null,
                    onSaved: (val) => specialization = val!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Phone"),
                    validator: (val) => val!.isEmpty ? "Enter phone" : null,
                    onSaved: (val) => phone = val!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Email"),
                    validator: (val) => val!.isEmpty ? "Enter email" : null,
                    onSaved: (val) => email = val!,
                  ),
                  // Added password TextFormField
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Password"),
                    validator: (val) => val!.isEmpty ? "Enter password" : null,
                    onSaved: (val) => password = val!,
                    obscureText: true, // Hides the entered text
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  final response = await _apiService.addDoctor(
                    name: name,
                    specialization: specialization,
                    phone: phone,
                    email: email,
                    password: password, // Pass the password here
                  );

                  if (response['success']) {
                    Navigator.pop(context);
                    _fetchDoctors(); // refresh list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Doctor added successfully!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: ${response['message']}')),
                    );
                  }
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeDoctor(String doctorId) async {
    final response = await _apiService.removeDoctor(doctorId: doctorId);
    if (response['success']) {
      _fetchDoctors();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor removed successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove: ${response['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctors"),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctors.isEmpty
              ? const Center(child: Text("No doctors available"))
              : ListView.builder(
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _doctors[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(doctor['name'] ?? ''),
                        subtitle: Text("${doctor['specialization']} • ${doctor['phone']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeDoctor(doctor['id'].toString()),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDoctorDialog,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}