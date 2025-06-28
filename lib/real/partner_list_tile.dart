// lib/real/partner_list_tile.dart
import 'package:checkmate/real/partner_profile_page.dart';
import 'package:flutter/material.dart';

// Define custom colors based on the screenshot theme
const Color primaryBackgroundColor = Color(0xFFFBF8F2); // Not directly used in tile, but for consistency
const Color cardBackgroundColor = Color(0xFFF2EFEA); // Soft, fleshy beige for cards/buttons
const Color primaryTextColor = Color(0xFF4A4A4A); // Darker brown or charcoal for primary text
const Color secondaryTextColor = Color(0xFF888888); // Lighter muted brown for secondary text
const Color accentColor = Color(0xFF789D86); // Muted green accent

class PartnerListTile extends StatelessWidget {
  final Map<String, dynamic> recommendation;

  const PartnerListTile({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final String name = recommendation['name'] ?? 'Unknown User';
    final double score = (recommendation['similarity_score'] ?? 0.0) * 100;

    // Safely cast the user ID to a nullable String.
    final String? userId = recommendation['id'] as String?;

    // A flag to determine if the tile has valid data and should be interactive.
    final bool isValid = userId != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      // Apply card background color
      color: isValid ? cardBackgroundColor : cardBackgroundColor.withOpacity(0.7), // Slightly dimmed for invalid
      elevation: 0, // Flat design similar to screenshot
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Add subtle shadow for definition, consistent with previous card styling
      child: Container(
        decoration: BoxDecoration(
          color: isValid ? cardBackgroundColor : cardBackgroundColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          // Only allow tapping if the user ID is valid.
          onTap: isValid
              ? () {
                  // We know userId is not null here because of the isValid check.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PartnerProfilePage(userId: userId!), // userId is guaranteed non-null here
                    ),
                  );
                }
              : null, // Disable the onTap functionality if no ID.
          leading: CircleAvatar(
            // Use a thematic color for avatar background. Using card background or primary background
            // would be too light; a slightly darker shade or accent color works.
            // For now, a subtle grey that blends well with the theme.
            backgroundColor: isValid ? Colors.grey[300] : Colors.grey[300], // Example: a light grey for avatars
            child: Icon(Icons.person, color: isValid ? primaryTextColor : secondaryTextColor), // Icon color
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold, // Bold for names
              color: primaryTextColor, // Darker brown/charcoal for primary text
              fontFamily: 'Roboto', // Sans-serif font
            ),
          ),
          subtitle: Text(
            isValid ? 'Match Score: ${score.toStringAsFixed(0)}%' : 'Invalid Data',
            style: TextStyle(
              color: secondaryTextColor, // Lighter muted brown for secondary text
              fontFamily: 'Roboto', // Sans-serif font
            ),
          ),
          trailing: isValid
              ? const Icon(Icons.arrow_forward_ios, color: primaryTextColor) // Icon color
              : const Icon(Icons.error_outline, color: Colors.red), // Error icon remains red for visibility
        ),
      ),
    );
  }
}