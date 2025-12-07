import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import 'blocked_users_page.dart';
import 'onboarding_screen.dart';
import 'admin_dashboard.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: StreamBuilder<UserModel?>(
        stream: FirebaseService().getUserStream(user.uid),
        builder: (context, snapshot) {
          final userModel = snapshot.data;
          final isAdmin = userModel?.isAdmin ?? false;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isAdmin) ...[
                 const Text("Administration", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                 const SizedBox(height: 10),
                 _buildSettingsTile(
                    context, 
                    icon: Icons.admin_panel_settings, 
                    title: "Admin Panel", 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboard()))
                 ),
                 const SizedBox(height: 30),
              ],
              
              const Text("Account", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildSettingsTile(
                context, 
                icon: Icons.block, 
                title: "Blocked Users", 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedUsersPage()))
              ),
              
              const SizedBox(height: 30),
              
              const Text("App", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildSettingsTile(
                context, 
                icon: Icons.info_outline, 
                title: "About Qubex", 
                onTap: () {
                   showAboutDialog(
                     context: context, 
                     applicationName: "Qubex", 
                     applicationVersion: "1.0.0",
                     children: [const Text("The social learning platform for Sri Lankan students.")]
                   );
                }
              ),
              
              const SizedBox(height: 40),
              
              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                     final shouldSignOut = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Sign Out"),
                          content: const Text("Are you sure?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sign Out", style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (shouldSignOut == true) {
                        await AuthService().signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                            (route) => false,
                          );
                        }
                      }
                  },
                ),
              )
            ],
          );
        }
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset:const Offset(0, 2))
        ]
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    ).animate().fadeIn().slideX();
  }
}
