// lib/screens/profile/aboutus.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:url_launcher/url_launcher.dart'; // Uncomment if you want to launch URLs

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  // Example function to launch URLs (requires url_launcher package)
  // Future<void> _launchURL(String url) async {
  //   if (await canLaunchUrl(Uri.parse(url))) {
  //     await launchUrl(Uri.parse(url));
  //   } else {
  //     throw 'Could not launch $url';
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2), // Consistent background
      appBar: AppBar(
        title: Text(
          'About Us',
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
        ), // Back button color
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo.png', // Replace with your app logo asset
                height: 120,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ArogyaLink: Your Health, Connected',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ArogyaLink is dedicated to revolutionizing healthcare access and management for patients. Our platform connects you seamlessly with healthcare providers, making it easier to book appointments, manage your health records, and find essential medical services nearby.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Our Mission',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To empower individuals with convenient and reliable tools to take control of their health journey, fostering a healthier and more connected community.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Contact Us',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Example of clickable links (uncomment url_launcher import to use)
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blueAccent),
              title: Text(
                'support@arogyalink.com',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              // onTap: () => _launchURL('mailto:support@arogyalink.com'),
            ),
            ListTile(
              leading: const Icon(Icons.public, color: Colors.blueAccent),
              title: Text(
                'www.arogyalink.com',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              // onTap: () => _launchURL('https://www.arogyalink.com'),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Version 1.0.0', // Your app version
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '© 2023 ArogyaLink. All rights reserved.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
