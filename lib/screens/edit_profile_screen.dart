import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../widgets/loading_widget.dart';
import '../data/schools_data.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel? user;

  const EditProfileScreen({super.key, this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _schoolController;
  late TextEditingController _ageController;
  
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  File? _selectedImage;
  String? _photoUrl;

  String? _selectedGrade;
  String? _selectedStream;
  String? _selectedGender;

  final List<String> _grades = ['6', '7', '8', '9', '10', '11', '12', '13', 'University', 'Other'];
  final List<String> _streams = ['Physical Science', 'Biological Science', 'Commerce', 'Arts', 'Technology'];
  final List<String> _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _schoolController = TextEditingController(text: widget.user?.school ?? '');
    _ageController = TextEditingController(text: widget.user?.age.toString() ?? '');
    _photoUrl = widget.user?.photoUrl;
    
    _selectedGrade = widget.user?.grade.isNotEmpty == true ? widget.user!.grade : null;
    _selectedStream = widget.user?.stream.isNotEmpty == true ? widget.user!.stream : null;
    _selectedGender = widget.user?.gender.isNotEmpty == true ? widget.user!.gender : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Change Profile Photo",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: AppTheme.primary),
              ),
              title: const Text("Take Photo"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: AppTheme.secondary),
              ),
              title: const Text("Choose from Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: $e")),
        );
      }
    }
  }

  Future<String?> _uploadPhoto() async {
    if (_selectedImage == null) return _photoUrl;

    setState(() => _isUploadingPhoto = true);

    try {
      final authUser = AuthService().currentUser;
      if (authUser == null) throw "User not logged in";

      final url = await FirebaseService().uploadProfilePhoto(
        authUser.uid,
        _selectedImage!,
      );
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error uploading photo: $e")),
        );
      }
      return _photoUrl;
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedGrade == null || _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Grade and Gender")));
      return;
    }

    if ((_selectedGrade == '12' || _selectedGrade == '13') && _selectedStream == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select your Stream")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authUser = AuthService().currentUser;
      if (authUser == null) throw "User not logged in";

      // Upload photo if selected
      final newPhotoUrl = await _uploadPhoto();

      final updatedUser = UserModel(
        id: authUser.uid,
        email: authUser.email ?? '',
        name: _nameController.text.trim(),
        searchName: _nameController.text.trim().toLowerCase(),
        school: _schoolController.text.trim(),
        avatarUrl: newPhotoUrl ?? widget.user?.avatarUrl ?? '',
        photoUrl: newPhotoUrl ?? widget.user?.photoUrl ?? '',
        iqScore: widget.user?.iqScore ?? 0,
        rank: widget.user?.rank ?? 'Novice',
        solvedCount: widget.user?.solvedCount ?? 0,
        grade: _selectedGrade!,
        stream: _selectedStream ?? '',
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        gender: _selectedGender!,
        fcmToken: widget.user?.fcmToken,
      );

      await FirebaseService().updateUser(updatedUser);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Header Background
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Title
                const Positioned(
                  top: 60,
                  child: Text(
                    "Edit Profile",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),

                // Form Card
                Container(
                  margin: const EdgeInsets.only(top: 160, left: 24, right: 24, bottom: 24),
                  padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: "Full Name",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),
                        
                        // School Autocomplete
                        Autocomplete<String>(
                          initialValue: TextEditingValue(text: _schoolController.text),
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
                            // Sync if initial value exists and controller is empty (first load)
                            if (fieldTextEditingController.text.isEmpty && _schoolController.text.isNotEmpty) {
                              fieldTextEditingController.text = _schoolController.text;
                            }
                            
                            // Listen to changes
                            fieldTextEditingController.addListener(() {
                               _schoolController.text = fieldTextEditingController.text;
                            });

                            return TextFormField(
                              controller: fieldTextEditingController,
                              focusNode: fieldFocusNode,
                              decoration: InputDecoration(
                                labelText: "School / University",
                                prefixIcon: const Icon(Icons.school_outlined, color: AppTheme.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Grade Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedGrade,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: "Grade",
                            prefixIcon: const Icon(Icons.class_outlined, color: AppTheme.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => setState(() {
                            _selectedGrade = v;
                            if (v != '12' && v != '13') {
                              _selectedStream = null;
                            }
                          }),
                        ),
                        const SizedBox(height: 20),

                        // Stream Dropdown (Conditional)
                        if (_selectedGrade == '12' || _selectedGrade == '13') ...[
                          DropdownButtonFormField<String>(
                            value: _selectedStream,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: "Stream",
                              prefixIcon: const Icon(Icons.category_outlined, color: AppTheme.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: _streams.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _selectedStream = v),
                          ).animate().fade().slideY(),
                          const SizedBox(height: 20),
                        ],

                        // Age & Gender Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Age",
                                  prefixIcon: const Icon(Icons.cake_outlined, color: AppTheme.primary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                validator: (v) => v!.isEmpty ? "Required" : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedGender,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: "Gender",
                                  prefixIcon: const Icon(Icons.people_outline, color: AppTheme.primary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                onChanged: (v) => setState(() => _selectedGender = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _isUploadingPhoto) ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                              elevation: 2,
                            ),
                            child: (_isLoading || _isUploadingPhoto)
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const LoadingWidget(color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        _isUploadingPhoto ? "Uploading photo..." : "Saving...",
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  )
                                : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms),

                // Avatar with Edit Button
                Positioned(
                  top: 110,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (_photoUrl?.isNotEmpty == true
                                    ? NetworkImage(_photoUrl!) as ImageProvider
                                    : null),
                            child: (_selectedImage == null && (_photoUrl?.isEmpty ?? true))
                                ? const Icon(Icons.person, size: 50, color: AppTheme.primary)
                                : null,
                          ),
                        ),
                        // Camera Icon Overlay
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(delay: 200.ms),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) => value!.isEmpty ? "Required" : null,
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
