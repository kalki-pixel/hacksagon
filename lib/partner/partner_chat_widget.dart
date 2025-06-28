import 'dart:async';
import 'package:flutter/material.dart'; // This import was missing before
import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerChatWidget extends StatefulWidget {
  final String partnerId;
  const PartnerChatWidget({super.key, required this.partnerId});

  @override
  State<PartnerChatWidget> createState() => _PartnerChatWidgetState();
}

class _PartnerChatWidgetState extends State<PartnerChatWidget> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  
  List<Map<String, dynamic>> _messages = [];
  late final StreamSubscription<List<Map<String, dynamic>>> _messagesSubscription;
  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser!.id;

    // The stream from Supabase that brings in new messages
    final messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((listOfMaps) {
          // Client-side filter
          return listOfMaps
              .where((message) =>
                  (message['sender_id'] == _currentUserId && message['receiver_id'] == widget.partnerId) ||
                  (message['sender_id'] == widget.partnerId && message['receiver_id'] == _currentUserId))
              .toList();
        });

    // We listen to the stream and update our local list
    _messagesSubscription = messagesStream.listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
        });
      }
    });
  }

  /// Implements Optimistic UI for instant message reflection
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      return;
    }

    // 1. Create a temporary message map to display instantly
    final optimisticMessage = {
      'id': DateTime.now().millisecondsSinceEpoch, // Use a temporary unique ID
      'sender_id': _currentUserId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    };

    // 2. Immediately add it to the local list and update the UI
    setState(() {
      _messages.insert(0, optimisticMessage); // Insert at the top of the reversed list
    });
    _messageController.clear();

    // 3. Send the actual message to the database in the background
    try {
      await _supabase.from('messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': widget.partnerId,
        'content': content,
      });
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ));
        // Optional: Remove the optimistic message or show a failed state
        setState(() {
          _messages.removeWhere((msg) => msg['id'] == optimisticMessage['id']);
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagesSubscription.cancel(); // Always cancel stream subscriptions
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The list of messages now reads from our local _messages list
        Expanded(
          child: _messages.isEmpty
              ? const Center(child: Text('Start the conversation!'))
              : ListView.builder(
                  reverse: true, // Makes the list start from the bottom
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isMine = message['sender_id'] == _currentUserId;

                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Card(
                        color: isMine ? Theme.of(context).primaryColor : Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Text(
                            message['content'],
                            style: TextStyle(color: isMine ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // The input field for typing a new message
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}