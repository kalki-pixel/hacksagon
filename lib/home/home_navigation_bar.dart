import 'package:checkmate/home/analytics_dashboard_page.dart';
import 'package:checkmate/home/home_page.dart';
import 'package:checkmate/home/partner_choice_page.dart';
import 'package:checkmate/home/study_timer_page.dart';
import 'package:checkmate/partner/partner_dashboard_page.dart';
import 'package:checkmate/analytics/analytics_partner_page.dart';
import 'package:checkmate/virtual/virtual_partner_page.dart';
import 'package:checkmate/virtual/weekly_goals_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HomeNavigationBar extends StatefulWidget {
  final int activeIndex;

  const HomeNavigationBar({
    super.key,
    required this.activeIndex,
  });

  @override
  State<HomeNavigationBar> createState() => _HomeNavigationBarState();
}

class _HomeNavigationBarState extends State<HomeNavigationBar> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isNavigating = false;

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // --- NEW: Robust analytics navigation logic ---
  Future<void> _handleAnalyticsNavigation() async {
    if (_isNavigating) return;
    setState(() { _isNavigating = true; });

    Widget destinationPage = const AnalyticsDashboardPage();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final profileResponse = await _supabase
            .from('profiles')
            .select('partner_id')
            .eq('id', userId)
            .maybeSingle();

        if (profileResponse != null && profileResponse['partner_id'] != null) {
          destinationPage = const AnalyticsPartnerPage();
        }
      }
    } catch (e) {
      // Fallback to default analytics page on error
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => destinationPage,
          transitionDuration: Duration.zero,
        ),
      );
    }
    if (mounted) {
      setState(() { _isNavigating = false; });
    }
  }

  // --- UPDATED: Partner navigation combines robust checks with original goal logic ---
  Future<void> _handlePartnerNavigation() async {
    if (_isNavigating) return;
    setState(() { _isNavigating = true; });

    Widget destinationPage = const PartnerChoicePage();

    try {
      final userId = _supabase.auth.currentUser!.id;
      final profileResponse = await _supabase
          .from('profiles')
          .select('partner_type, partner_id')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse != null) {
        final partnerType = profileResponse['partner_type'];
        final partnerId = profileResponse['partner_id'];

        if (partnerType == 'virtual') {
          // Re-integrated the weekly goal check from the original file
          final startOfWeek = _getStartOfWeek(DateTime.now());
          final weekString = DateFormat('yyyy-MM-dd').format(startOfWeek);
          final weeklyGoalResponse = await _supabase
              .from('weekly_goals')
              .select('id')
              .eq('user_id', userId)
              .eq('week_of', weekString)
              .maybeSingle();

          destinationPage = weeklyGoalResponse != null
              ? const VirtualPartnerPage()
              : const WeeklyGoalsPage();
        } else {
          destinationPage = partnerId != null
              ? const PartnerDashboardPage()
              : const PartnerChoicePage();
        }
      }
    } catch (e) {
      // Fallback to partner choice on error
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => destinationPage,
          transitionDuration: Duration.zero,
        ),
      );
    }
    if (mounted) {
      setState(() { _isNavigating = false; });
    }
  }

  // --- UPDATED: Taps now call the new handler functions ---
  void _onItemTapped(int index) {
    if (index == widget.activeIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context, PageRouteBuilder(pageBuilder: (_, __, ___) => const HomePage(), transitionDuration: Duration.zero));
        break;
      case 1:
        Navigator.pushReplacement(context,
            PageRouteBuilder(pageBuilder: (_, __, ___) => const StudyTimerPage(), transitionDuration: Duration.zero));
        break;
      case 2:
        _handleAnalyticsNavigation();
        break;
      case 3:
        _handlePartnerNavigation();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- The original, beautiful theme is preserved ---
    const Color primaryColor = Color(0xFFFDFCF8);
    const Color textColor = Color(0xFF333333);

    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.center_focus_strong_outlined),
          activeIcon: Icon(Icons.center_focus_strong),
          label: 'Focus',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'Statistics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group_outlined),
          activeIcon: Icon(Icons.group),
          label: 'Partner',
        ),
      ],
      currentIndex: widget.activeIndex,
      backgroundColor: primaryColor,
      selectedItemColor: textColor,
      unselectedItemColor: Colors.grey[400],
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    );
  }
}