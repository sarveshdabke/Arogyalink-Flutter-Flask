// ignore_for_file: use_build_context_synchronously

import 'package:arogyalink/screens/auth/otp_screen.dart' show OtpScreen;
import 'package:arogyalink/screens/roleselection/admin/admin_login.dart';
import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String userRole; 

  const ForgotPasswordScreen({super.key, required this.userRole});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text.trim();

      try {
        final result = await ApiService().requestPasswordResetOtp(email);

        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          // Explicitly check for true
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(email: email, userRole: widget.userRole)), // Pass userRole
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("OTP sent successfully! Please check your email."),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorDialog(
            result['message']?.toString() ??
                "Failed to send OTP. Please try again.",
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

  @override
  Widget build(BuildContext context) {
    // Determine a responsive width for the container
    final screenWidth = MediaQuery.of(context).size.width;
    // Card width should be around 85-90% of screen width, but capped at 400px
    final cardWidth = screenWidth > 500 ? 400.0 : screenWidth * 0.90;
    
    // Calculate a responsive offset for the unique shadow effect
    // We use a fixed offset (40) for the height, and a factor of the remaining
    // width for the side offset to keep it visually balanced.
    final responsiveShadowX = cardWidth * 0.15; // Approx 15% of card width for offset

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
              // Use a ConstrainedBox to control the maximum width of the content
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Main Card Container (Responsive width applied via ConstrainedBox)
                    Container(
                      // Removed hardcoded width here. Now using ConstrainedBox above.
                      margin: const EdgeInsets.only(top: 35),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFADD),
                        boxShadow: [
                          BoxShadow(
                            // 💡 RESPONSIVE CHANGE: Updated offset to use calculated values
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.25),
                            offset: Offset(responsiveShadowX, 40),
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
                            const SizedBox(height: 20),
                            const Text(
                              'Forgot Password',
                              style: TextStyle(
                                fontFamily: 'Platypi',
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Email TextFormField
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: "Email Address",
                                hintText: "your@gmail.com",
                                prefixIcon: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFC8E3E9),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      bottomLeft: Radius.circular(20),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  margin: const EdgeInsets.only(right: 8.0, left: 2.0),
                                  child: const Icon(
                                    Icons.email,
                                    color: Colors.black,
                                  ),
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
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),
                            // Get OTP Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC8E3E9),
                                foregroundColor: Colors.white,
                                // 💡 RESPONSIVE CHANGE: Used double.infinity for full button width
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      "Get OTP",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            // Back to Login Button
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
                                  color: Color(0xFFA8A8A8),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 2. Icon Positioned Above the Card
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
      ),
    );
  }
}