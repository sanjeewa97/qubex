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
import 'services/notification_service.dart';

// --- MAIN ENTRY POINT ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app(); // Ensure the default app is returned if already initialized
    }
  } catch (e) {
    // Ignore duplicate app error if it happens in a race condition
    if (e.toString().contains('duplicate-app')) {
      // Firebase already initialized
    } else {
      // Silently ignore or log to crashlytics in production
    }
  }

  // Initialize Notifications
  await NotificationService().initialize();
  
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

                if (userSnapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text("Error loading profile: ${userSnapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  );
                }

                if (userSnapshot.hasData && userSnapshot.data != null) {
                  // Profile exists, go to main app
                  // Save FCM Token
                  NotificationService().getToken().then((token) {
                    if (token != null) {
                      FirebaseService().saveUserToken(snapshot.data!.uid, token);
                    }
                  });
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