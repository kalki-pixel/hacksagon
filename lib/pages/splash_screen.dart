import 'package:checkmate/auth/auth_gate.dart'; // Ensure this path is correct
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  static const Color primaryColor = Color.fromARGB(255, 252, 253, 248); // Background color

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Total duration for both fade-in and fade-out
      vsync: this,
    );

    // Define the fade-in and fade-out curves
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn), // Fade in during the first half
      ),
    );

    // Add a listener to control the fade-out
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // After fade-in completes, reverse the animation for fade-out
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        // After fade-out completes, navigate to AuthGate
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AuthGate()),
          );
        }
      }
    });

    _controller.forward(); // Start the fade-in animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 252, 248),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SizedBox(
            width: 200,
            height: 200,
            child: Image.asset(
              'assets/logo.png', // Make sure your logo is at this path
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    'STRIVE',
                    style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}