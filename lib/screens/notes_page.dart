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
  
  // State
  String? _selectedSubject; // If null, show folders. If set, show notes.
  bool _isUploading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userData = await _firebaseService.getUser(user.uid);
      if (mounted) {
        setState(() => _currentUser = userData);
      }
    }
  }

  // Dynamic Subject List based on Grade and Stream
  List<Map<String, dynamic>> get _subjects {
    if (_currentUser == null) return [];

    final grade = _currentUser!.grade;
    final stream = _currentUser!.stream;

    // A/L Logic (Grade 12 & 13)
    if (grade == '12' || grade == '13') {
      switch (stream) {
        case 'Physical Science':
          return [
            {'name': 'Combined Maths', 'icon': Icons.calculate, 'color': Colors.blue},
            {'name': 'Physics', 'icon': Icons.speed, 'color': Colors.red},
            {'name': 'Chemistry', 'icon': Icons.science, 'color': Colors.green},
            {'name': 'ICT', 'icon': Icons.computer, 'color': Colors.purple},
            {'name': 'General English', 'icon': Icons.language, 'color': Colors.orange},
          ];
        case 'Biological Science':
          return [
            {'name': 'Biology', 'icon': Icons.biotech, 'color': Colors.teal},
            {'name': 'Physics', 'icon': Icons.speed, 'color': Colors.red},
            {'name': 'Chemistry', 'icon': Icons.science, 'color': Colors.green},
            {'name': 'ICT', 'icon': Icons.computer, 'color': Colors.purple},
            {'name': 'General English', 'icon': Icons.language, 'color': Colors.orange},
          ];
        case 'Commerce':
          return [
            {'name': 'Accounting', 'icon': Icons.account_balance, 'color': Colors.blueGrey},
            {'name': 'Business Studies', 'icon': Icons.business, 'color': Colors.indigo},
            {'name': 'Economics', 'icon': Icons.trending_up, 'color': Colors.green},
            {'name': 'ICT', 'icon': Icons.computer, 'color': Colors.purple},
            {'name': 'General English', 'icon': Icons.language, 'color': Colors.orange},
          ];
        case 'Arts':
          return [
            {'name': 'Sinhala', 'icon': Icons.menu_book, 'color': Colors.brown},
            {'name': 'History', 'icon': Icons.history_edu, 'color': Colors.orange},
            {'name': 'Geography', 'icon': Icons.public, 'color': Colors.green},
            {'name': 'Political Science', 'icon': Icons.gavel, 'color': Colors.red},
            {'name': 'ICT', 'icon': Icons.computer, 'color': Colors.purple},
            {'name': 'General English', 'icon': Icons.language, 'color': Colors.orange},
          ];
        case 'Technology':
          return [
            {'name': 'SFT', 'icon': Icons.science_outlined, 'color': Colors.teal},
            {'name': 'ET', 'icon': Icons.engineering, 'color': Colors.blue},
            {'name': 'ICT', 'icon': Icons.computer, 'color': Colors.purple},
            {'name': 'General English', 'icon': Icons.language, 'color': Colors.orange},
          ];
        default:
          return [
            {'name': 'General', 'icon': Icons.folder, 'color': Colors.grey},
          ];
      }
    } 
    // University
    else if (grade == 'University') {
       return [
        {'name': 'Lecture Notes', 'icon': Icons.menu_book, 'color': Colors.blue},
        {'name': 'Assignments', 'icon': Icons.assignment, 'color': Colors.green},
        {'name': 'Past Papers', 'icon': Icons.history, 'color': Colors.orange},
        {'name': 'Research', 'icon': Icons.science, 'color': Colors.purple},
        {'name': 'Other', 'icon': Icons.folder_open, 'color': Colors.grey},
      ];
    }
    // O/L Logic (Grade 6-11)
    else {
      return [
        {'name': 'Maths', 'icon': Icons.calculate, 'color': Colors.blue},
        {'name': 'Science', 'icon': Icons.science, 'color': Colors.green},
        {'name': 'Sinhala', 'icon': Icons.menu_book, 'color': Colors.brown},
        {'name': 'English', 'icon': Icons.language, 'color': Colors.orange},
        {'name': 'History', 'icon': Icons.history_edu, 'color': Colors.red},
        {'name': 'Religion', 'icon': Icons.self_improvement, 'color': Colors.purple},
        {'name': 'ICT', 'icon': Icons.computer, 'color': Colors.indigo},
        {'name': 'Commerce', 'icon': Icons.store, 'color': Colors.teal},
        {'name': 'Health', 'icon': Icons.health_and_safety, 'color': Colors.pink},
        {'name': 'Geography', 'icon': Icons.public, 'color': Colors.lightGreen},
        {'name': 'Tamil', 'icon': Icons.translate, 'color': Colors.deepOrange},
        {'name': 'Other', 'icon': Icons.folder_open, 'color': Colors.grey},
      ];
    }
  }

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
      String uploadSubject = _selectedSubject ?? _subjects.first['name']; // Default to first available
      
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
                value: _subjects.any((s) => s['name'] == uploadSubject) ? uploadSubject : _subjects.first['name'],
                items: _subjects.map((s) => DropdownMenuItem<String>(value: s['name'], child: Text(s['name']))).toList(),
                onChanged: (val) => uploadSubject = val!,
                decoration: const InputDecoration(labelText: "Subject"),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performUpload(file, titleController.text, uploadSubject, user.displayName ?? "Unknown", user.uid);
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
      // Re-fetch user to ensure we have latest grade/stream
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
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: LoadingWidget()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedSubject ?? "Knowledge Hub"),
        leading: _selectedSubject != null 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => setState(() => _selectedSubject = null),
            )
          : null,
      ),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(),
          
          Expanded(
            child: _selectedSubject == null 
              ? _buildFolderGrid() 
              : _buildNotesList(),
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

  Widget _buildFolderGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        return GestureDetector(
          onTap: () => setState(() => _selectedSubject = subject['name']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (subject['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(subject['icon'], size: 24, color: subject['color']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text("Folder", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ).animate(delay: (50 * index).ms).slideX().fade(),
        );
      },
    );
  }

  Widget _buildNotesList() {
    // We already have _currentUser loaded
    final userGrade = _currentUser?.grade ?? '';
    final userSchool = _currentUser?.school ?? '';

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
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text("No $_selectedSubject notes for Grade $userGrade yet.", style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              TextButton(onPressed: _uploadNote, child: const Text("Upload the first one!"))
            ],
          ));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return GestureDetector(
              onTap: () => _openNote(note.fileUrl),
              child: _NoteTile(title: note.title, author: note.authorName, size: note.size),
            ).animate(delay: (50 * index).ms).fade().slideX();
          },
        );
      },
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
