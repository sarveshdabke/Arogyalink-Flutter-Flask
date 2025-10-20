// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'package:arogyalink/screens/auth/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:arogyalink/screens/roleselection/patient/patient_register.dart';
import 'package:arogyalink/screens/home/patient_home_screen.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arogyalink/screens/roleselection/role_selection_screen.dart';

class PatientLogin extends StatefulWidget {
  const PatientLogin({super.key});

  @override
  State<PatientLogin> createState() => _PatientLoginState();
}

class _PatientLoginState extends State<PatientLogin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      final result = await ApiService().loginPatient(
        identifier: email,
        password: password,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('user_role', 'patient');
        await prefs.setString(
          'username',
          result['user']?['username'] ?? 'Guest',
        );

        if (result.containsKey('access_token')) {
  await prefs.setString('jwt_token', result['access_token']); // ⚡ fix key name
} else {
  _showErrorDialog("Warning: Token not received from server.");
}


        _showSnackBar("Login successful!", Colors.green);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
        );
      } else {
        _showErrorDialog(
          result['message'] ?? "Login failed. Please check your credentials.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("An error occurred: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error!"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Try again"),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFD7FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
              top: 100.0, left: 24.0, right: 24.0, bottom: 40.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildLoginCard(context),
              _buildHeaderImage(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildBackButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24.0, 90.0, 24.0, 40.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFADD), // Changed color
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 35,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
              children: [
                TextSpan(text: "Hey! Welcome To "),
                TextSpan(
                  text: "Arogya",
                  style: TextStyle(color: Color(0xFF0A8F13)),
                ),
                TextSpan(
                  text: "Link",
                  style: TextStyle(color: Color(0xFF656565)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildLoginForm(),
          const SizedBox(height: 14),
          _buildRegisterText(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 20),
          _buildLoginButton(),
          const SizedBox(height: 10), // Added a small space
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ForgotPasswordScreen(
                    userRole: 'patient', // Pass the user role
                  ),
                ),
              );
            },
            child: const Text(
              "Forgot Password?",
              style: TextStyle(
                color: Color(0xFFA8A8A8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: "Email",
        hintText: "Enter your email",
        prefixIcon: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFC8E3E9),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.all(8.0),
          margin: const EdgeInsets.only(right: 8.0, left: 2.0),
          child: const Icon(Icons.email_outlined, color: Colors.black),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
          return 'Please enter your email';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: "Password",
        hintText: "Enter your password",
        prefixIcon: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFC8E3E9),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.all(8.0),
          margin: const EdgeInsets.only(right: 8.0, left: 2.0),
          child: const Icon(Icons.lock_outline, color: Colors.black),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFFC8E3E9),
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
          return 'Please enter your password';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      // Increased the width of the login button.
      width: MediaQuery.of(context).size.width * 0.4,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC8E3E9),
          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                "Login",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildRegisterText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PatientRegister()),
            );
          },
          child: Text(
            "Register here",
            style: TextStyle(
              color: const Color(0xFFA8A8A8),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderImage() {
    return Positioned(
      top: -100,
      left: 25,
      child: Image.asset(
        'assets/images/patient_top_image.png',
        width: 150,
        height: 150,
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black87),
      onPressed: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      ),
    );
  }
}
