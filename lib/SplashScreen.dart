import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart'; // Import the LoginPage here

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Function to navigate to LoginPage after the splash screen
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  // Delay function for splash screen
  _navigateToLogin() async {
    await Future.delayed(const Duration(
        seconds: 3)); // Adjust the splash screen duration as needed

    // Using WidgetsBinding to ensure context is valid before navigating
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const LoginPage()), // Navigate to LoginPage instead of HomePage
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your logo here
            Image.asset('images/CT.png',
                width: 150, height: 150), // Update the logo path as needed
            const SizedBox(height: 20),
            const Text(
              "CampusTalk",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
