import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Header
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Alex Johnson",
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Male, 34 yrs • 180cm • 75kg",
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Settings Sections
            _buildSectionHeader("Medical Profile"),
            _buildSettingItem("Known Conditions", "None"),
            _buildSettingItem("Medications", "None"),
             _buildSettingItem("Emergency Contact", "+1 555-0123"),

            const SizedBox(height: 24),
            _buildSectionHeader("App Settings"),
            _buildSwitchItem("Notifications", true),
            _buildSwitchItem("Dark Mode", false), // Logic to be implemented
            _buildActionItem("Privacy & Security", Icons.lock_outline),
            _buildActionItem("Help & Support", Icons.help_outline),
            
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () {
                context.go('/welcome'); // Logout
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text("Log Out"),
            ),
             const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
        trailing: Text(value, style: GoogleFonts.outfit(color: Colors.grey)),
      ),
    );
  }

   Widget _buildSwitchItem(String title, bool value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
        value: value,
        onChanged: (v) {},
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Widget _buildActionItem(String title, IconData icon) {
     return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textLight),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
