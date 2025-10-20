// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:arogyalink/screens/home/hospital_home_screen.dart';
import 'package:arogyalink/screens/roleselection/admin/admin_register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arogyalink/screens/roleselection/role_selection_screen.dart';
import 'package:arogyalink/screens/auth/forgot_password_screen.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _identifierFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _identifierFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final identifier = _identifierController.text.trim();
      final password = _passwordController.text.trim();

      try {
        // Assuming ApiService().loginAdmin is correctly implemented
        final result = await ApiService().loginAdmin(
          identifier: identifier,
          password: password,
        );

        print('API response result: $result'); // debug line
        setState(() => _isLoading = false);

        if (result['success']) {
          final String status = result['user']?['status'] ?? 'pending';
          final bool isApproved = status.toLowerCase() == 'approved';

          if (isApproved) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString(
              'admin_username',
              result['user']?['username'] ?? 'Admin',
            );
            await prefs.setString('admin_token', result['token'] ?? '');
            await prefs.setString('user_role', 'admin');

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Admin login successful!"),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pushReplacement( 
              context,
              MaterialPageRoute(builder: (context) => HospitalHomeScreen()),
            );

          } else if (status.toLowerCase() == 'pending') {
            _showErrorDialog(
              "Your account is pending approval by a super admin.",
            );
          } else if (status.toLowerCase() == 'rejected') {
            _showErrorDialog(
              "Your account registration request has been rejected.",
            );
          } else {
            _showErrorDialog("Invalid account status: $status");
          }
        } else {
          _showErrorDialog(result['message'] ?? "Login failed.");
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog("An error occurred: $e");
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

  // A new helper widget to build text fields with consistent styling
  Widget _buildTextField(TextEditingController controller, String labelText,
      IconData icon, FocusNode focusNode,
      {bool obscureText = false,
      TextInputType keyboardType = TextInputType.text,
      Widget? suffixIcon}) { 
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: focusNode.hasFocus ? Colors.teal.shade600 : Colors.grey,
        ),
        prefixIcon: Icon(
          icon,
          color: focusNode.hasFocus ? Colors.teal.shade600 : Colors.grey,
        ),
        suffixIcon: suffixIcon, 
        border: InputBorder.none,
        // Vertical padding reduced to save space
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12, // 16 se 12 kar diya gaya hai
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $labelText';
        }
        return null;
      },
      // Added error style adjustment to minimize vertical space on validation error
      // Note: This needs to be outside the InputDecoration for the TextField
      style: TextStyle(height: 1.0), // Adjust text style
      // The validator return text's style can be adjusted in InputDecoration if needed:
      // errorStyle: TextStyle(fontSize: 12, height: 0.8), 
    );
  }

  // Helper widget to wrap fields with the desired styling
  Widget _buildOutlinedFieldContainer({required Widget child}) {
    // Vertical padding ko aur kam kiya gaya hai taki jagah bache
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), 
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFBFD7FF),
      // To prevent the body from resizing when the keyboard appears, 
      // set resizeToAvoidBottomInset to true (which is the default, but good to know)
      // or false if you want to handle the space yourself.
      // We are relying on SingleChildScrollView, so the default is fine.
      
      appBar: AppBar(
        backgroundColor: const Color(0xFFBFD7FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RoleSelectionScreen(),
              ),
            );
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFBFD7FF),
          ),
        ),
      ),
      // *******************************************************************
      // FIX: Wrap the entire content area with SingleChildScrollView
      // *******************************************************************
      body: SingleChildScrollView(
        // This ensures the content can scroll when the keyboard is up
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding( 
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // mainAxisAlignment.start is good here
              mainAxisAlignment: MainAxisAlignment.start, 
              children: [
                // Image size
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0.0, bottom: 8.0), 
                    child: Image.asset(
                      'assets/images/adminregister.png',
                      height: screenSize.height * 0.15, 
                    ),
                  ),
                ),
                
                // Header Container
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 10), 
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.black, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Admin Login",
                      style: TextStyle(
                        fontFamily: 'Platypi Regular',
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16), 

                // Login form fields
                _buildOutlinedFieldContainer(
                  child: _buildTextField(
                    _identifierController,
                    "Email",
                    Icons.email,
                    _identifierFocus,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),

                _buildOutlinedFieldContainer(
                  child: _buildTextField(
                    _passwordController,
                    "Password",
                    Icons.lock,
                    _passwordFocus,
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: _passwordFocus.hasFocus
                            ? Colors.teal.shade600
                            : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                
                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0), 
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(
                              userRole: 'admin',
                            ), 
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16), 

                // Login button
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      )
                    : SizedBox(
                        height: 45, 
                        child: ElevatedButton(
                          onPressed: _submitLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            shadowColor: Colors.teal.shade200,
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                
                // Added a consistent space instead of Spacer()
                const SizedBox(height: 24),

                // Register now link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminRegisterPage(),
                          ),
                        );
                      },
                      child: Text(
                        "Register now",
                        style: TextStyle(
                          color: Colors.teal.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}