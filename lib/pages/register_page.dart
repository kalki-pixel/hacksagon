import 'package:checkmate/auth/auth_gate.dart';
import 'package:checkmate/auth/auth_service.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // --- Feature: Added loading state for better UX ---
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Feature: Sign-up logic with loading state management ---
  void signUp() async {
    if (_isLoading) return;

    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Passwords don't match")));
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await authService.signUpWithEmailPassword(email, password);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Theme: Colors and styles to match the rest of the app ---
    const Color primaryColor = Color(0xFFFDFCF8);
    const Color secondaryColor = Color(0xFFF0EAE3);
    const Color textColor = Color(0xFF333333);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: secondaryColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      labelStyle: const TextStyle(color: textColor),
    );

    return Scaffold(
      backgroundColor: primaryColor,
      // --- Theme: Styled AppBar ---
      appBar: AppBar(
        title: const Text(
          "Sign Up",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Themed Email Text Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: inputDecoration.copyWith(labelText: "Email"),
            ),
            const SizedBox(height: 16),
            // Themed Password Text Field
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: inputDecoration.copyWith(labelText: "Password"),
            ),
            const SizedBox(height: 16),
            // Themed Confirm Password Text Field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: inputDecoration.copyWith(labelText: "Confirm Password"),
            ),
            const SizedBox(height: 24),
            // Themed Sign Up Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: textColor,
                foregroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : signUp,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
                    )
                  : const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}