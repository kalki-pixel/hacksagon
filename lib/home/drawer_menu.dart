import 'package:checkmate/drawer/invitations_page.dart';
import 'package:checkmate/drawer/my_profile_page.dart';
import 'package:checkmate/home/analytics_dashboard_page.dart';
import 'package:checkmate/home/partner_choice_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// The widget is now stateful to manage the invitation stream.
class DrawerMenu extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final VoidCallback onLogout;

  const DrawerMenu({
    super.key,
    required this.userProfile,
    required this.onLogout,
  });

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  // --- The theme from the original file is preserved ---
  static const Color primaryColor = Color(0xFFFDFCF8);
  static const Color secondaryColor = Color(0xFFF0EAE3);
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF8D8478);

  // --- New state variable for the invitation count stream ---
  late final Stream<int> _invitationCountStream;

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;

    // The stream counts pending invitations for the current user
    _invitationCountStream = Supabase.instance.client
        .from('invitations')
        .stream(primaryKey: ['id']).map((listOfInvitations) {
      final pendingInvitations = listOfInvitations.where((invitation) =>
          invitation['receiver_id'] == userId &&
          invitation['status'] == 'pending');
      return pendingInvitations.length;
    }); //
  }

  @override
  Widget build(BuildContext context) {
    // Variables are now accessed via `widget.`
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final accountName = widget.userProfile?['name'] ?? 'User'; //
    final accountEmail = supabaseUser?.email ?? '';
    final avatarUrl = widget.userProfile?['avatar_url'] as String?; //

    return Drawer(
      backgroundColor: primaryColor, // Themed background
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              accountName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 16,
              ),
            ), //
            accountEmail: Text(
              accountEmail,
              style: const TextStyle(
                color: secondaryTextColor,
              ),
            ), //
            currentAccountPicture: CircleAvatar(
              backgroundColor: primaryColor,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? const Icon(Icons.person, size: 40, color: secondaryTextColor)
                  : null,
            ), //
            decoration: const BoxDecoration(
              color: secondaryColor,
            ), //
          ),
          ListTile(
            leading: const Icon(Icons.account_circle, color: textColor), //
            title: const Text('My Profile', style: TextStyle(color: textColor)), //
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyProfilePage()));
            },
          ),
          const Divider(color: secondaryColor, thickness: 1), //
          ListTile(
            leading: const Icon(Icons.analytics, color: textColor), //
            title: const Text('Statistics', style: TextStyle(color: textColor)), //
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsDashboardPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.group, color: textColor), //
            title: const Text('Partner', style: TextStyle(color: textColor)), //
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PartnerChoicePage()));
            },
          ),

          // --- New "My Invitations" item with real-time count badge ---
          StreamBuilder<int>(
            stream: _invitationCountStream, //
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return ListTile(
                leading: const Icon(Icons.mail_outline, color: textColor), // Themed icon
                title: const Text('My Invitations', style: TextStyle(color: textColor)), // Themed text
                trailing: count > 0
                    ? Badge(
                        backgroundColor: textColor, // Themed badge
                        label: Text(count.toString(), style: const TextStyle(color: primaryColor)),
                      ) //
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const InvitationsPage()));
                },
              );
            },
          ),

          const Divider(color: secondaryColor, thickness: 1), //
          ListTile(
            leading: const Icon(Icons.logout, color: textColor), //
            title: const Text('Logout', style: TextStyle(color: textColor)), //
            onTap: widget.onLogout, //
          ),
        ],
      ),
    );
  }
}