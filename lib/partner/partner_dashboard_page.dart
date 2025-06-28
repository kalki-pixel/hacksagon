import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:checkmate/home/home_navigation_bar.dart';
import 'package:checkmate/partner/partner_chat_widget.dart';
import 'package:checkmate/partner/weekly_tasks_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerDashboardPage extends StatefulWidget {
  const PartnerDashboardPage({super.key});

  @override
  State<PartnerDashboardPage> createState() => _PartnerDashboardPageState();
}

class _PartnerDashboardPageState extends State<PartnerDashboardPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _errorMessage;

  String? _partnerName;
  Map<String, dynamic>? _currentUserProfile;
  Map<String, dynamic>? _partnerProfile;
  Map<String, dynamic>? _currentUserWeeklyTasks;
  Map<String, dynamic>? _partnerWeeklyTasks;

  // --- THEME DEFINITIONS ---
  static const Color primaryColor = Color(0xFFFDFCF8);
  static const Color secondaryColor = Color(0xFFF0EAE3);
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF8D8478);
  static final Color goodEfficiencyColor = Colors.teal.shade600;
  static final Color errorColor = Colors.red.shade700;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  String _getWeekString() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(startOfWeek);
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // Data loading logic remains the same
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw ("You are not logged in.");
      final weekOf = _getWeekString();
      final userProfileResponse = await supabase
          .from('profiles')
          .select('*, partner_id')
          .eq('id', userId)
          .single();
      final partnerId = userProfileResponse['partner_id'];
      if (mounted) setState(() => _currentUserProfile = userProfileResponse);
      if (partnerId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final partnerProfileResponse =
          await supabase.from('profiles').select().eq('id', partnerId).single();
      final tasksResponse = await supabase
          .from('weekly_tasks')
          .select()
          .eq('week_of', weekOf)
          .or('user_id.eq.$userId,user_id.eq.$partnerId');
      if (mounted) {
        setState(() {
          _partnerProfile = partnerProfileResponse;
          _partnerName = partnerProfileResponse['name'];
          _currentUserWeeklyTasks = tasksResponse.firstWhere(
              (taskSet) => taskSet['user_id'] == userId,
              orElse: () => {});
          _partnerWeeklyTasks = tasksResponse.firstWhere(
              (taskSet) => taskSet['user_id'] == partnerId,
              orElse: () => {});
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Could not load data.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTaskCompletion(int taskNumber, bool isCompleted) async {
    // Task toggling logic remains the same
    final weekOf = _getWeekString();
    final columnToUpdate = 'task_${taskNumber}_completed_at';
    final newDate = isCompleted ? DateTime.now().toIso8601String() : null;
    final currentTasksId = _currentUserWeeklyTasks?['id'];
    if (currentTasksId == null) return;
    setState(() => _currentUserWeeklyTasks?[columnToUpdate] = newDate);
    try {
      await supabase
          .from('weekly_tasks')
          .update({columnToUpdate: newDate}).eq('id', currentTasksId);
    } catch (e) {
      setState(() => _currentUserWeeklyTasks?[columnToUpdate] =
          isCompleted ? null : DateTime.now().toIso8601String());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: errorColor,
            content: const Text('Error updating task',
                style: TextStyle(color: primaryColor))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          centerTitle: true,
          title: const Text("Partner Dashboard",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
      body: _buildDashboardView(),
      bottomNavigationBar: const HomeNavigationBar(activeIndex: 3),
    );
  }

  Widget _buildDashboardView() {
    if (_isLoading)
      return Center(
          child: CircularProgressIndicator(color: goodEfficiencyColor));
    if (_errorMessage != null)
      return Center(
          child:
              Text(_errorMessage!, style: const TextStyle(color: textColor)));
    if (_partnerName == null) return _buildNoPartnerView();

    return RefreshIndicator(
      color: textColor,
      backgroundColor: primaryColor,
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text("This Week's Progress",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
          ),
          Column(
            children: [
              _buildTaskProgressCard(
                tasksData: _currentUserWeeklyTasks,
                isMyTasks: true,
              ),
              const SizedBox(height: 16),
              _buildTaskProgressCard(
                tasksData: _partnerWeeklyTasks,
                isMyTasks: false,
              ),
            ],
          ),
          const Divider(height: 48, thickness: 0.8, color: secondaryTextColor),
          const Center(
            child: Text(
              "Team Chat",
              style: TextStyle(
                  color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400, // Example height for the chat history
            child: PartnerChatWidget(partnerId: _partnerProfile!['id']),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNoPartnerView() {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline_rounded,
              size: 80, color: secondaryTextColor),
          const SizedBox(height: 20),
          Text(
            "You are not connected with a partner yet.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: textColor),
          ),
        ],
      ),
    ));
  }

  Widget _buildTaskProgressCard({
    required Map<String, dynamic>? tasksData,
    required bool isMyTasks,
  }) {
    int totalTasks = 0;
    int completedTasks = 0;
    if (tasksData != null && tasksData.isNotEmpty) {
      for (int i = 1; i <= 8; i++) {
        if (tasksData['task_$i'] != null &&
            (tasksData['task_$i'] as String).isNotEmpty) {
          totalTasks++;
          if (tasksData['task_${i}_completed_at'] != null) {
            completedTasks++;
          }
        }
      }
    }
    final double progress = totalTasks == 0 ? 0 : completedTasks / totalTasks;
    final String cardTitle =
        isMyTasks ? 'My Progress' : '$_partnerName\'s Progress';

    Widget buildTaskRow(int taskNumber) {
      final taskKey = 'task_$taskNumber';
      final dateKey = 'task_${taskNumber}_completed_at';
      final taskName = tasksData?[taskKey] as String?;
      if (taskName == null || taskName.isEmpty) return const SizedBox.shrink();
      final isCompleted = tasksData?[dateKey] != null;
      return ListTile(
        leading: Checkbox(
          value: isCompleted,
          activeColor: goodEfficiencyColor,
          checkColor: primaryColor,
          side: const BorderSide(color: secondaryTextColor, width: 1.5),
          onChanged: isMyTasks
              ? (bool? value) =>
                  _toggleTaskCompletion(taskNumber, value ?? false)
              : null,
        ),
        title: Text(taskName,
            style: TextStyle(
                color: textColor,
                fontSize: 15,
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none)),
        contentPadding: const EdgeInsets.only(left: 4.0, right: 0),
      );
    }

    // ######################################################################
    // ##################### CHANGE MADE IN THIS WIDGET #####################
    // ######################################################################
    Widget buildEmptyTasksView() {
      // Added SizedBox with full width and centered the Column's content
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center horizontally
            children: [
              const Icon(Icons.list_alt_rounded,
                  size: 40, color: secondaryTextColor),
              const SizedBox(height: 12),
              Text(
                isMyTasks
                    ? "Set your tasks for the week."
                    : "Tasks not set yet.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: secondaryTextColor),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(cardTitle,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                ),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        color: goodEfficiencyColor,
                        backgroundColor: Colors.grey.shade300,
                      ),
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontSize: 12),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const Divider(
              color: secondaryTextColor, indent: 16, endIndent: 16, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Column(
              children: [
                if (totalTasks == 0)
                  buildEmptyTasksView()
                else
                  Column(
                      children: List.generate(8, (i) => buildTaskRow(i + 1))),
                if (isMyTasks)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: textColor,
                            foregroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const WeeklyTasksPage()));
                          _refreshData();
                        },
                        child: const Text('Set / Edit Tasks',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}