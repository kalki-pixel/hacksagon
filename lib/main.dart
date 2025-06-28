import 'package:checkmate/pages/splash_screen.dart'; // Import the new splash screen
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- IMPORTANT ---
  // Replace with your actual Supabase URL and Anon Key
  await Supabase.initialize(
    url: 'https://wsxnzuiinwzsmccsrovn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndzeG56dWlpbnd6c21jY3Nyb3ZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjczMjQsImV4cCI6MjA2NjEwMzMyNH0.v3iToGQIWJ4-bnzY7yoByQHncV5YrBRtzlM8cjEuh7A',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checkmate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF333333)),
        useMaterial3: true,
      ),
      // --- This line sets the splash screen as the first page ---
      home: const SplashScreen(),
    );
  }
}