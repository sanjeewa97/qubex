import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../data/schools_data.dart';
import '../widgets/loading_widget.dart';
import 'main_app_scaffold.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  
  String? _selectedGrade;
  String? _selectedStream; // New for A/L
  String? _selectedGender;
  bool _isLoading = false;

  final List<String> _grades = ['6', '7', '8', '9', '10', '11', '12', '13', 'University', 'Other'];
  final List<String> _streams = ['Physical Science', 'Biological Science', 'Commerce', 'Arts', 'Technology']; // A/L Streams
  final List<String> _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final user = _authService.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGrade == null || _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Grade and Gender")));
      return;
    }

    // Validate Stream for A/L
    if ((_selectedGrade == '12' || _selectedGrade == '13') && _selectedStream == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select your Stream")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw "User not logged in";

      final userModel = UserModel(
        id: user.uid,
        name: _nameController.text.trim(),
        searchName: _nameController.text.trim().toLowerCase(),
        school: _schoolController.text.trim(),
        avatarUrl: user.photoURL ?? '',
        photoUrl: user.photoURL ?? '',
        grade: _selectedGrade!,
        stream: _selectedStream ?? '', // Save stream
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        gender: _selectedGender!,
        iqScore: 0, // Initial score
        rank: 'Novice',
        solvedCount: 0,
      );

      await _firebaseService.updateUser(userModel);

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainAppScaffold()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving profile: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Complete Your Profile"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _authService.currentUser?.photoURL != null 
                    ? NetworkImage(_authService.currentUser!.photoURL!) 
                    : null,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: _authService.currentUser?.photoURL == null 
                    ? const Icon(Icons.person, size: 50, color: AppTheme.primary)
                    : null,
                ),
              ).animate().scale(),
              const SizedBox(height: 32),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // School Autocomplete
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return kSriLankanSchools.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _schoolController.text = selection;
                },
                fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                  // Sync controllers
                  if (fieldTextEditingController.text.isEmpty && _schoolController.text.isNotEmpty) {
                    fieldTextEditingController.text = _schoolController.text;
                  }
                  
                  // Listen to changes to update the main controller if user types a custom name
                  fieldTextEditingController.addListener(() {
                     _schoolController.text = fieldTextEditingController.text;
                  });

                  return TextFormField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    decoration: const InputDecoration(labelText: "School", prefixIcon: Icon(Icons.school_outlined)),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Grade (Dropdown)
              DropdownButtonFormField<String>(
                value: _selectedGrade,
                decoration: const InputDecoration(labelText: "Grade", prefixIcon: Icon(Icons.class_outlined)),
                items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() {
                  _selectedGrade = v;
                  if (v != '12' && v != '13') {
                    _selectedStream = null; // Reset stream if not A/L
                  }
                }),
              ),
              const SizedBox(height: 16),

              // Stream (Dropdown) - Only for Grade 12 & 13
              if (_selectedGrade == '12' || _selectedGrade == '13') ...[
                DropdownButtonFormField<String>(
                  value: _selectedStream,
                  decoration: const InputDecoration(labelText: "Stream", prefixIcon: Icon(Icons.category_outlined)),
                  items: _streams.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedStream = v),
                ).animate().fade().slideY(),
                const SizedBox(height: 16),
              ],

              // Age & Gender Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Age", prefixIcon: Icon(Icons.cake_outlined)),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(labelText: "Gender", prefixIcon: Icon(Icons.people_outline)),
                      items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => setState(() => _selectedGender = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isLoading 
                    ? const LoadingWidget(color: Colors.white, size: 20) 
                    : const Text("Save & Continue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
