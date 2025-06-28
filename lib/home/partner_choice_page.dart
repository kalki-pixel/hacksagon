import 'package:checkmate/home/home_navigation_bar.dart';
import 'package:checkmate/real/study_partner_page.dart';
import 'package:checkmate/virtual/weekly_goals_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerChoicePage extends StatefulWidget {
  const PartnerChoicePage({super.key});

  @override
  State<PartnerChoicePage> createState() => _PartnerChoicePageState();
}

class _PartnerChoicePageState extends State<PartnerChoicePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // --- Theme Definition ---
  static const Color primaryColor = Color(0xFFFDFCF8);
  static const Color secondaryColor = Color(0xFFF0EAE3);
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF8D8478);

  // --- Feature: Robust function to handle virtual partner selection ---
  Future<void> _selectPartnerType(String type, VoidCallback onSuccess) async {
    setState(() { _isLoading = true; });
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase
          .from('profiles')
          .update({'partner_type': type})
          .eq('id', userId);
      
      if(mounted) onSuccess();

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating partner type: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- Theme: Themed background and AppBar ---
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text('Find a Partner', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const HomeNavigationBar(activeIndex: 3),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: textColor))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Feature: Themed card with real partner logic ---
                  _buildChoiceCard(
                    icon: Icons.people_alt_rounded,
                    title: 'Find a Real Partner',
                    subtitle: 'Match with another user who shares your goal.',
                    onTap: () => _selectPartnerType('real', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const StudyPartnerPage()));
                    }),
                  ),
                  const SizedBox(height: 24),
                  // --- Feature: Themed card with virtual partner logic ---
                  _buildChoiceCard(
                    icon: Icons.smart_toy_rounded,
                    title: 'Chat with a Virtual Partner',
                    subtitle: 'Get motivation from an AI partner available 24/7.',
                    onTap: () => _selectPartnerType('virtual', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const WeeklyGoalsPage()));
                    }),
                  ),
                ],
              ),
            ),
    );
  }

  // --- Theme & Feature: A single, beautifully styled card widget ---
  Widget _buildChoiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 60, color: textColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }
}