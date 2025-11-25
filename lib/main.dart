import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

// --- MAIN ENTRY POINT ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
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
      // Start at Login, flow to StreamSelect -> Home
      home: const LoginScreen(), 
    );
  }
}