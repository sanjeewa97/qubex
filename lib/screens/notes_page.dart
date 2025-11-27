import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../models/note_model.dart';
import '../models/user_model.dart';
import '../widgets/loading_widget.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  String _selectedSubject = "Maths"; // Default subject
  bool _isUploading = false;

  Future<void> _uploadNote() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to upload notes")));
      return;
    }

    // Pick file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      // Show dialog to enter title
      TextEditingController titleController = TextEditingController(text: fileName.replaceAll('.pdf', ''));
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Upload Note"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                items: ["Maths", "Physics", "Chemistry", "ICT"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => _selectedSubject = val!,
                decoration: const InputDecoration(labelText: "Subject"),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performUpload(file, titleController.text, _selectedSubject, user.displayName ?? "Unknown", user.uid);
              },
              child: const Text("Upload"),
            )
          ],
        ),
      );
    }
  }

  Future<void> _performUpload(File file, String title, String subject, String author, String userId) async {
    setState(() => _isUploading = true);
    try {
      final userModel = await _firebaseService.getUser(userId);
      await _firebaseService.uploadNote(
        file, 
        title, 
        subject, 
        author, 
        userModel?.school ?? 'Unknown', 
        userModel?.grade ?? ''
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Note uploaded successfully!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _openNote(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open note")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Knowledge Hub")),
      body: Column(
        children: [
          // Subject Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSubject = "Maths"),
                    child: _SubjectCard(
                      title: "Maths", 
                      color: _selectedSubject == "Maths" ? AppTheme.primary.withOpacity(0.1) : Colors.white, 
                      icon: Icons.calculate, 
                      iconColor: _selectedSubject == "Maths" ? AppTheme.primary : Colors.grey,
                      isSelected: _selectedSubject == "Maths",
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSubject = "Physics"),
                    child: _SubjectCard(
                      title: "Physics", 
                      color: _selectedSubject == "Physics" ? AppTheme.accent.withOpacity(0.1) : Colors.white, 
                      icon: Icons.speed, 
                      iconColor: _selectedSubject == "Physics" ? AppTheme.accent : Colors.grey,
                      isSelected: _selectedSubject == "Physics",
                    ),
                  ),
                ),
              ],
            ).animate().fade().slideY(begin: -0.2, end: 0),
          ),
          
          if (_isUploading) const LinearProgressIndicator(),

          Expanded(
            child: FutureBuilder<UserModel?>(
              future: _firebaseService.getUser(AuthService().currentUser?.uid ?? ''),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingWidget());
                }

                final user = userSnapshot.data;
                final userGrade = user?.grade ?? '';
                final userSchool = user?.school ?? '';

                return StreamBuilder<List<NoteModel>>(
                  stream: _firebaseService.getNotes(_selectedSubject, userGrade, userSchool),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      ));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LoadingWidget());
                    }
                    
                    final notes = snapshot.data ?? [];
                    
                    if (notes.isEmpty) {
                      return Center(child: Text("No $_selectedSubject notes for Grade $userGrade yet.", style: Theme.of(context).textTheme.bodyMedium));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return GestureDetector(
                          onTap: () => _openNote(note.fileUrl),
                          child: _NoteTile(title: note.title, author: note.authorName, size: note.size),
                        ).animate(delay: (100 * index).ms).fade().slideX();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadNote,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text("Upload Note", style: TextStyle(color: Colors.white)),
      ).animate().scale(delay: 500.ms),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;

  const _SubjectCard({required this.title, required this.color, required this.icon, required this.iconColor, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: iconColor, width: 2) : Border.all(color: Colors.grey.shade200),
        boxShadow: isSelected ? [BoxShadow(color: iconColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : []
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: iconColor)),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final String title;
  final String author;
  final String size;

  const _NoteTile({required this.title, required this.author, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.picture_as_pdf, color: AppTheme.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
                Text("$author • $size", style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.download_rounded, color: Colors.grey),
        ],
      ),
    );
  }
}
