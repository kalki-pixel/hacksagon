import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Define custom colors based on the screenshot theme for consistency
const Color primaryBackgroundColor = Color(0xFFFBF8F2); // Very light, warm off-white/cream
const Color cardBackgroundColor = Color(0xFFF2EFEA); // Soft, fleshy beige for cards/buttons
const Color primaryTextColor = Color(0xFF4A4A4A); // Darker brown or charcoal for primary text
const Color secondaryTextColor = Color(0xFF888888); // Lighter muted brown for secondary text
const Color accentColor = Color(0xFF789D86); // Muted green accent

class WeeklyTasksPage extends StatefulWidget {
  const WeeklyTasksPage({super.key});

  @override
  State<WeeklyTasksPage> createState() => _WeeklyTasksPageState();
}

class _WeeklyTasksPageState extends State<WeeklyTasksPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  final _task1Controller = TextEditingController();
  final _task2Controller = TextEditingController();
  final _task3Controller = TextEditingController();
  final _task4Controller = TextEditingController();
  final _task5Controller = TextEditingController();
  final _task6Controller = TextEditingController();
  final _task7Controller = TextEditingController();
  final _task8Controller = TextEditingController();

  late final String _weekOf;

  @override
  void initState() {
    super.initState();
    _calculateWeekString();
    _loadCurrentWeekTasks();
  }
  
  void _calculateWeekString() {
    final now = DateTime.now();
    // Monday is weekday 1, Sunday is 7.
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    _weekOf = DateFormat('yyyy-MM-dd').format(startOfWeek);
  }

  Future<void> _loadCurrentWeekTasks() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('weekly_tasks')
          .select()
          .eq('user_id', userId)
          .eq('week_of', _weekOf)
          .maybeSingle();

      if (response != null && mounted) {
        _task1Controller.text = response['task_1'] ?? '';
        _task2Controller.text = response['task_2'] ?? '';
        _task3Controller.text = response['task_3'] ?? '';
        _task4Controller.text = response['task_4'] ?? '';
        _task5Controller.text = response['task_5'] ?? '';
        _task6Controller.text = response['task_6'] ?? '';
        _task7Controller.text = response['task_7'] ?? '';
        _task8Controller.text = response['task_8'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Error loading existing tasks'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _saveWeeklyTasks() async {
    setState(() { _isLoading = true; });
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // --- THIS IS THE CORRECTED UPSERT CALL ---
      await _supabase.from('weekly_tasks').upsert(
        {
          'user_id': userId,
          'week_of': _weekOf,
          'task_1': _task1Controller.text,
          'task_2': _task2Controller.text,
          'task_3': _task3Controller.text,
          'task_4': _task4Controller.text,
          'task_5': _task5Controller.text,
          'task_6': _task6Controller.text,
          'task_7': _task7Controller.text,
          'task_8': _task8Controller.text,
        },
        // This tells Supabase to check for conflicts on the user_id and week_of columns
        onConflict: 'user_id, week_of',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Weekly tasks saved successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error saving tasks: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _task1Controller.dispose();
    _task2Controller.dispose();
    _task3Controller.dispose();
    _task4Controller.dispose();
    _task5Controller.dispose();
    _task6Controller.dispose();
    _task7Controller.dispose();
    _task8Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackgroundColor, // Apply primary background color
      appBar: AppBar(
        backgroundColor: primaryBackgroundColor, // App bar background matches page background
        elevation: 0, // No shadow under app bar
        title: const Text(
          'Set Weekly Tasks',
          style: TextStyle(
            color: primaryTextColor, // Darker brown/charcoal for title
            fontFamily: 'Roboto', // Sans-serif font
            fontWeight: FontWeight.bold, // Bold for headings
          ),
        ),
        centerTitle: true, // Center the title
        iconTheme: const IconThemeData(color: primaryTextColor), // Back arrow color
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor)) // Loading indicator with accent color
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Tasks for the week of ${DateFormat.yMMMMd().format(DateTime.parse(_weekOf))}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: primaryTextColor, // Updated text color
                    fontFamily: 'Roboto', // Sans-serif font
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildTaskTextField(_task1Controller, 'Task 1'),
                _buildTaskTextField(_task2Controller, 'Task 2'),
                _buildTaskTextField(_task3Controller, 'Task 3'),
                _buildTaskTextField(_task4Controller, 'Task 4'),
                _buildTaskTextField(_task5Controller, 'Task 5'),
                _buildTaskTextField(_task6Controller, 'Task 6'),
                _buildTaskTextField(_task7Controller, 'Task 7'),
                _buildTaskTextField(_task8Controller, 'Task 8'),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveWeeklyTasks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTextColor, // Darker brown/charcoal for button background
                    foregroundColor: primaryBackgroundColor, // Text color on button is light background
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontFamily: 'Roboto', fontWeight: FontWeight.bold), // Sans-serif and bold
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
                    elevation: 0, // Flat design
                  ),
                  child: const Text('Save Weekly Tasks'),
                )
              ],
            ),
    );
  }

  Widget _buildTaskTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        cursorColor: accentColor, // Cursor color
        style: const TextStyle(color: primaryTextColor, fontFamily: 'Roboto'), // Input text color and font
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: secondaryTextColor, fontFamily: 'Roboto'), // Label text color and font
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // Rounded corners for input fields
            borderSide: BorderSide(color: secondaryTextColor.withOpacity(0.5)), // Subtle border color
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: secondaryTextColor.withOpacity(0.3)), // Lighter border when not focused
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentColor, width: 2), // Accent color when focused
          ),
          filled: true,
          fillColor: cardBackgroundColor, // Input field background color
        ),
      ),
    );
  }
}