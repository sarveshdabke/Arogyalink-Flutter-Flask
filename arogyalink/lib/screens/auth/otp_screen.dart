// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:arogyalink/screens/auth/update_pass.dart';
import 'package:arogyalink/screens/roleselection/admin/admin_login.dart';
import 'package:flutter/material.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String userRole;

  const OtpScreen({super.key, required this.email, required this.userRole});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final otp = _otpController.text.trim();

      try {
        // Simulate an API call for now
        await Future.delayed(const Duration(seconds: 2));
        final result = {'success': true, 'message': 'OTP verified'};

        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          // Navigate to the Update Password screen, passing the email and userRole
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UpdatePasswordScreen(
                  email: widget.email,
                  otp: otp,
                  userRole: widget.userRole), // Pass userRole
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("OTP verified successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorDialog(result['message'].toString());
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
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontFamily: 'Platypi',
                              fontSize: 40,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 50),
                          Text(
                            "A 6-digit code has been sent to ${widget.email}.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _otpController,
                            decoration: InputDecoration(
                              labelText: "OTP",
                              hintText: "Enter the code",
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
                                  Icons.lock_open,
                                  color: Colors.black, // Changed icon color to black
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide:
                                    const BorderSide(color: Colors.black, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide:
                                    const BorderSide(color: Colors.black, width: 2),
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
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the OTP';
                              }
                              if (value.length != 6) {
                                return 'OTP must be 6 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC8E3E9),
                              foregroundColor: Colors.white,
                              minimumSize:
                                  Size(MediaQuery.of(context).size.width * 0.15, 55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    "Verify",
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
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminLogin(),
                                ),
                              );
                            },
                            child: const Text(
                              "Back to Login",
                              style: TextStyle(
                                color: Colors.blueAccent,
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
                          Icons.verified_user, // Changed icon to represent OTP
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