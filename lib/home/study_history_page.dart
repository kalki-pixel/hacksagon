import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:checkmate/home/home_navigation_bar.dart';

class StudyHistoryPage extends StatefulWidget {
  const StudyHistoryPage({super.key});

  @override
  State<StudyHistoryPage> createState() => _StudyHistoryPageState();
}

class _StudyHistoryPageState extends State<StudyHistoryPage> {
  // --- Theme Definition ---
  static const Color primaryColor = Color(0xFFFDFCF8);
  static const Color secondaryColor = Color(0xFFF0EAE3);
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF8D8478);
  
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _studySessions = [];
  bool _isLoading = true;
  // --- Feature: State for toggling view ---
  bool _viewByMonth = false;

  @override
  void initState() {
    super.initState();
    _fetchStudySessions();
  }

  Future<void> _fetchStudySessions() async {
    setState(() { _isLoading = true; });
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in.');

      final List<Map<String, dynamic>> data = await _supabase
          .from('study_sessions')
          .select('*')
          .eq('user_id', userId)
          .order('start_time', ascending: false);

      if (mounted) {
        setState(() { _studySessions = data; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching study history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
  
  String _formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secs = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${hours}h ${minutes}m";
    } else if (duration.inMinutes > 0) {
      return "${minutes}m ${secs}s";
    } else {
      return "${secs}s";
    }
  }

  // --- Feature: Grouping logic for both daily and monthly views ---
  Map<String, List<Map<String, dynamic>>> _groupSessionsByDay() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var session in _studySessions) {
      final DateTime startTime = DateTime.parse(session['start_time']);
      final String dateKey = DateFormat('yyyy-MM-dd').format(startTime);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(session);
    }
    return grouped;
  }

  Map<String, List<Map<String, dynamic>>> _groupSessionsByMonth() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var session in _studySessions) {
      final DateTime startTime = DateTime.parse(session['start_time']);
      final String monthKey = DateFormat('yyyy-MM').format(startTime);
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(session);
    }
    return grouped;
  }

  int _getTotalDurationForGroup(List<Map<String, dynamic>> sessions) {
    return sessions.fold(0, (sum, session) => sum + (session['duration_seconds'] as int));
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> groupedSessions = 
      _viewByMonth ? _groupSessionsByMonth() : _groupSessionsByDay();
    
    final sortedKeys = groupedSessions.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      // --- Theme: Themed background and AppBar ---
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text("Study History", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        // --- Feature: Themed toggle switch in AppBar ---
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              _viewByMonth ? "Monthly" : "Daily",
              style: const TextStyle(fontSize: 14, color: secondaryTextColor),
            ),
          ),
          Switch(
            value: _viewByMonth,
            onChanged: (value) {
              setState(() { _viewByMonth = value; });
            },
            activeTrackColor: textColor.withOpacity(0.5),
            activeColor: textColor,
            inactiveThumbColor: secondaryTextColor,
            inactiveTrackColor: secondaryColor,
          ),
        ],
      ),
      bottomNavigationBar: const HomeNavigationBar(activeIndex: 1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: textColor))
          : _studySessions.isEmpty
              ? const Center(child: Text("No study sessions recorded yet.", style: TextStyle(color: secondaryTextColor)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final String groupKey = sortedKeys[index];
                    final List<Map<String, dynamic>> sessionsInGroup = groupedSessions[groupKey]!;
                    final int totalDuration = _getTotalDurationForGroup(sessionsInGroup);

                    String formattedHeading;
                    if (_viewByMonth) {
                      formattedHeading = DateFormat.yMMMM().format(DateTime.parse('$groupKey-01'));
                    } else {
                      formattedHeading = DateFormat('EEEE, MMMM d, y').format(DateTime.parse(groupKey));
                    }

                    return Card(
                      // --- Theme: Themed card design ---
                      elevation: 0,
                      color: secondaryColor,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$formattedHeading (${_formatDuration(totalDuration)})",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const Divider(height: 20, color: primaryColor),
                            ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: sessionsInGroup.length,
                              itemBuilder: (context, sessionIndex) {
                                final session = sessionsInGroup[sessionIndex];
                                final sessionStartTime = DateFormat.jm().format(DateTime.parse(session['start_time']));
                                final sessionDuration = _formatDuration(session['duration_seconds']);
                                final sessionDescription = session['description'] ?? 'No description provided.';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "• $sessionStartTime ($sessionDuration)",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                                        child: Text(
                                          sessionDescription,
                                          style: const TextStyle(fontSize: 14, color: secondaryTextColor, fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}