import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:checkmate/home/home_navigation_bar.dart';

// Define custom colors based on the new description
const Color primaryBackgroundColor = Color(0xFFFBF8F2); 
const Color cardBackgroundColor = Color(0xFFF2EFEA); 
const Color primaryTextColor = Color(0xFF4A4A4A); // Darker brown or charcoal for primary text
const Color secondaryTextColor = Color(0xFF888888); // Lighter muted brown for secondary text
const Color accentColor = Color(0xFF789D86); // Keeping the previous accent green for progress indicator for consistency, as no new accent was explicitly given for progress.

class AnalyticsPartnerPage extends StatefulWidget {
  const AnalyticsPartnerPage({super.key});

  @override
  State<AnalyticsPartnerPage> createState() => _AnalyticsPartnerPageState();
}

class _AnalyticsPartnerPageState extends State<AnalyticsPartnerPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _errorMessage;

  // State for the selected week and the data
  late DateTime _selectedMonday;
  Map<String, dynamic>? _efficiencyData;

  @override
  void initState() {
    super.initState();
    // Initialize to the Monday of the current week
    _selectedMonday =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    _fetchEfficiencyData();
  }

  /// Fetches efficiency data by calling the database function
  Future<void> _fetchEfficiencyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser!.id;
      final weekString = DateFormat('yyyy-MM-dd').format(_selectedMonday);

      final data = await _supabase.rpc('calculate_weekly_efficiency', params: {
        'p_user_id': userId,
        'p_week_of': weekString,
      });

      if (mounted) {
        setState(() {
          _efficiencyData = data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Could not load analytics data.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeWeek(int days) {
    setState(() {
      _selectedMonday = _selectedMonday.add(Duration(days: days));
    });
    _fetchEfficiencyData();
  }

  @override
  Widget build(BuildContext context) {
    final endOfWeek = _selectedMonday.add(const Duration(days: 6));
    final weekDisplayFormat = DateFormat('MMM d');
    final weekString =
        "${weekDisplayFormat.format(_selectedMonday)} - ${weekDisplayFormat.format(endOfWeek)}";

    return Scaffold(
      backgroundColor: primaryBackgroundColor, // Applied primary background color
      appBar: AppBar(
        title: const Text(
          'My Weekly Analytics',
          style: TextStyle(
            color: primaryTextColor, // App bar title color
            fontFamily: 'Roboto', // Assuming 'Roboto' or similar for sans-serif
            fontWeight: FontWeight.bold, // Bold for headings
          ),
        ),
        backgroundColor: primaryBackgroundColor, // App bar background color
        iconTheme: const IconThemeData(color: primaryTextColor), // App bar icon color
        elevation: 0, // No shadow under app bar
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor)) // Loading indicator color
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: primaryTextColor))) // Error message color
              : SingleChildScrollView(
                  // Added SingleChildScrollView for better responsiveness on smaller screens if content grows
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, // Ensures children are centered horizontally
                      children: [
                        // Week Selector UI
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                          decoration: BoxDecoration(
                            color: cardBackgroundColor, // Card background for week selector
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: primaryTextColor), // Icon color
                                onPressed: () => _changeWeek(-7),
                              ),
                              Text(
                                weekString,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: primaryTextColor, // Text color
                                      fontFamily: 'Roboto', // Sans-serif font
                                      fontWeight: FontWeight.bold, // Bold for dates/headings
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, color: primaryTextColor), // Icon color
                                onPressed: () => _changeWeek(7),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32), // Increased spacing
                        // --- NEW WIDGET: Partner Comparison ---
                        _buildPartnerComparisonCard(),
                        const SizedBox(height: 32),
                        // --- NEW WIDGET: Daily Breakdown Chart ---
                        _buildDailyBreakdownChart(),
                        const SizedBox(height: 32),
                        // --- NEW WIDGET: Accomplishments Section ---
                        _buildAccomplishmentsSection(),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: const HomeNavigationBar(activeIndex: 2), // Assuming this widget handles its own theming
    );
  }

  // --- NEW WIDGET: Partner Comparison View ---
  // This widget uses mock data for the partner's efficiency.
  Widget _buildPartnerComparisonCard() {
    final myEfficiency = _efficiencyData?['efficiency']?.toDouble() ?? 0.0;
    // --- Mock Data: Replace with your actual partner data ---
    final partnerEfficiency = 0.65; // Example partner efficiency
    // --- End Mock Data ---

    return _buildSectionCard(
      title: 'Partner Comparison',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniGauge('You', myEfficiency),
          _buildMiniGauge('Partner', partnerEfficiency),
        ],
      ),
    );
  }

  Widget _buildMiniGauge(String title, double value) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 60.0,
          lineWidth: 12.0,
          percent: value,
          center: Text(
            "${(value * 100).toStringAsFixed(0)}%",
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
              fontFamily: 'Roboto',
            ),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: accentColor,
          backgroundColor: accentColor.withOpacity(0.2),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: secondaryTextColor,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }

  // --- NEW WIDGET: Daily Breakdown Chart ---
  // This widget uses mock data to display tasks completed each day.
  Widget _buildDailyBreakdownChart() {
    // --- Mock Data: Replace with your actual daily data ---
    final dailyTasks = [3, 5, 2, 4, 1, 6, 3]; // Mon, Tue, Wed...
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    // --- End Mock Data ---
    
    final double maxTasks = dailyTasks.reduce((a, b) => a > b ? a : b).toDouble();

    return _buildSectionCard(
      title: 'Daily Breakdown',
      child: SizedBox(
        height: 150,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            final barHeight = dailyTasks[index] > 0
                ? (dailyTasks[index] / maxTasks) * 120
                : 0.0;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: barHeight,
                  width: 25,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(days[index], style: const TextStyle(color: secondaryTextColor, fontFamily: 'Roboto')),
              ],
            );
          }),
        ),
      ),
    );
  }

  // --- NEW WIDGET: Accomplishments Section ---
  // This section uses mock data.
  Widget _buildAccomplishmentsSection() {
     // --- Mock Data: Replace with your actual data ---
    const currentStreak = "5 days";
    const busiestDay = "Tuesday";
    // --- End Mock Data ---
    
    return Row(
      children: [
        _buildInfoCard("Current Streak", currentStreak, Icons.local_fire_department_rounded),
        const SizedBox(width: 20),
        _buildInfoCard("Busiest Day", busiestDay, Icons.calendar_today_rounded),
      ],
    );
  }
  
  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Expanded(
      child: _buildSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: accentColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: secondaryTextColor, fontFamily: 'Roboto'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor, fontFamily: 'Roboto'),
                  ),
                ],
              ),
            ),
          ],
        ), title: '',
      ),
    );
  }


  // --- Helper widget to create a consistent card shell ---
  Widget _buildSectionCard({required String title, required Widget child, EdgeInsets? padding}) {
     return Card(
      color: cardBackgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
   // Original stat card widget, now only used inside the _buildAccomplishmentsSection
   Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Card(
        color: cardBackgroundColor, // Card background color
        elevation: 0, // Flat design as in screenshot
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Rounded corners
        ),
        child: Container(
          // Wrap with Container to add box shadow
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0), // Increased padding for more spacing
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor, // Secondary text color
                    fontFamily: 'Roboto', // Sans-serif font
                  ),
                ),
                const SizedBox(height: 10), // Increased spacing
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 36, // Slightly larger font size for value
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor, // Primary text color
                    fontFamily: 'Roboto', // Sans-serif font
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