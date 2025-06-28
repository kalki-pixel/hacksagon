import 'package:checkmate/home/home_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Define custom colors based on the new description, replacing the old AppTheme
const Color primaryBackgroundColor = Color(0xFFFBF8F2); // Very light, warm off-white/cream
const Color cardBackgroundColor = Color(0xFFF2EFEA); // Soft, fleshy beige for cards/buttons
const Color primaryTextColor = Color(0xFF4A4A4A); // Darker brown or charcoal for primary text
const Color secondaryTextColor = Color(0xFF888888); // Lighter muted brown for secondary text
const Color accentColor = Color(0xFF789D86); // Muted green accent
const Color errorColor = Colors.red; // Keeping standard red for error visibility
const Color efficiencyMediumColor = Color(0xFFE69A8D); // A slightly muted orange/red for medium efficiency
const Color efficiencyBadColor = Color(0xFFCC5E5E); // A stronger red for bad efficiency
const double cardRadius = 12.0; // Consistent card radius

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() { _isLoading = true; });
    try {
      final monthString = DateFormat('yyyy-MM').format(_selectedMonth);
      final data = await _supabase.rpc(
        'get_monthly_analytics',
        params: {'p_month': monthString},
      );
      if (mounted) {
        setState(() {
          _analyticsData = data as Map<String, dynamic>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error fetching analytics: $e'),
              backgroundColor: errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: accentColor, // Calendar header/selected date color
              onPrimary: primaryBackgroundColor, // Text color on primary color
              surface: primaryBackgroundColor, // Background of the date picker dialog
              onSurface: primaryTextColor, // Text color on the surface
            ),
            dialogBackgroundColor: primaryBackgroundColor, // Dialog background itself
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryTextColor, // Color of month/year buttons
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null &&
        (picked.year != _selectedMonth.year ||
            picked.month != _selectedMonth.month)) {
      setState(() {
        _selectedMonth = picked;
      });
      _fetchAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Monthly Report",
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto', // Sans-serif font
          ),
        ),
        backgroundColor: primaryBackgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: primaryTextColor),
            onPressed: () => _selectMonth(context),
            tooltip: 'Select Month',
          )
        ],
      ),
      bottomNavigationBar: const HomeNavigationBar(activeIndex: 2),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    DateFormat.yMMMM().format(_selectedMonth),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                          fontFamily: 'Roboto', // Sans-serif font
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildSummaryCard(), // This is functional
                  
                  // --- NON-FUNCTIONAL WIDGETS REMOVED ---
                  
                  if (_analyticsData != null && _analyticsData!['efficiency'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        _analyticsData!['efficiency'] >= 0.75
                            ? 'Excellent focus this month. Keep up the great work!'
                            : (_analyticsData!['efficiency'] >= 0.4
                                ? 'Good progress. A little more consistency could make a big difference.'
                                : 'Let\'s build a stronger study routine for next month.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: _analyticsData!['efficiency'] >= 0.75
                              ? accentColor
                              : secondaryTextColor,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    // This widget is functional as it uses the fetched _analyticsData
    final efficiency = _analyticsData?['efficiency']?.toDouble() ?? 0.0;
    final completed = _analyticsData?['completed_tasks'] ?? 0;
    final total = _analyticsData?['total_tasks'] ?? 0;
    final Color progressColor = efficiency >= 0.75
        ? accentColor
        : (efficiency >= 0.4
            ? efficiencyMediumColor
            : efficiencyBadColor);

    return Card(
      color: cardBackgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius)),
      child: Container(
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(cardRadius),
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
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: efficiency,
                      strokeWidth: 12,
                      backgroundColor: primaryBackgroundColor,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                    Center(
                      child: Text(
                        "${(efficiency * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                            fontFamily: 'Roboto'
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Task Efficiency",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                            fontFamily: 'Roboto'
                            )),
                    const SizedBox(height: 12),
                    Text("Completed: $completed",
                        style: const TextStyle(
                            fontSize: 16,
                            color: secondaryTextColor,
                            fontFamily: 'Roboto'
                            )),
                    Text("Planned: $total",
                        style: const TextStyle(
                            fontSize: 16,
                            color: secondaryTextColor,
                            fontFamily: 'Roboto'
                            )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}