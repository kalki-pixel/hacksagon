import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'partner_list_tile.dart'; // We will create this file next

// Define custom colors based on the screenshot theme for consistency
const Color primaryBackgroundColor = Color(0xFFFBF8F2); // Very light, warm off-white/cream
const Color cardBackgroundColor = Color(0xFFF2EFEA); // Soft, fleshy beige for cards/buttons
const Color primaryTextColor = Color(0xFF4A4A4A); // Darker brown or charcoal for primary text
const Color secondaryTextColor = Color(0xFF888888); // Lighter muted brown for secondary text
const Color accentColor = Color(0xFF789D86); // Muted green accent

class StudyPartnerPage extends StatefulWidget {
  const StudyPartnerPage({super.key});

  @override
  State<StudyPartnerPage> createState() => _StudyPartnerPageState();
}

class _StudyPartnerPageState extends State<StudyPartnerPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<dynamic> _recommendations = [];
  String? _errorMessage;

  
  Future<void> _getRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
     
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw ("User is not logged in.");
      }

      
      final profileData = await supabase
          .from('profiles')
          .select('age, goal, academic_qualification, deadline')
          .eq('id', user.id)
          .single();

     
      final String userAge = profileData['age'].toString();
      final String userGoal = profileData['goal'];
      final String userAcademicLevel = profileData['academic_qualification'];
      final String? userDeadlineStr = profileData['deadline'];

      int daysRemaining = 730; 
      if (userDeadlineStr != null) {
        final deadlineDate = DateTime.parse(userDeadlineStr);
        daysRemaining = deadlineDate.difference(DateTime.now()).inDays;
        if (daysRemaining < 0) daysRemaining = 0;
      }
      
      const apiUrl = 'https://hermit-in-student-recommender.hf.space/recommend';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, dynamic>{
        'age': userAge,
        'goal': userGoal,
        'academic_level': userAcademicLevel,
        'deadline_days': daysRemaining,
        // ADD THIS LINE: Send the current user's ID to the API
        'current_user_id': user.id, 
      }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _recommendations = data['recommendations'];
            _isLoading = false;
          });
        } else {
          throw ('Failed to get recommendations: ${response.body}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackgroundColor, // Apply warm off-white/cream background
      appBar: AppBar(
        backgroundColor: primaryBackgroundColor, // App bar background matches page background
        elevation: 0, // No shadow under app bar
        title: const Text(
          'Find a Study Partner',
          style: TextStyle(
            color: primaryTextColor, // Darker brown/charcoal for title
            fontFamily: 'Roboto', // Sans-serif font
            fontWeight: FontWeight.bold, // Bold for headings
          ),
        ),
        centerTitle: true, // Center the title as seen in the screenshot's 'Find Partners'
        iconTheme: const IconThemeData(color: primaryTextColor), // Back arrow color
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _getRecommendations,
                icon: const Icon(Icons.search, color: primaryBackgroundColor), // Icon color
                label: const Text('Find a Match'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTextColor, // Darker brown/charcoal for button background
                  foregroundColor: primaryBackgroundColor, // Text color on button is light background
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontFamily: 'Roboto', fontWeight: FontWeight.bold), // Sans-serif and bold
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
                  elevation: 0, // Flat design
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _buildResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: accentColor)); // Loading indicator color
    }

    if (_errorMessage != null) {
      return Center(child: Text('An error occurred: $_errorMessage', style: const TextStyle(color: Colors.red, fontFamily: 'Roboto')));
    }

    if (_recommendations.isEmpty) {
      return Center(child: Text('Press "Find a Match" to see potential study partners.', style: TextStyle(color: secondaryTextColor, fontFamily: 'Roboto'))); // Text color
    }

   
    return ListView.builder(
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];
        return PartnerListTile(recommendation: recommendation);
      },
    );
  }
}