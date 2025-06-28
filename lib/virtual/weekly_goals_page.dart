import 'package:checkmate/virtual/virtual_partner_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class WeeklyGoalsPage extends StatefulWidget {
  const WeeklyGoalsPage({super.key});

  @override
  State<WeeklyGoalsPage> createState() => _WeeklyGoalsPageState();
}

class _WeeklyGoalsPageState extends State<WeeklyGoalsPage> {
  // --- Theme Definition (Updated to match the new palette) ---
  static const Color primaryBackgroundColor = Color(0xFFFBF8F2); // Very light, warm off-white/cream
  static const Color cardBackgroundColor = Color(0xFFF2EFEA); // Soft, fleshy beige for cards/buttons
  static const Color primaryTextColor = Color(0xFF4A4A4A); // Darker brown or charcoal for primary text
  static const Color secondaryTextColor = Color(0xFF888888); // Lighter muted brown for secondary text
  static const Color accentColor = Color(0xFF789D86); // Muted green accent

  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _taskController = TextEditingController();
  
  List<String> _tasks = [];
  bool _isLoading = true;
  late DateTime _startOfWeek;

  @override
  void initState() {
    super.initState();
    _startOfWeek = _getStartOfWeek(DateTime.now());
    _loadWeeklyGoals();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
  
  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadWeeklyGoals() async {
    setState(() { _isLoading = true; });
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('weekly_goals')
          .select('tasks')
          .eq('user_id', userId)
          .eq('week_of', DateFormat('yyyy-MM-dd').format(_startOfWeek))
          .maybeSingle();
      
      if (mounted && response != null && response['tasks'] != null) {
        final taskData = List<Map<String, dynamic>>.from(response['tasks'] as List);
        final taskDescriptions = taskData.map((task) => task['description'] as String).toList();
        setState(() {
          _tasks = taskDescriptions;
        });
      }
    } catch (e) {
      _showError('An unexpected error occurred during loading: $e');
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _addTask() {
    final taskText = _taskController.text.trim();
    if (taskText.isNotEmpty) {
      setState(() {
        _tasks.add(taskText);
      });
      _taskController.clear();
    }
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }
  
  Future<void> _saveAndProceed() async {
    if (_tasks.isEmpty) {
      _showError("Please add at least one task for the week.");
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showError("Your session has expired. Please log in again.");
      return;
    }

    setState(() { _isLoading = true; });
    try {
      final structuredTasks = _tasks.map((taskDescription) {
        return {'description': taskDescription, 'is_completed': false};
      }).toList();
      
      await _supabase.from('weekly_goals').upsert({
        'user_id': user.id,
        'week_of': DateFormat('yyyy-MM-dd').format(_startOfWeek),
        'tasks': structuredTasks,
      }, onConflict: 'user_id, week_of');
      
      await _supabase
          .from('profiles')
          .update({'partner_type': 'virtual'})
          .eq('id', user.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly plan saved! Let\'s get started.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VirtualPartnerPage()),
        );
      }
    } catch (e) {
      _showError('Failed to save weekly plan: $e');
    } finally {
     if(mounted) {
      setState(() { _isLoading = false; });
    }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackgroundColor, // Apply primary background color
      // --- Themed AppBar ---
      appBar: AppBar(
        title: Text(
          "Plan for Week of ${DateFormat.yMMMd().format(_startOfWeek)}",
          style: const TextStyle(
            color: primaryTextColor, // Updated title color
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto', // Sans-serif font
          ),
        ),
        backgroundColor: primaryBackgroundColor, // App bar background matches page background
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryTextColor), // Back arrow color
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor)) // Loading indicator with accent color
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "Set your key tasks for this week. Your virtual partner will share these goals.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: secondaryTextColor, fontFamily: 'Roboto'), // Text color and font
                  ),
                  const SizedBox(height: 20),
                  // --- Themed Input Field and Button ---
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskController,
                          cursorColor: accentColor, // Cursor color
                          style: const TextStyle(color: primaryTextColor, fontFamily: 'Roboto'), // Input text color and font
                          decoration: InputDecoration(
                            hintText: 'Add a new weekly task',
                            hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.7), fontFamily: 'Roboto'), // Hint text style
                            filled: true,
                            fillColor: cardBackgroundColor, // Input field background color
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12), // Rounded corners for input fields
                              borderSide: BorderSide.none, // No border line
                            ),
                            enabledBorder: OutlineInputBorder( // Ensure consistent border when enabled
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder( // Accent border when focused
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: accentColor, width: 2),
                            ),
                          ),
                          onSubmitted: (_) => _addTask(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container( // Wrap IconButton in a Container for consistent sizing and background
                        decoration: BoxDecoration(
                          color: cardBackgroundColor, // Background color for the add button
                          borderRadius: BorderRadius.circular(12), // Match text field corner radius
                          boxShadow: [ // Subtle shadow
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add_circle, size: 30), // Slightly smaller icon to fit container
                          onPressed: _addTask,
                          style: IconButton.styleFrom(
                            foregroundColor: primaryTextColor, // Icon color
                            padding: const EdgeInsets.all(10), // Padding to make the button a decent size
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _tasks.isEmpty
                        ? Center(child: Text("No tasks added for this week yet.", style: TextStyle(color: secondaryTextColor, fontFamily: 'Roboto'))) // Text color and font
                        : ListView.builder(
                            itemCount: _tasks.length,
                            itemBuilder: (context, index) {
                              // --- Themed Task List Tile ---
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6), // Increased vertical margin for spacing
                                decoration: BoxDecoration(
                                  color: cardBackgroundColor, // Card background color
                                  borderRadius: BorderRadius.circular(12), // Rounded corners
                                  boxShadow: [ // Subtle shadow for card effect
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: primaryBackgroundColor, // Avatar background color
                                    child: Text('${index + 1}', style: const TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold, fontFamily: 'Roboto')), // Text color and font
                                  ),
                                  title: Text(_tasks[index], style: const TextStyle(color: primaryTextColor, fontFamily: 'Roboto')), // Text color and font
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent), // Kept red for delete action clarity
                                    onPressed: () => _removeTask(index),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  // --- Themed Primary Action Button ---
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Start Week with Partner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTextColor, // Darker brown/charcoal for button background
                      foregroundColor: primaryBackgroundColor, // Text and icon color on button is light background
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Roboto'), // Sans-serif and bold
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Fully rounded button
                      ),
                      elevation: 0, // Flat design
                    ),
                    onPressed: _isLoading ? null : _saveAndProceed,
                  ),
                ],
              ),
            ),
    );
  }
}