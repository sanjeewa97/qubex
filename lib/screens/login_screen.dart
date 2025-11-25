import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'stream_selection_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Placeholder
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                      ]
                    ),
                    child: const Icon(Icons.bolt_rounded, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text("QUBEX", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5)),
                  const Text("The Student Network", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  
                  const SizedBox(height: 60),
                  
                  // Inputs
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      hintText: "Email",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      hintText: "Password",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to Stream Selection
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const StreamSelectionScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
