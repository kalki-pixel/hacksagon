import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PartnerProfilePage extends StatefulWidget {
  final String userId;
  const PartnerProfilePage({super.key, required this.userId});

  @override
  State<PartnerProfilePage> createState() => _PartnerProfilePageState();
}

class _PartnerProfilePageState extends State<PartnerProfilePage> {
  // --- Theme Definition (Updated to match the new palette) ---
  static const Color primaryBackgroundColor = Color(0xFFFBF8F2); // Very light, warm off-white/cream
  static const Color cardBackgroundColor = Color(0xFFF2EFEA); // Soft, fleshy beige for cards/buttons
  static const Color primaryTextColor = Color(0xFF4A4A4A); // Darker brown or charcoal for primary text
  static const Color secondaryTextColor = Color(0xFF888888); // Lighter muted brown for secondary text
  static const Color accentColor = Color(0xFF789D86); // Muted green accent

  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _errorMessage;

  // --- Feature: State for handling connection requests ---
  bool _isSendingRequest = false;
  String _requestStatus = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _checkExistingInvitation();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();
      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load profile.";
          _isLoading = false;
        });
      }
    }
  }

  // --- Feature: Checks for an existing invitation between users ---
  Future<void> _checkExistingInvitation() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    final senderId = currentUser.id;
    final receiverId = widget.userId;

    final response = await supabase
        .from('invitations')
        .select('status')
        .or('and(sender_id.eq.$senderId,receiver_id.eq.$receiverId),and(sender_id.eq.$receiverId,receiver_id.eq.$senderId)')
        .maybeSingle();

    if (response != null && mounted) {
      setState(() {
        _requestStatus = response['status'];
      });
    }
  }

  // --- Feature: Sends a connection request to the database ---
  Future<void> _sendConnectionRequest() async {
    setState(() { _isSendingRequest = true; });

    final senderId = supabase.auth.currentUser?.id;
    if (senderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to send requests.')));
      return;
    }

    try {
      await supabase.from('invitations').insert({
        'sender_id': senderId,
        'receiver_id': widget.userId,
      });
      if (mounted) {
        setState(() { _requestStatus = 'pending'; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _requestStatus = 'error'; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send request. The user may have already sent you a request.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) { setState(() { _isSendingRequest = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- Theme: Themed background and AppBar ---
      backgroundColor: primaryBackgroundColor, // Updated to new primary background color
      appBar: AppBar(
        title: const Text(
          'Partner Profile',
          style: TextStyle(
            color: primaryTextColor, // Updated to new primary text color
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto', // Sans-serif font
          ),
        ),
        backgroundColor: primaryBackgroundColor, // App bar background matches page background
        elevation: 0,
        foregroundColor: primaryTextColor, // Color of leading icon (back arrow)
      ),
      body: _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: accentColor)); // Loading indicator with accent color
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_profileData == null) {
      return const Center(child: Text('Profile not found.', style: TextStyle(color: primaryTextColor)));
    }

    final String name = _profileData!['name'] ?? 'No Name';
    final String age = _profileData!['age']?.toString() ?? 'N/A';
    final String goal = _profileData!['goal'] ?? 'Not specified';
    final String academicLevel = _profileData!['academic_qualification'] ?? 'Not specified';
    final String description = _profileData!['description'] ?? 'No description provided.';
    final String? avatarUrl = _profileData!['avatar_url'];
    String deadline = 'Not set';
    if (_profileData!['deadline'] != null) {
      try {
        final deadlineDate = DateTime.parse(_profileData!['deadline']);
        deadline = DateFormat.yMMMMd().format(deadlineDate);
      } catch (_) {
        deadline = 'Invalid Date';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: cardBackgroundColor, // Avatar background uses card color
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? const Icon(Icons.person, size: 50, color: secondaryTextColor) : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryTextColor, // Updated text color
              fontFamily: 'Roboto', // Sans-serif font
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: secondaryTextColor, // Updated text color
              fontFamily: 'Roboto', // Sans-serif font
            ),
          ),
          const SizedBox(height: 24),
          _buildProfileDetailCard(title: 'User Details', details: {
            'Age': age,
            'Goal': goal,
            'Academic Level': academicLevel,
            'Deadline': deadline,
          }),
          const SizedBox(height: 32),
          _buildConnectionButton(),
        ],
      ),
    );
  }

  // --- Feature: Themed button that changes based on request status ---
  Widget _buildConnectionButton() {
    // Don't show button on your own profile
    if (widget.userId == supabase.auth.currentUser?.id) {
      return const SizedBox.shrink();
    }
    
    // --- Style for the main action button ---
    final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: primaryTextColor, // Darker brown/charcoal for 'Connect' button
      foregroundColor: primaryBackgroundColor, // Text on button is the light background color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      elevation: 0, // Flat design
      minimumSize: const Size(double.infinity, 50),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Roboto'), // Sans-serif font
    );
    
    // --- Style for disabled/status buttons ---
    final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: cardBackgroundColor, // Soft, fleshy beige for disabled/status buttons
      foregroundColor: secondaryTextColor, // Lighter muted brown for text
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      elevation: 0,
       minimumSize: const Size(double.infinity, 50),
       textStyle: const TextStyle(fontSize: 16, fontFamily: 'Roboto'), // Sans-serif font
    );

    if (_isSendingRequest) {
      return ElevatedButton(
        onPressed: null,
        style: primaryButtonStyle,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: primaryBackgroundColor, strokeWidth: 3), // Loading indicator color
        ),
      );
    }
    switch (_requestStatus) {
      case 'pending':
        return ElevatedButton(onPressed: null, style: secondaryButtonStyle, child: const Text('Request Sent'));
      case 'accepted':
        return ElevatedButton(
            onPressed: null,
            style: secondaryButtonStyle.copyWith(
              backgroundColor: WidgetStateProperty.all(accentColor.withOpacity(0.2)), // Soft green for accepted
              foregroundColor: WidgetStateProperty.all(accentColor), // Darker green for accepted text
            ),
            child: const Text('Connected!'));
      default:
        return ElevatedButton(
          onPressed: _sendConnectionRequest,
          style: primaryButtonStyle,
          child: const Text('Send Connection Request'), // Text style moved to primaryButtonStyle
        );
    }
  }

  // --- Theme: A single, beautifully styled card for profile details ---
  Widget _buildProfileDetailCard({required String title, required Map<String, String> details}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackgroundColor, // Card background uses soft, fleshy beige
        borderRadius: BorderRadius.circular(12),
        boxShadow: [ // Subtle shadow for card effect, consistent with other cards
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold, // Bold for title
              color: primaryTextColor, // Updated text color
              fontFamily: 'Roboto', // Sans-serif font
            ),
          ),
          Divider(height: 20, color: primaryBackgroundColor.withOpacity(0.5)), // Divider color that blends
          ...details.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor, // Updated text color
                    fontFamily: 'Roboto', // Sans-serif font
                  ),
                ),
                Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600, // Slightly bolder for values
                    color: primaryTextColor, // Updated text color
                    fontFamily: 'Roboto', // Sans-serif font
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}