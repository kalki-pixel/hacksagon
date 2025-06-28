import 'package:checkmate/auth/auth_gate.dart';
import 'package:checkmate/auth/auth_service.dart';
import 'package:checkmate/pages/register_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  void login() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      await authService.signInWithEmailPassword(email, password);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
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
    // Define colors from the new design for a consistent theme
    const Color primaryColor = Color(0xFFFDFCF8); // Background color
    const Color secondaryColor = Color(0xFFF0EAE3); // Textfield and button color
    const Color textColor = Color(0xFF333333); // Text color

    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // "STRIVE" title from the new design
                const Text(
                  "STRIVE",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 60),

                // Themed Email Text Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Email",
                    filled: true,
                    fillColor: secondaryColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                ),

                const SizedBox(height: 16),

                // Themed Password Text Field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    filled: true,
                    fillColor: secondaryColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                ),

                const SizedBox(height: 24),

                // Themed Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: textColor,     // Dark background
                    foregroundColor: primaryColor,  // Light foreground (text & spinner)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: primaryColor, // Themed spinner
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "Log in",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Themed Sign up link
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  ),
                  child: const Center(
                    child: Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(
                        color: textColor,
                      ),
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