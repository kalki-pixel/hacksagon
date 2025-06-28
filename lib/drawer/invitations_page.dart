import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  final supabase = Supabase.instance.client;

  late final Stream<List<Map<String, dynamic>>> _invitationsStream;
  
  // --- THEME UPDATE: Define theme colors for easy access ---
  static const Color primaryColor = Color(0xFFFDFCF8);
  static const Color secondaryColor = Color(0xFFF0EAE3);
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF8D8478);
  static final Color goodEfficiencyColor = Colors.teal.shade600;
  static final Color badEfficiencyColor = Colors.red.shade700;

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser?.id;

    _invitationsStream = supabase
        .from('invitations')
        .stream(primaryKey: ['id']).map((listOfMaps) {
      return listOfMaps
          .where((invitation) =>
              invitation['receiver_id'] == userId &&
              invitation['status'] == 'pending')
          .toList();
    });
  }

  Future<String> _getSenderName(String senderId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('name')
          .eq('id', senderId)
          .single();
      return response['name'] ?? 'Unknown User';
    } catch (_) {
      return 'Unknown User';
    }
  }

  Future<void> _handleInvitation(int invitationId, bool isAccepted) async {
    if (isAccepted) {
      try {
        await supabase.rpc('accept_invitation', params: {
          'invitation_id_to_accept': invitationId,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Partner connected successfully!'),
              // --- THEME UPDATE: Use theme's "good" color ---
              backgroundColor: goodEfficiencyColor));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to connect: ${e.toString()}'),
              // --- THEME UPDATE: Use theme's "bad" color ---
              backgroundColor: badEfficiencyColor));
        }
      }
    } else {
      // If rejected, just delete the invitation
      await supabase.from('invitations').delete().eq('id', invitationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- THEME UPDATE: Set background color and themed AppBar ---
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pending Invitations',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: textColor), // Style for back button
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _invitationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // --- THEME UPDATE: Use themed progress indicator ---
            return Center(child: CircularProgressIndicator(color: goodEfficiencyColor));
          }
          if (snapshot.hasError) {
            // --- THEME UPDATE: Use themed text color ---
            return Center(
                child: Text('Error fetching invitations: ${snapshot.error}',
                    style: const TextStyle(color: textColor)));
          }
          final invitations = snapshot.data ?? [];
          if (invitations.isEmpty) {
            // --- THEME UPDATE: Use themed text color ---
            return const Center(
                child: Text('You have no pending invitations.',
                    style: TextStyle(color: textColor, fontSize: 16)));
          }

          return ListView.builder(
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              final senderId = invitation['sender_id'];
              final invitationId = invitation['id'];

              // --- THEME UPDATE: Replaced Card with a styled Container ---
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(12),
                   boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ],
                ),
                child: ListTile(
                  // --- THEME UPDATE: Styled leading avatar ---
                  leading: CircleAvatar(
                    backgroundColor: textColor,
                    foregroundColor: primaryColor,
                    child: const Icon(Icons.person_add_alt_1),
                  ),
                  title: FutureBuilder<String>(
                    future: _getSenderName(senderId),
                    builder: (context, nameSnapshot) {
                      if (nameSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Text('Loading...', style: TextStyle(color: secondaryTextColor));
                      }
                      // --- THEME UPDATE: Styled title text ---
                      return Text(nameSnapshot.data ?? 'Unknown User',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: textColor));
                    },
                  ),
                  // --- THEME UPDATE: Styled subtitle text ---
                  subtitle: const Text('Sent you a connection request.',
                      style: TextStyle(color: secondaryTextColor)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- THEME UPDATE: Styled accept/reject buttons ---
                      IconButton(
                        icon: Icon(Icons.check_circle,
                            color: goodEfficiencyColor, size: 30),
                        onPressed: () => _handleInvitation(invitationId, true),
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel,
                            color: badEfficiencyColor, size: 30),
                        onPressed: () => _handleInvitation(invitationId, false),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}