import 'package:checkmate/pages/login_page.dart';
import 'package:checkmate/pages/profile_page.dart';
import 'package:checkmate/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _hasProfile(String userId) async {
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', userId);

      debugPrint('Profile check response for $userId: $response');

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error in _hasProfile check: $e');
      return false; // fail-safe: treat as no profile
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          final userId = session.user.id;

          return FutureBuilder<bool>(
            future: _hasProfile(userId),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (profileSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      'Error loading profile status:\n${profileSnapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              }

              final profileExists = profileSnapshot.data ?? false;

              return profileExists
                  ? const HomePage()
                  : const ProfilePage(); // or OnboardingPage()
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
