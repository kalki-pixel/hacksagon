import 'package:checkmate/pages/profile_page.dart'; // To navigate to the edit page
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  // Consistent color palette from the original file
  static const Color primaryColor = Color(0xFFFDFCF8);
  static const Color secondaryColor = Color(0xFFF0EAE3);
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF8D8478);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser!.id;
      final response =
          await _supabase.from('profiles').select('*').eq('id', userId).single();

      if (mounted) {
        setState(() {
          _profileData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    ).then((_) {
      _loadProfileData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor, // Themed background
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold), // Themed title
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: textColor)) // Themed loader
          : _profileData == null
              ? const Center(child: Text('No profile data found.'))
              : _buildProfileView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToEditProfile,
        icon: const Icon(Icons.edit, color: textColor), // Themed icon
        label: const Text('Edit Profile', style: TextStyle(color: textColor)), // Themed label
        backgroundColor: secondaryColor, // Themed FAB background
      ),
    );
  }

  Widget _buildProfileView() {
    final avatarUrl = _profileData!['avatar_url'] as String?;
    final name = _profileData!['name'] ?? 'N/A';
    final description = _profileData!['description'] ?? 'No description provided.';
    final age = _profileData!['age']?.toString() ?? 'N/A';
    final sex = _profileData!['sex'] ?? 'N/A';
    final goal = _profileData!['goal'] ?? 'N/A';
    final qualification = _profileData!['academic_qualification'] ?? 'N/A';
    final deadline = _profileData!['deadline'] != null
        ? DateFormat('MMMM d, y').format(DateTime.parse(_profileData!['deadline']))
        : 'N/A';

    final dailyTasks = [
      _profileData!['task_1'],
      _profileData!['task_2'],
      _profileData!['task_3'],
      _profileData!['task_4'],
    ]
        .where((task) => task != null && task.isNotEmpty)
        .map((task) => task.toString())
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: secondaryColor,
                  backgroundImage:
                      avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: secondaryColor), // Themed divider
          _buildInfoCard(
            title: 'Personal Information',
            icon: Icons.person_outline,
            details: {
              'Age': age,
              'Sex': sex,
            },
          ),
          _buildInfoCard(
            title: 'Goals & Ambitions',
            icon: Icons.flag_outlined,
            details: {
              'Main Goal': goal,
              'Qualification': qualification,
              'Deadline': deadline,
            },
          ),
          _buildInfoCard(
            title: 'Daily Accountability Tasks',
            icon: Icons.check_circle_outline,
            isTaskList: true,
            tasks: dailyTasks,
          ),
          const SizedBox(height: 80), // Added space for FAB
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    Map<String, String> details = const {},
    List<String> tasks = const [],
    bool isTaskList = false,
  }) {
    return Card(
      color: secondaryColor, // Themed card color
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0, // Themed elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            if (!isTaskList)
              ...details.entries.map((entry) => _buildDetailRow(icon, entry.key, entry.value))
            else
              ...tasks.asMap().entries.map(
                  (entry) => _buildDetailRow(Icons.check, 'Task ${entry.key + 1}', entry.value))
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textColor), // Themed icon
          const SizedBox(width: 16),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label: ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}