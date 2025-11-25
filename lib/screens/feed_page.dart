import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';

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
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              label: const Text("IQ 420", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              avatar: const Icon(Icons.bolt, size: 16, color: Colors.amber),
              backgroundColor: AppTheme.secondary,
              labelStyle: const TextStyle(color: Colors.white),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Post Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: AppTheme.primary, child: Text("C", style: TextStyle(color: Colors.white))),
                  const SizedBox(width: 12),
                  const Text("Ask a question...", style: TextStyle(color: Colors.grey)),
                  const Spacer(),
                  Icon(Icons.image_outlined, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
          
          // Feed Stream
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: _firebaseService.getPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  // Fallback to static data if Firebase fails (likely due to missing config)
                  return _buildStaticFeed();
                }

                final posts = snapshot.data ?? [];
                
                if (posts.isEmpty) {
                  // Fallback if no posts
                  return _buildStaticFeed();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return FeedCard(
                      type: post.type,
                      author: post.authorName,
                      school: post.school,
                      content: post.content,
                      likes: post.likes,
                      comments: post.comments,
                      isAchievement: post.isAchievement,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStaticFeed() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: const [
        // Post 1: Question
        FeedCard(
          type: 'Question',
          author: 'Sanduni Perera',
          school: 'Visakha Vidyalaya',
          content: 'Can someone explain the difference between Homologous and Analogous organs? Confused about the evolution part.',
          likes: 24,
          comments: 5,
        ),
        // Post 2: Achievement
        FeedCard(
          type: 'Achievement',
          author: 'Kasun Bandara',
          school: 'Royal College',
          content: 'Just got selected for the National Physics Olympiad pool! Thanks everyone for the help.',
          likes: 156,
          comments: 42,
          isAchievement: true,
        ),
      ],
    );
  }
}

class FeedCard extends StatelessWidget {
  final String type;
  final String author;
  final String school;
  final String content;
  final int likes;
  final int comments;
  final bool isAchievement;

  const FeedCard({
    super.key, 
    required this.type, 
    required this.author, 
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isAchievement ? Colors.green.shade100 : Colors.blue.shade100,
                child: Text(author.isNotEmpty ? author[0] : '?', style: TextStyle(color: isAchievement ? Colors.green : Colors.blue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(school, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              if (!isAchievement)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Text("QUESTION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(likes.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(width: 20),
              Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(comments.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}
