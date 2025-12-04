import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'feed_page.dart'; // For FeedCard
import '../widgets/loading_widget.dart';

class PostDetailsPage extends StatefulWidget {
  final String postId;
  final PostModel? post;

  const PostDetailsPage({super.key, required this.postId, this.post});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;
  PostModel? _post;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _post = widget.post;
      _isLoading = false;
    } else {
      _fetchPost();
    }
  }

  Future<void> _fetchPost() async {
    final post = await _firebaseService.getPost(widget.postId);
    if (mounted) {
      setState(() {
        _post = post;
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to comment")));
      return;
    }

    setState(() => _isSending = true);

    try {
      // Fetch user data for photo URL
      final userModel = await _firebaseService.getUser(user.uid);
      
      final comment = CommentModel(
        id: '',
        postId: widget.postId,
        authorName: user.displayName ?? "Anonymous",
        authorId: user.uid,
        authorPhotoUrl: userModel?.photoUrl.isNotEmpty == true ? userModel!.photoUrl : user.photoURL ?? '',
        content: _commentController.text.trim(),
        timestamp: DateTime.now(),
      );

      await _firebaseService.addComment(widget.postId, comment);
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to comment: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: LoadingWidget()));
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Discussion")),
        body: const Center(child: Text("Post not found")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Discussion")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Original Post
                FeedCard(
                  type: _post!.type,
                  authorId: _post!.authorId,
                  author: _post!.authorName,
                  authorPhotoUrl: _post!.authorPhotoUrl,
                  school: _post!.school,
                  content: _post!.content,
                  likes: _post!.likes,
                  comments: _post!.comments, // Note: This might be stale until refresh
                  isAchievement: _post!.isAchievement,
                ),
                const Divider(height: 32),
                const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),

                // Comments Stream
                StreamBuilder<List<CommentModel>>(
                  stream: _firebaseService.getComments(widget.postId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LoadingWidget());
                    }

                    final comments = snapshot.data ?? [];

                    if (comments.isEmpty) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No comments yet. Start the discussion!", style: TextStyle(color: Colors.grey)),
                      ));
                    }

                    return Column(
                      children: comments.map((comment) => _CommentTile(comment: comment)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Comment Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: "Add a comment...",
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30)), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _isSending ? null : _addComment,
                  icon: _isSending 
                    ? const LoadingWidget(size: 20) 
                    : const Icon(Icons.send, color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                backgroundImage: comment.authorPhotoUrl.isNotEmpty ? NetworkImage(comment.authorPhotoUrl) : null,
                child: comment.authorPhotoUrl.isEmpty 
                  ? const Icon(Icons.person, size: 14, color: AppTheme.primary)
                  : null,
              ),
              const SizedBox(width: 8),
              Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              Text(
                "${comment.timestamp.hour}:${comment.timestamp.minute.toString().padLeft(2, '0')}", 
                style: const TextStyle(color: Colors.grey, fontSize: 10)
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment.content, style: const TextStyle(fontSize: 14)),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
