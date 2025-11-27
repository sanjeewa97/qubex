import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/main_app_scaffold.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_setup_screen.dart';

// --- MAIN ENTRY POINT ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
  
  // Ensure status bar looks good (Transparent)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const QubexApp());
}

// --- ROOT WIDGET ---
class QubexApp extends StatelessWidget {
  const QubexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qubex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.hasData) {
            // User is logged in, check if they have a profile
            return FutureBuilder(
              future: FirebaseService().getUser(snapshot.data!.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }

                if (userSnapshot.hasData && userSnapshot.data != null) {
                  // Profile exists, go to main app
                  return const MainAppScaffold();
                } else {
                  // Profile missing, go to setup
                  return const ProfileSetupScreen();
                }
              },
            );
          } else {
            return const OnboardingScreen();
          }
        },
      ),
    );
  }
}