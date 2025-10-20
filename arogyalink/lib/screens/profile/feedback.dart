// lib/screens/profile/feedback.dart

// ignore_for_file: avoid_print, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:flutter/foundation.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();
  String? _feedbackType;

  final List<String> _feedbackTypes = [
    'Suggestion',
    'Complaint',
    'Appreciation',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending your feedback...'),
          backgroundColor: Colors.blue,
        ),
      );

      try {
        final apiService = ApiService();
        final response = await apiService.sendFeedback(
          feedbackType: _feedbackType ?? 'Not specified',
          feedbackText: _messageController.text,
        );

        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.green,
            ),
          );
          // Clear the form on success
          _messageController.clear();
          setState(() {
            _feedbackType = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print("Exception during feedback submission: $e");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double containerOverlap = 40.0;
    const double topImageHeight = 300.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: Text(
          'Feedback',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: Stack(
        children: [
          Positioned(
  top: 0,
  left: 0,
  right: 0,
  child: SizedBox(
    width: double.infinity,
    height: MediaQuery.of(context).size.height * 0.3, // responsive height
    child: FittedBox(
      fit: BoxFit.contain, // ensures full image is visible, no cropping
      child: Image.asset(
        'assets/images/feedback_top.png',
      ),
    ),
  ),
),

          Positioned(
            top: topImageHeight - containerOverlap,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBFD7FF),
                    borderRadius: BorderRadius.circular(180),
                    border: Border.all(
                      color: const Color(0xFFBFD7FF),
                      width: 6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You swiped right!')),
                        );
                      } else if (details.primaryVelocity! < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You swiped left!')),
                        );
                      }
                    },
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: 80,
                            width: 80,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            '💬 We’d love to hear from you!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Your feedback helps us improve Arogyalink and deliver a better healthcare experience. Whether it’s a suggestion, an issue you faced, or appreciation for a feature you liked – we value your input.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _feedbackType,
                            hint: Text(
                              'Select Feedback Type',
                              style: GoogleFonts.poppins(),
                            ),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _feedbackTypes.map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type, style: GoogleFonts.poppins()),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _feedbackType = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a feedback type';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _messageController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Write your feedback here...',
                              hintStyle: GoogleFonts.poppins(),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your feedback';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: SizedBox(
                              width: 200,
                              child: ElevatedButton(
                                onPressed: _submitFeedback,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E88E5),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Submit Feedback',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
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
          ),
        ],
      ),
    );
  }
}