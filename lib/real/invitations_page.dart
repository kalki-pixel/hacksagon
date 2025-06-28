// lib/real/invitations_page.dart
import 'package:flutter/material.dart';

// Define custom colors based on the screenshot theme
const Color primaryBackgroundColor = Color(0xFFFBF8F2); // Very light, warm off-white/cream
const Color cardBackgroundColor = Color(0xFFF2EFEA); // Soft, fleshy beige for cards/containers
const Color primaryTextColor = Color(0xFF4A4A4A); // Darker brown or charcoal for primary text
const Color secondaryTextColor = Color(0xFF888888); // Lighter muted brown for secondary text
// Note: An explicit accent color for buttons like 'Connect' is muted green from previous context,
// but not strictly needed for this page's current content.

class InvitationsPage extends StatelessWidget {
  const InvitationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackgroundColor, // Apply warm off-white/cream background
      appBar: AppBar(
        backgroundColor: primaryBackgroundColor, // App bar background matches page background
        elevation: 0, // No shadow under app bar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryTextColor), // Back arrow icon
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'My Invitations',
          style: TextStyle(
            color: primaryTextColor, // Darker brown/charcoal for title
            fontFamily: 'Roboto', // Assuming 'Roboto' or similar for sans-serif
            fontWeight: FontWeight.bold, // Bold for headings
          ),
        ),
        centerTitle: true, // Center the title as seen in the screenshot's 'Find Partners'
      ),
      body: Center(
        child: Text(
          'Invitations will be displayed here.',
          style: TextStyle(
            color: secondaryTextColor, // Lighter muted brown for body text
            fontSize: 16,
            fontFamily: 'Roboto', // Sans-serif font
          ),
        ),
      ),
    );
  }
}