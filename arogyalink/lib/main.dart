import 'package:flutter/material.dart';
// Corrected import path for SplashScreen
import 'package:arogyalink/screens/splash/splash_screen.dart'; // Make sure 'arogyalink' matches your project name

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ArogyaLink',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Roboto', // Optional: Use your preferred font
      ),
      home: const SplashScreen(),
    );
  }
}
