// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// Make sure you have these imports for your respective screens
import 'package:arogyalink/screens/home/hospital_home_screen.dart';
import 'package:arogyalink/screens/home/patient_home_screen.dart';
import 'package:arogyalink/screens/roleselection/role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start the animation and then check login status
    _controller.forward().whenComplete(() {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userRole = prefs.getString('user_role');

    if (!mounted) {
      return;
    }

    if (isLoggedIn) {
      if (userRole == 'patient') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
        );
      } else if (userRole == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HospitalHomeScreen()),
        );
      } else {
        // Fallback for an unknown role, though ideally this case shouldn't be reached
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFBFD7FF), // Lighter blue
              Color(0xFF8BA9E6), // A slightly darker blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 200,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              // Define the shadow effect here
                              shadows: [
                                Shadow(
                                  blurRadius: 4.0,
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(2.0, 2.0),
                                ),
                              ],
                            ),
                            children: const [
                              TextSpan(
                                text: 'Arogya',
                                style: TextStyle(color: Color(0xFF2FBF3F)),
                              ),
                              TextSpan(
                                text: 'Link',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Linking You to Care, Instantly.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
