import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'create_post_screen.dart';
import 'post_details_page.dart';
import 'profile_page.dart';

import 'search_page.dart';
import 'leaderboard_page.dart';
import '../widgets/loading_widget.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QUBEX"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardPage()));
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppTheme.secondary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                ]
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt, size: 16, color: AppTheme.accent),
                  SizedBox(width: 4),
                  Text("IQ 420", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                ],
              ),
            ),
          )
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: _firebaseService.getUser(AuthService().currentUser?.uid ?? ''),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget());
          }

          final user = userSnapshot.data;
          final userGrade = user?.grade ?? '';

          return StreamBuilder<List<PostModel>>(
            stream: _firebaseService.getPosts(userGrade),
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

              final posts = snapshot.data ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Post Input
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primary,
                            backgroundImage: user?.photoUrl.isNotEmpty == true ? NetworkImage(user!.photoUrl) : null,
                            child: user?.photoUrl.isEmpty == true ? const Icon(Icons.person, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 12),
                          Text("Ask a question...", style: Theme.of(context).textTheme.bodyMedium),
                          const Spacer(),
                          Icon(Icons.image_outlined, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ).animate().fade().slideY(begin: 0.2, end: 0, duration: 400.ms),
                  
                  const SizedBox(height: 20),
                  
                  if (posts.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("No posts for Grade $userGrade yet.", style: Theme.of(context).textTheme.bodyMedium),
                    )),

                  // Dynamic Posts
                  ...posts.asMap().entries.map((entry) {
                    int index = entry.key;
                    PostModel post = entry.value;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailsPage(postId: post.id, post: post)));
                      },
                      child: FeedCard(
                        type: post.type,
                        authorId: post.authorId,
                        author: post.authorName,
                        authorPhotoUrl: post.authorPhotoUrl,
                        school: post.school,
                        content: post.content,
                        likes: post.likes,
                        comments: post.comments,
                        isAchievement: post.isAchievement,
                      ).animate(delay: (100 * index).ms).fade().slideX(begin: 0.1, end: 0),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ).animate().scale(delay: 500.ms),
    );
  }
}

class FeedCard extends StatelessWidget {
  final String type;
  final String authorId;
  final String author;
  final String authorPhotoUrl;
  final String school;
  final String content;
  final int likes;
  final int comments;
  final bool isAchievement;

  const FeedCard({
    super.key,
    required this.type,
    required this.authorId,
    required this.author,
    this.authorPhotoUrl = '',
    required this.school,
    required this.content,
    required this.likes,
    required this.comments,
    this.isAchievement = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isAchievement ? Border.all(color: AppTheme.accent.withOpacity(0.5), width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userId: authorId)));
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isAchievement ? AppTheme.accent : AppTheme.primary.withOpacity(0.1),
                  backgroundImage: authorPhotoUrl.isNotEmpty ? NetworkImage(authorPhotoUrl) : null,
                  child: authorPhotoUrl.isEmpty 
                    ? Icon(isAchievement ? Icons.emoji_events : Icons.person, color: isAchievement ? Colors.white : AppTheme.primary)
                    : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text(school, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAchievement ? AppTheme.accent.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(type, style: TextStyle(color: isAchievement ? AppTheme.accent.withOpacity(1) : AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(content, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text("$likes", style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text("$comments", style: TextStyle(color: Colors.grey.shade600)),
              const Spacer(),
              Icon(Icons.share_outlined, size: 20, color: Colors.grey.shade400),
            ],
          )
        ],
      ),
    );
  }
}
