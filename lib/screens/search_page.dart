import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/note_model.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import 'post_details_page.dart';

import '../services/auth_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  
  String _query = "";
  List<UserModel> _userResults = [];
  List<PostModel> _postResults = [];
  List<NoteModel> _noteResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _query = "";
        _userResults = [];
        _postResults = [];
        _noteResults = [];
      });
      return;
    }

    setState(() {
      _query = query;
      _isLoading = true;
    });

    // Fetch user details for filtering
    final currentUser = _authService.currentUser;
    final userModel = currentUser != null ? await _firebaseService.getUser(currentUser.uid) : null;
    final userGrade = userModel?.grade ?? '';
    final userSchool = userModel?.school ?? '';

    // 1. Search Users (Backend)
    final users = await _firebaseService.searchUsers(query);

    // 2. Search Posts (Client-side filtering for MVP)
    // Fetch recent posts and filter. In production, use Algolia or similar.
    final allPostsStream = _firebaseService.getPosts(userGrade);
    final allPosts = await allPostsStream.first; // Get current snapshot
    final posts = allPosts.where((post) => 
      post.content.toLowerCase().contains(query.toLowerCase()) || 
      post.authorName.toLowerCase().contains(query.toLowerCase())
    ).toList();

    // 3. Search Notes (Client-side filtering for MVP)
    final allNotesStream = _firebaseService.getNotes(null, userGrade, userSchool);
    final allNotes = await allNotesStream.first;
    final notes = allNotes.where((note) => 
      note.title.toLowerCase().contains(query.toLowerCase()) ||
      note.subject.toLowerCase().contains(query.toLowerCase())
    ).toList();

    if (mounted) {
      setState(() {
        _userResults = users;
        _postResults = posts;
        _noteResults = notes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Search users, posts, notes...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          style: const TextStyle(color: Colors.black, fontSize: 18),
          onChanged: (value) {
            // Debounce could be added here
            _performSearch(value);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: "Users"),
            Tab(text: "Posts"),
            Tab(text: "Notes"),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: LoadingWidget())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildUserList(),
              _buildPostList(),
              _buildNoteList(),
            ],
          ),
    );
  }

  Widget _buildUserList() {
    if (_query.isEmpty) return const Center(child: Text("Type to search users"));
    if (_userResults.isEmpty) return const Center(child: Text("No users found"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            child: user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(user.school),
          onTap: () {
            // Navigate to user profile (future feature)
          },
        ).animate().fadeIn().slideX();
      },
    );
  }

  Widget _buildPostList() {
    if (_query.isEmpty) return const Center(child: Text("Type to search posts"));
    if (_postResults.isEmpty) return const Center(child: Text("No posts found"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _postResults.length,
      itemBuilder: (context, index) {
        final post = _postResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: post.authorPhotoUrl.isNotEmpty ? NetworkImage(post.authorPhotoUrl) : null,
                    child: post.authorPhotoUrl.isEmpty ? const Icon(Icons.person, size: 12) : null,
                  ),
                  const SizedBox(width: 8),
                  Text(post.authorName, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailsPage(postId: post.id, post: post)));
            },
          ),
        ).animate().fadeIn().slideY();
      },
    );
  }

  Widget _buildNoteList() {
    if (_query.isEmpty) return const Center(child: Text("Type to search notes"));
    if (_noteResults.isEmpty) return const Center(child: Text("No notes found"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _noteResults.length,
      itemBuilder: (context, index) {
        final note = _noteResults[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf, color: AppTheme.primary),
          ),
          title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${note.subject} • ${note.authorName}"),
          onTap: () {
            // Open note logic (same as NotesPage)
          },
        ).animate().fadeIn().slideX();
      },
    );
  }
}
