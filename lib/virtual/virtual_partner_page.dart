import 'dart:convert';
import 'package:checkmate/home/home_navigation_bar.dart'; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class VirtualPartnerPage extends StatefulWidget {
  const VirtualPartnerPage({super.key});

  @override
  State<VirtualPartnerPage> createState() => _VirtualPartnerPageState();
}

class _VirtualPartnerPageState extends State<VirtualPartnerPage> {
  // --- Theme Definition ---
  static const Color primaryColor = Color(0xFFFDFCF8);
  static const Color secondaryColor = Color(0xFFF0EAE3);
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF8D8478);
  
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _weeklyTasks = [];
  bool _isLoading = true;
  bool _isAwaitingResponse = false;

  String? _userName;
  String? _userGoal;
  DateTime? _userDeadline;
  DateTime? _profileCreationDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() { _isLoading = true; });
    try {
      await Future.wait([
        _loadUserProfile(),
        _loadWeeklyGoals(),
      ]);
      if (mounted) _addInitialMessage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }
  
  Future<void> _loadUserProfile() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase.from('profiles').select('name, goal, deadline, created_at').eq('id', userId).single();
    _userName = response['name'] ?? 'User';
    _userGoal = response['goal'] ?? 'achieve our goals';
    _userDeadline = response['deadline'] != null ? DateTime.parse(response['deadline']) : null;
    _profileCreationDate = DateTime.parse(response['created_at']);
  }

  Future<void> _loadWeeklyGoals() async {
    final userId = _supabase.auth.currentUser!.id;
    final startOfWeek = _getStartOfWeek(DateTime.now());
    final response = await _supabase
        .from('weekly_goals')
        .select('tasks')
        .eq('user_id', userId)
        .eq('week_of', DateFormat('yyyy-MM-dd').format(startOfWeek))
        .maybeSingle();

    if (response != null && response['tasks'] != null) {
      _weeklyTasks = List<Map<String, dynamic>>.from(response['tasks'] as List);
    }
  }

  void _addInitialMessage() {
    setState(() {
      _messages.add(ChatMessage(text: "Hey $_userName! I've got our weekly plan right here. Ready to get started?", isUser: false));
    });
  }

  void _toggleTask(int index) async {
    setState(() { _weeklyTasks[index]['is_completed'] = !_weeklyTasks[index]['is_completed']; });
    try {
      final userId = _supabase.auth.currentUser!.id;
      final startOfWeek = _getStartOfWeek(DateTime.now());
      await _supabase
          .from('weekly_goals')
          .update({'tasks': _weeklyTasks})
          .eq('user_id', userId)
          .eq('week_of', DateFormat('yyyy-MM-dd').format(startOfWeek));
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving task progress: $e'), backgroundColor: Colors.red));
        setState(() { _weeklyTasks[index]['is_completed'] = !_weeklyTasks[index]['is_completed']; });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isAwaitingResponse) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isAwaitingResponse = true;
    });
    _chatController.clear();
    _scrollToBottom();

    try {
      final weekNumber = _calculateWeekNumber();
      final partnerEfficiency = _calculatePartnerEfficiency(weekNumber);
      final completedTasks = _weeklyTasks.where((t) => t['is_completed']).map((t) => t['description']).toList();
      final pendingTasks = _weeklyTasks.where((t) => !t['is_completed']).map((t) => t['description']).toList();
      final prompt = """
      You are Alex, a motivating virtual accountability partner. Your personality is positive and focused. You are not a generic AI.
      **Our Core Mission:**
      - User's Name: $_userName
      - Our Shared Main Goal: $_userGoal
      - Our Deadline: ${_userDeadline != null ? DateFormat.yMMMd().format(_userDeadline!) : 'Not set'}
      **This Week's Status (Week $weekNumber of our journey):**
      - User's Completed Tasks: ${completedTasks.isNotEmpty ? completedTasks.join(', ') : 'None yet.'}
      - User's Pending Tasks: ${pendingTasks.isNotEmpty ? pendingTasks.join(', ') : 'All done!'}
      - Your Simulated Efficiency: ${(partnerEfficiency * 100).toStringAsFixed(0)}%
      **Your Task:**
      Respond to the user's message as Alex. Based on your efficiency and the user's progress, talk about how your week is going.
      - If the user completed a task, congratulate them!
      - Talk about your own (simulated) struggles or successes with the pending tasks.
      - ALWAYS be encouraging. End by asking the user a question about their progress or well-being.
      - Keep responses conversational and concise.
      **Chat History (for context):**
      ${_messages.map((m) => "${m.isUser ? 'User' : 'Alex'}: ${m.text}").join('\n')}
      **User's latest message:** "$text"
      **Your response as Alex:**
      """;
      
      const apiKey = 'YOUR_API_KEY_HERE'; // Replace with your actual API key
      const apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey';
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': [{'parts': [{'text': prompt}]}]}),
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        final aiText = decodedResponse['candidates'][0]['content']['parts'][0]['text'];
        setState(() { _messages.add(ChatMessage(text: aiText.trim(), isUser: false)); });
      } else {
         final errorBody = jsonDecode(response.body);
         setState(() { _messages.add(ChatMessage(text: "Sorry, I'm having trouble connecting right now. (Error: ${errorBody['error']?['message'] ?? 'Unknown'})", isUser: false)); });
      }
    } catch (e) {
      setState(() { _messages.add(ChatMessage(text: "Oops, something went wrong. Please check your connection.", isUser: false)); });
    } finally {
      setState(() { _isAwaitingResponse = false; });
      _scrollToBottom();
    }
  }
  
  DateTime _getStartOfWeek(DateTime date) => date.subtract(Duration(days: date.weekday - 1));
  int _calculateWeekNumber() => _profileCreationDate == null ? 1 : (DateTime.now().difference(_profileCreationDate!).inDays / 7).floor() + 1;
  double _calculatePartnerEfficiency(int weekNumber) {
    double efficiency = 0.60 + ((weekNumber - 1) * 0.05);
    return efficiency > 0.95 ? 0.95 : efficiency;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text("Virtual Partner", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      bottomNavigationBar: const HomeNavigationBar(activeIndex: 3),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: textColor))
          : Column(
              children: [
                _buildDeadlineCard(),
                _buildWeeklyTasksCard(),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                        ),
                      ),
                      if (_isAwaitingResponse)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(strokeWidth: 2, color: textColor),
                              SizedBox(width: 12),
                              Text("Alex is thinking...", style: TextStyle(color: secondaryTextColor))
                            ],
                          ),
                        ),
                      _buildChatInput(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // --- All UI build methods are themed ---
  Widget _buildDeadlineCard() {
    int daysLeft = _userDeadline?.difference(DateTime.now()).inDays ?? 0;
    if (daysLeft < 0) daysLeft = 0;
    
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, size: 40, color: textColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$daysLeft Days Left", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              Text("Until your deadline for '$_userGoal'", style: const TextStyle(color: secondaryTextColor)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWeeklyTasksCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Text("This Week's Plan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const Divider(color: secondaryTextColor, thickness: 0.5),
          if (_weeklyTasks.isEmpty)
            const Padding(padding: EdgeInsets.all(8.0), child: Text("No tasks set for this week yet.", style: TextStyle(color: secondaryTextColor)))
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.2),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _weeklyTasks.length,
                itemBuilder: (context, index) {
                  final task = _weeklyTasks[index];
                  return CheckboxListTile(
                    title: Text(task['description'], style: TextStyle(decoration: task['is_completed'] ? TextDecoration.lineThrough : null, color: task['is_completed'] ? secondaryTextColor : textColor)),
                    value: task['is_completed'],
                    onChanged: (bool? value) => _toggleTask(index),
                    activeColor: textColor,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bubbleAlignment = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = message.isUser ? textColor : secondaryColor;
    final textColorOnBubble = message.isUser ? primaryColor : textColor;

    return Container(
      alignment: bubbleAlignment,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(16)),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(message.text, style: TextStyle(fontSize: 16, color: textColorOnBubble)),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      decoration: BoxDecoration(color: primaryColor, boxShadow: [BoxShadow(offset: const Offset(0, -1), blurRadius: 2, color: Colors.black.withOpacity(0.05))]),
      padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: "Type your message...",
                filled: true,
                fillColor: secondaryColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: _isAwaitingResponse ? null : (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isAwaitingResponse ? null : _sendMessage,
            style: IconButton.styleFrom(backgroundColor: textColor, foregroundColor: primaryColor, disabledBackgroundColor: Colors.grey),
          ),
        ],
      ),
    );
  }
}