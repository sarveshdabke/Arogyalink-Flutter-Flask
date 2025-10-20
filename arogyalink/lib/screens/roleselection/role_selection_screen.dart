// ignore_for_file: deprecated_member_use

import 'package:arogyalink/screens/doctors/doctor_login.dart';
import 'package:flutter/material.dart';
import 'package:arogyalink/screens/roleselection/patient/patient_login.dart';
import 'package:arogyalink/screens/roleselection/admin/admin_login.dart';
// Proper Doctor Login

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoAnimation;
  late final List<AnimationController> _cardControllers;
  late final List<Animation<Offset>> _cardAnimations;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _cardControllers = List.generate(
      3, // 3 roles: Patient, Admin, Doctor
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _cardAnimations = List.generate(
      3,
      (index) => Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero)
          .animate(
        CurvedAnimation(
          parent: _cardControllers[index],
          curve: Curves.easeOut,
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      _logoController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _cardControllers[0].forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      _cardControllers[1].forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      _cardControllers[2].forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildRoleCard(
    int index,
    String title,
    IconData icon,
    Widget destination,
  ) {
    // Wrap the card in Expanded to take equal space in the Row
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SlideTransition(
          position: _cardAnimations[index],
          child: FadeTransition(
            opacity: _logoAnimation,
            child: RoleCard(
              title: title,
              icon: icon,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => destination),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Using a light background color/gradient for a clean look
    const List<Color> backgroundGradientColors = [
      Color(0xFFE3F2FD),
      Color(0xFFE0F7FA),
      Color(0xFFF1F8E9)
    ];

    return Scaffold(
      body: Container(
        // Set a background gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: backgroundGradientColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out content
              children: [
                // 1. Top Content: Logo and Tagline
                FadeTransition(
                  opacity: _logoAnimation,
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 57, // Fixed height for a prominent logo
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your Health, our priority',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(height: 30), // Spacing after tagline
                    ],
                  ),
                ),
                
                // 2. The requested image in the middle (taking up space via Spacer)
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _logoAnimation,
                      child: FractionallySizedBox(
                        widthFactor: 0.7, // Control image size
                        child: Image.asset(
                          'assets/images/background_image.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Bottom Content: Role Cards in a Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Patient Card (Index 0)
                    _buildRoleCard(
                      0,
                      "Patient",
                      Icons.person_outline,
                      const PatientLogin(),
                    ),
                    // Doctor Card (Index 2)
                    _buildRoleCard(
                      2,
                      "Doctor",
                      Icons.medical_services_outlined,
                      const DoctorLoginScreen(),
                    ),
                    // Admin Card (Index 1)
                    _buildRoleCard(
                      1,
                      "Admin",
                      Icons.admin_panel_settings_outlined,
                      const AdminLogin(),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Add some padding at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoleCard extends StatefulWidget {
  final String title;
  final IconData icon; // Kept as part of the interface, though unused in the current build
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
  bool _isPressed = false;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    const List<Color> gradientColors = [Color(0xFFBBDEFB), Color(0xFFC8E6C9)];
    const Color defaultShadowColor = Color.fromRGBO(0, 0, 0, 0.1);
    const Color pressedShadowColor = Color.fromRGBO(30, 136, 229, 0.5);

    final List<BoxShadow> cardShadow = [
      BoxShadow(
        color: _isPressed
            ? pressedShadowColor
            : _isHovering
                ? defaultShadowColor.withOpacity(0.2)
                : defaultShadowColor,
        blurRadius: _isPressed ? 20 : _isHovering ? 15 : 10,
        spreadRadius: _isPressed ? 5 : 0,
        offset: _isPressed ? const Offset(0, 10) : const Offset(0, 5),
      ),
    ];

    return MouseRegion(
      onEnter: (event) => setState(() => _isHovering = true),
      onExit: (event) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: cardShadow,
          ),
          child: AspectRatio(
            aspectRatio: 1.0, // Retaining the square shape for design
            child: Center( // Centering the text
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center contents vertically
                  crossAxisAlignment: CrossAxisAlignment.center, // Center contents horizontally
                  children: [
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
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