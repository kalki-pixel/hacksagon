import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'study_history_page.dart';
import 'home_navigation_bar.dart';

class StudyTimerPage extends StatefulWidget {
  const StudyTimerPage({super.key});

  @override
  State<StudyTimerPage> createState() => _StudyTimerPageState();
}

class _StudyTimerPageState extends State<StudyTimerPage> {
  // --- Theme Definition ---
  static const Color primaryColor = Color(0xFFFDFCF8);
  static const Color secondaryColor = Color(0xFFF0EAE3);
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF8D8478);

  final SupabaseClient _supabase = Supabase.instance.client;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  bool _isRunning = false;
  DateTime? _startTime;
  Duration _duration = Duration.zero;
  final TextEditingController _descriptionController = TextEditingController();

  Duration _totalStudyTimeToday = Duration.zero;
  int _sessionCountToday = 0;
  
  bool _isFocusMode = false;
  
  List<String> _userTasks = [];
  String? _selectedTaskForSession;

  @override
  void initState() {
    super.initState();
    _duration = const Duration(minutes: 25);
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadTodayStats(),
      _loadTasksForDropdown(),
    ]);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    try {
      final response = await _supabase.from('study_sessions').select('duration_seconds').eq('user_id', userId).gte('start_time', todayStart.toIso8601String()).lt('start_time', todayEnd.toIso8601String());
      if (mounted) {
        final totalSeconds = response.fold<int>(0, (sum, session) => sum + (session['duration_seconds'] as int));
        setState(() {
          _sessionCountToday = response.length;
          _totalStudyTimeToday = Duration(seconds: totalSeconds);
        });
      }
    } catch (e) {}
  }

  Future<void> _loadTasksForDropdown() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    List<String> tasks = [];
    try {
      final profileResponse = await _supabase.from('profiles').select('task_1, task_2, task_3, task_4').eq('id', userId).single();
      for (int i = 1; i <= 4; i++) {
        if (profileResponse['task_$i'] != null && profileResponse['task_$i'].isNotEmpty) {
          tasks.add(profileResponse['task_$i']);
        }
      }
      final taskResponse = await _supabase.from('tasks').select('task_description').eq('user_id', userId).eq('is_completed', false);
      for (var task in taskResponse) {
        tasks.add(task['task_description']);
      }
      if(mounted) {
        setState(() {
          _userTasks = tasks.toSet().toList(); // Remove duplicates
        });
      }
    } catch(e) {}
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _stopwatch.start();
      _startTime = DateTime.now();
      _duration = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() { _duration = _stopwatch.elapsed; });
      }
    });
  }

  void _stopTimer() {
    if (!_isRunning) return;
    _timer?.cancel();
    _stopwatch.stop();
    setState(() { _isRunning = false; });
    
    if (_stopwatch.elapsed.inMinutes < 1) {
      _showSessionTooShortDialog();
    } else {
      _showSaveSessionDialog();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours : $minutes : $seconds";
  }

  Future<void> _showSessionTooShortDialog() async {
     await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: primaryColor,
        title: const Text("Session Too Short", style: TextStyle(color: textColor)),
        content: const Text("Study sessions less than 1 minute are not saved.", style: TextStyle(color: secondaryTextColor)),
        actions: [
          TextButton(
            child: const Text("OK", style: TextStyle(color: textColor)),
            onPressed: () {
              _resetTimer();
              Navigator.of(context).pop();
            },
          )
        ],
      )
     );
  }

  Future<void> _showSaveSessionDialog() async {
    _descriptionController.clear();
    _selectedTaskForSession = null;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: primaryColor,
              title: const Text("Save Study Session", style: TextStyle(color: textColor)),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text("Duration: ${_formatDuration(_stopwatch.elapsed)}", style: const TextStyle(color: textColor)),
                    const SizedBox(height: 20),
                    if (_userTasks.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedTaskForSession,
                        hint: const Text("Associate with a task? (Optional)", style: TextStyle(color: secondaryTextColor)),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: secondaryColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onChanged: (String? newValue) {
                          setDialogState(() {
                            _selectedTaskForSession = newValue;
                            if(newValue != null) _descriptionController.text = newValue;
                          });
                        },
                        items: _userTasks.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: "What did you study?",
                        labelStyle: const TextStyle(color: secondaryTextColor),
                        filled: true,
                        fillColor: secondaryColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Discard", style: TextStyle(color: secondaryTextColor)),
                  onPressed: () {
                    _resetTimer();
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: textColor, foregroundColor: primaryColor),
                  child: const Text("Save"),
                  onPressed: () {
                    _saveStudySession();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveStudySession() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in.'), backgroundColor: Colors.red));
      _resetTimer();
      return;
    }
    try {
      await _supabase.from('study_sessions').insert({
        'user_id': userId,
        'start_time': _startTime!.toIso8601String(),
        'end_time': DateTime.now().toIso8601String(),
        'duration_seconds': _stopwatch.elapsed.inSeconds,
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Study session saved successfully!')));
      await _loadTodayStats();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving session: $e'), backgroundColor: Colors.red));
    } finally {
      _resetTimer();
    }
  }

  void _resetTimer() {
    _stopwatch.reset();
    _startTime = null;
    if (mounted) {
      setState(() {
        _isRunning = false;
        _duration = const Duration(minutes: 25);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFocusMode) return _buildFocusModeView();
    return _buildStandardView();
  }

  Widget _buildFocusModeView() {
    return Scaffold(
      backgroundColor: textColor,
      body: GestureDetector(
        onTap: () => setState(() => _isFocusMode = false),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isRunning ? _formatDuration(_duration) : _formatDuration(const Duration(minutes: 25)),
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 10),
              const Text("Tap anywhere to exit focus mode", style: TextStyle(color: secondaryTextColor, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardView() {
    final double progress = _isRunning ? (_duration.inSeconds % 60) / 60.0 : 1.0;
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text("Study Session", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_weak, color: textColor),
            onPressed: () => setState(() => _isFocusMode = true),
            tooltip: 'Enter Focus Mode',
          ),
          IconButton(
            icon: const Icon(Icons.history, color: textColor),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StudyHistoryPage()));
            },
            tooltip: 'View Study History',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // <-- COMMA ADDED
          children: [
            _buildStatsRow(),
            const Spacer(),
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(width: 280, height: 280, child: CircularProgressIndicator(value: progress, strokeWidth: 12, backgroundColor: secondaryColor, valueColor: const AlwaysStoppedAnimation<Color>(textColor))),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRunning ? _formatDuration(_duration) : _formatDuration(const Duration(minutes: 25)),
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("HOURS", style: TextStyle(color: secondaryTextColor)),
                          SizedBox(width: 20),
                          Text("MINUTES", style: TextStyle(color: secondaryTextColor)),
                          SizedBox(width: 20),
                          Text("SECONDS", style: TextStyle(color: secondaryTextColor)),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: ElevatedButton(
                onPressed: _isRunning ? _stopTimer : _startTimer,
                style: ElevatedButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: textColor,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(_isRunning ? "End Session" : "Start Session", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const HomeNavigationBar(activeIndex: 1),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                _formatDuration(_totalStudyTimeToday).split(' : ').join(':'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
              ),
              const Text("Time Today", style: TextStyle(color: secondaryTextColor)),
            ],
          ),
          Container(height: 40, width: 1, color: secondaryColor),
          Column(
            children: [
              Text('$_sessionCountToday', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
              const Text("Sessions Today", style: TextStyle(color: secondaryTextColor)),
            ],
          ),
        ],
      ),
    );
  }
}