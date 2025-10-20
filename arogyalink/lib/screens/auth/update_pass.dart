// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:arogyalink/screens/roleselection/admin/admin_login.dart';
import 'package:arogyalink/screens/roleselection/patient/patient_login.dart';
import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';

class UpdatePasswordScreen extends StatefulWidget {
  final String email;
  final String otp;
  final String userRole;

  const UpdatePasswordScreen({
    super.key,
    required this.email,
    required this.otp,
    required this.userRole,
  });

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final newPassword = _passwordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      if (newPassword != confirmPassword) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog("Passwords do not match.");
        return;
      }

      try {
        final result = await _apiService.updatePassword(
          email: widget.email,
          otp: widget.otp,
          newPassword: newPassword,
        );

        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          _showSuccessDialog(
            result['message'] ?? 'Password updated successfully!',
          );
        } else {
          _showErrorDialog(
            result['message'] ?? 'Failed to update password. Please try again.',
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog("An error occurred: $e");
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                if (widget.userRole == 'patient') {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const PatientLogin()),
                    (Route<dynamic> route) => false,
                  );
                } else if (widget.userRole == 'admin') {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AdminLogin()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFD7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.blueGrey,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    margin: const EdgeInsets.only(top: 35),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFADD),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          offset: const Offset(80, 40),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Update Password',
                            style: TextStyle(
                              fontFamily: 'Platypi',
                              fontSize: 40,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 50),
                          Text(
                            "Enter your new password for ${widget.email}.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: "New Password",
                              hintText: "Enter new password",
                              prefixIcon: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC8E3E9),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                ),
                                padding: const EdgeInsets.all(8.0),
                                margin: const EdgeInsets.only(right: 8.0, left: 2.0), // Shifted to the right
                                child: const Icon(
                                  Icons.lock,
                                  color: Colors.black, // Changed icon color to black
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: const Color(0xFFC8E3E9),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.black, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.black, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.blueAccent,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              labelStyle: const TextStyle(color: Colors.blueGrey),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a new password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            decoration: InputDecoration(
                              labelText: "Confirm Password",
                              hintText: "Re-enter new password",
                              prefixIcon: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC8E3E9),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                ),
                                padding: const EdgeInsets.all(8.0),
                                margin: const EdgeInsets.only(right: 8.0, left: 2.0), // Shifted to the right
                                child: const Icon(
                                  Icons.lock,
                                  color: Colors.black, // Changed icon color to black
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: const Color(0xFFC8E3E9),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.black, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.black, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.blueAccent,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              labelStyle: const TextStyle(color: Colors.blueGrey),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _updatePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC8E3E9),
                              foregroundColor: Colors.white,
                              minimumSize: Size(MediaQuery.of(context).size.width * 0.15, 55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    "Update Password",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black, // Changed text color to black
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              if (widget.userRole == 'patient') {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PatientLogin(),
                                  ),
                                );
                              } else if (widget.userRole == 'admin') {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminLogin(),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              "Back to Login",
                              style: TextStyle(
                                color: Color(0xFFA8A8A8),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4F4CA7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.key,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}