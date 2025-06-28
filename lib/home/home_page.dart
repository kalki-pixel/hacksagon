import 'dart:math';
import 'package:checkmate/auth/auth_service.dart';
import 'package:checkmate/home/study_timer_page.dart';
import 'package:checkmate/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:checkmate/home/home_navigation_bar.dart';
import 'package:checkmate/home/drawer_menu.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _newTaskController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _newTaskFocusNode = FocusNode();

  List<Map<String, dynamic>> _userTasks = [];
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  // Data for dynamic cards
  final List<Map<String, String>> _quotes = const [
    {"quote": "The secret of getting ahead is getting started.", "author": "Mark Twain"},
    {"quote": "The only way to do great work is to love what you do.", "author": "Steve Jobs"},
    {"quote": "Believe you can and you're halfway there.", "author": "Theodore Roosevelt"},
    {"quote": "Strive for progress, not perfection.", "author": "Anonymous"},
  ];

  final List<String> _studyTips = const [
    "Use the Pomodoro Technique: 25 minutes of focused study followed by a 5-minute break.",
    "Actively recall information instead of passively rereading it.",
    "Teach what you've learned to someone else to solidify your understanding.",
    "Get enough sleep; it's crucial for memory consolidation.",
  ];

  final List<String> _doodleAssets = const [
    'assets/doodles/doodle1.png.jpg',
    'assets/doodles/doodle2.png.jpg',
    'assets/doodles/doodle3.png.jpg',
    'assets/doodles/doodle5 (1).png',
    'assets/doodles/doodle5 (2).png',
    'assets/doodles/doodle5 (3).png',
    'assets/doodles/doodle5 (4).png',
    'assets/doodles/doodle5 (5).png',
  ];

  int _quoteIndex = 0;
  int _tipIndex = 0;
  int _doodleIndex = 0;

  // Consistent App Theme
  static const Color primaryColor = Color(0xFFFDFCF8);
  static const Color secondaryColor = Color(0xFFF0EAE3);
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF8D8478);
  static final Color progressColor = Colors.teal.shade600;


  @override
  void initState() {
    super.initState();
    _quoteIndex = Random().nextInt(_quotes.length);
    _tipIndex = Random().nextInt(_studyTips.length);
    if (_doodleAssets.isNotEmpty) {
      _doodleIndex = Random().nextInt(_doodleAssets.length);
    }
    
    _loadUserData();
    _newTaskFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _newTaskController.dispose();
    _scrollController.dispose();
    _newTaskFocusNode.removeListener(_onFocusChange);
    _newTaskFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_newTaskFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  bool _isSameDay(DateTime? date1, DateTime date2) {
    if (date1 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    await Future.wait([
      _getProfileDailyTasks(),
      _getTasks(),
    ]);
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _getProfileDailyTasks() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      // Fetches all necessary data for the new cards
      final response = await _supabase
          .from('profiles')
          .select('name, avatar_url, goal, deadline, partner_type, task_1, task_2, task_3, task_4, task_1_last_completed_date, task_2_last_completed_date, task_3_last_completed_date, task_4_last_completed_date')
          .eq('id', userId)
          .single();
      if (mounted) {
        setState(() {
          _userProfile = response;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading profile data: ${e.toString()}')));
      }
    }
  }

  Future<void> _markDailyTaskCompleted(int taskIndex) async {
    final userId = _supabase.auth.currentUser!.id;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    String columnName = 'task_${taskIndex}_last_completed_date';
    try {
      await _supabase.from('profiles').update({
        columnName: today,
      }).eq('id', userId);
      await _getProfileDailyTasks();
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error marking daily task: ${e.toString()}')));
      }
    }
  }

  Future<void> _getTasks() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final List<Map<String, dynamic>> tasks = await _supabase
          .from('tasks')
          .select('*')
          .eq('user_id', userId)
          .eq('is_completed', false)
          .order('created_at', ascending: true);
      if (mounted) {
        setState(() { _userTasks = tasks; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading tasks: ${e.toString()}')));
      }
    }
  }

  Future<void> _addTask() async {
    if (_newTaskController.text.trim().isEmpty) return;

    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('tasks').insert({
        'user_id': userId,
        'task_description': _newTaskController.text.trim(),
        'is_completed': false,
      });
      _newTaskController.clear();
      _newTaskFocusNode.unfocus();
      await _getTasks();
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding task: ${e.toString()}')));
      }
    }
  }

  Future<void> _toggleAndRemoveTask(String taskId) async {
    try {
      await _supabase.from('tasks').update({'is_completed': true}).eq('id', taskId);
      await _getTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task completed!')),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating task: ${e.toString()}')));
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
      await _getTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task permanently deleted!')),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting task: ${e.toString()}')));
      }
    }
  }
  
  void _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: primaryColor,
        body: Center(child: CircularProgressIndicator(color: textColor)),
      );
    }

    final List<Map<String, dynamic>> dailyTasksWithStatus = [];
    if (_userProfile != null) {
      for (int i = 1; i <= 4; i++) {
        String taskKey = 'task_$i';
        String dateKey = 'task_${i}_last_completed_date';
        String? taskDescription = _userProfile![taskKey];
        String? lastCompletedDateStr = _userProfile![dateKey];

        if (taskDescription != null && taskDescription.isNotEmpty) {
          DateTime? lastCompletedDate;
          if (lastCompletedDateStr != null) {
            lastCompletedDate = DateTime.tryParse(lastCompletedDateStr);
          }
          bool isCompletedToday = _isSameDay(lastCompletedDate, DateTime.now());
          dailyTasksWithStatus.add({
            'index': i,
            'description': taskDescription,
            'is_completed_today': isCompletedToday,
          });
        }
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text("Study Buddy", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
      drawer: DrawerMenu(userProfile: _userProfile, onLogout: _logout),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- WIDGETS REORDERED AS PER YOUR REQUEST ---
            const SizedBox(height: 16),
            _buildWeeklyActivityCard(),
            const SizedBox(height: 16),
            _buildDoodleCard(),
            const SizedBox(height: 16),
            _buildQuoteCard(),
            const SizedBox(height: 16),
            if (dailyTasksWithStatus.isNotEmpty) ...[
              _buildTodayProgressCard(dailyTasksWithStatus),
              const SizedBox(height: 16),
            ],
            if (_userProfile?['deadline'] != null) ...[
              _buildDeadlineCard(),
              const SizedBox(height: 16),
            ],
            // The rest of the widgets
            _buildPartnerCard(),
            const SizedBox(height: 16),
            _buildFocusCard(),
            const SizedBox(height: 16),
            _buildTipCard(),
            // --- END OF REORDERED WIDGETS ---
            const SizedBox(height: 24),
            const Text("Upcoming Tasks", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),
            if (dailyTasksWithStatus.isNotEmpty)
              ...dailyTasksWithStatus.map((taskData) {
                return _buildTaskItem(
                  title: taskData['description'],
                  isCompleted: taskData['is_completed_today'],
                  onChanged: (value) {
                          if (value == true) {
                            _markDailyTaskCompleted(taskData['index']);
                          }
                        },
                );
              }),
            if (_userTasks.isNotEmpty)
              ..._userTasks.map((task) {
                return _buildTaskItem(
                  title: task['task_description'],
                  isCompleted: task['is_completed'],
                  onChanged: (value) {
                    if (value == true) {
                      _toggleAndRemoveTask(task['id']);
                    }
                  },
                  onDelete: () => _deleteTask(task['id']),
                );
              }),
            if (_userTasks.isEmpty && dailyTasksWithStatus.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text("No tasks for today. Add one below!", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _newTaskController,
              focusNode: _newTaskFocusNode,
              decoration: InputDecoration(
                hintText: "Add a new task...",
                filled: true,
                fillColor: secondaryColor,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: textColor, size: 30),
                  onPressed: _addTask,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _addTask(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const HomeNavigationBar(activeIndex: 0),
    );
  }

  Widget _buildWeeklyActivityCard() {
    DateTime getStartOfWeek(DateTime date) => date.subtract(Duration(days: date.weekday - 1));
    final startOfWeek = getStartOfWeek(DateTime.now());
    Set<int> completedDays = {};
    if (_userProfile != null) {
      for (int i = 1; i <= 4; i++) {
        final dateStr = _userProfile!['task${i}_last_completed_date'];
        if (dateStr != null) {
          final completedDate = DateTime.parse(dateStr);
          if (!completedDate.isBefore(startOfWeek) && completedDate.isBefore(startOfWeek.add(const Duration(days: 7)))) {
            completedDays.add(completedDate.weekday);
          }
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("This Week's Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final dayInitial = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
              final isCompleted = completedDays.contains(index + 1);
              return Column(
                children: [
                  Text(dayInitial, style: const TextStyle(color: secondaryTextColor, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: isCompleted ? progressColor : primaryColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isCompleted ? Colors.transparent : secondaryColor, width: 2)
                    ),
                  )
                ],
              );
            }),
          )
        ],
      )
    );
  }

  Widget _buildPartnerCard() {
    final partnerType = _userProfile?['partner_type'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(partnerType == 'virtual' ? Icons.computer : Icons.people_outline, color: textColor, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Partner Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                Text(partnerType == 'virtual' ? "Virtual partner is active." : "Find a study partner to boost accountability.", style: const TextStyle(color: secondaryTextColor)),
              ],
            ),
          ),
           if (partnerType != 'virtual')
            const Icon(Icons.arrow_forward_ios, color: secondaryTextColor, size: 16)
        ],
      ),
    );
  }

  Widget _buildTodayProgressCard(List<Map<String, dynamic>> dailyTasks) {
    final completedCount = dailyTasks.where((task) => task['is_completed_today']).length;
    final totalCount = dailyTasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          SizedBox(
            height: 80, width: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: primaryColor,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
                Center(child: Text("${(progress * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)))
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                Text("$completedCount of $totalCount daily tasks completed", style: const TextStyle(color: secondaryTextColor)),
              ],
            )
          )
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    final tip = _studyTips[_tipIndex];
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: secondaryTextColor, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tip of the Day", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                Text(tip, style: const TextStyle(color: secondaryTextColor)),
              ],
            ),
          )
        ],
      )
    );
  }

  Widget _buildDoodleCard() {
    if (_doodleAssets.isEmpty) return const SizedBox.shrink();
    final doodleAssetPath = _doodleAssets[_doodleIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Focus Doodle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              doodleAssetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text('Doodle not found!', style: TextStyle(color: secondaryTextColor)));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineCard() {
    final deadline = DateTime.parse(_userProfile!['deadline']);
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    final goal = _userProfile!['goal'] ?? 'your goal';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, color: textColor, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${daysLeft > 0 ? daysLeft : 0} days left", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                Text("Until you reach your goal: $goal", style: const TextStyle(color: secondaryTextColor)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFocusCard() {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const StudyTimerPage()));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: textColor, borderRadius: BorderRadius.circular(12)),
        child: const Row(
          children: [
            Icon(Icons.center_focus_strong_outlined, color: primaryColor, size: 40),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Start a Focus Session", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                  Text("Enter a distraction-free timer to get work done.", style: TextStyle(color: secondaryColor)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: primaryColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard() {
    final quote = _quotes[_quoteIndex];
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote, color: secondaryTextColor),
          const SizedBox(height: 8),
          Text(quote['quote']!, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: textColor)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text("- ${quote['author']!}", style: const TextStyle(fontWeight: FontWeight.bold, color: secondaryTextColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem({
    required String title,
    required bool isCompleted,
    required ValueChanged<bool?>? onChanged,
    VoidCallback? onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onChanged != null) {
              onChanged(!isCompleted);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              children: [
                Checkbox(
                  value: isCompleted,
                  onChanged: onChanged,
                  activeColor: textColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 16, color: isCompleted ? Colors.grey[600] : textColor, decoration: isCompleted ? TextDecoration.lineThrough : null),
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}