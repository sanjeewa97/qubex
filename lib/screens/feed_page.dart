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
              child: StreamBuilder<UserModel?>(
                    stream: FirebaseService().getUserStream(AuthService().currentUser?.uid ?? ''),
                    builder: (context, snapshot) {
                      final iq = snapshot.data?.iqScore ?? 0;
                      return Row(
                        children: [
                          const Icon(Icons.bolt, size: 16, color: AppTheme.accent),
                          const SizedBox(width: 4),
                          Text("IQ ${iq.toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                        ],
                      );
                    }
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
                        postId: post.id, // Add postId
                        currentUserId: AuthService().currentUser?.uid ?? '', // Add currentUserId
                        type: post.type,
                        authorId: post.authorId,
                        author: post.authorName,
                        authorPhotoUrl: post.authorPhotoUrl,
                        school: post.school,
                        content: post.content,
                        likes: post.likes,
                        comments: post.comments,
                        isAchievement: post.isAchievement,
                        imageUrl: post.imageUrl, // Add imageUrl usage
                        isLiked: post.likedBy.contains(user?.id),
                        pollOptions: post.pollOptions,
                        pollVotes: post.pollVotes,
                        correctOptionIndex: post.correctOptionIndex,
                        onLike: () => _firebaseService.toggleLike(post.id, post.authorId),
                        onVote: (optionIndex) => _firebaseService.voteOnPoll(post.id, optionIndex),
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
  final String postId;
  final String currentUserId;
  final String type;
  final String authorId;
  final String author;
  final String authorPhotoUrl;
  final String school;
  final String content;
  final int likes;
  final int comments;
  final bool isAchievement;
  final String? imageUrl; // Add field
  final bool isLiked;
  final VoidCallback? onLike;
  final List<String> pollOptions;
  final Map<String, int> pollVotes;
  final int? correctOptionIndex;
  final Function(int)? onVote;

  const FeedCard({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.type,
    required this.authorId,
    required this.author,
    this.authorPhotoUrl = '',
    required this.school,
    required this.content,
    required this.likes,
    required this.comments,
    this.isAchievement = false,
    this.imageUrl, // Add imageUrl to constructor
    this.isLiked = false,
    this.onLike,
    this.pollOptions = const [],
    this.pollVotes = const {},
    this.correctOptionIndex,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isAchievement ? Border.all(color: AppTheme.accent.withValues(alpha: 0.5), width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userId: authorId)));
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isAchievement ? AppTheme.accent : AppTheme.primary.withValues(alpha: 0.1),
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
                    color: isAchievement ? AppTheme.accent.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(type, style: TextStyle(color: isAchievement ? AppTheme.accent.withValues(alpha: 1) : AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          Text(content, style: Theme.of(context).textTheme.bodyLarge),
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
             const SizedBox(height: 12),
             ClipRRect(
               borderRadius: BorderRadius.circular(12),
               child: Image.network(imageUrl!, width: double.infinity, fit: BoxFit.cover),
             ),
          ],
          const SizedBox(height: 16),

          // Poll/Quiz Rendering
          if (pollOptions.isNotEmpty) ...[
            _buildPollOptions(),
            const SizedBox(height: 16),
          ],

          // Actions
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border, 
                      size: 20, 
                      color: isLiked ? Colors.red : Colors.grey.shade400
                    ).animate(target: isLiked ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms),
                    const SizedBox(width: 4),
                    Text("$likes", style: TextStyle(color: isLiked ? Colors.red : Colors.grey.shade600)),
                  ],
                ),
              ),
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

  Widget _buildPollOptions() {
    final hasVoted = pollVotes.containsKey(currentUserId);
    final totalVotes = pollVotes.length;
    final isQuiz = correctOptionIndex != null;

    return Column(
      children: List.generate(pollOptions.length, (index) {
        final option = pollOptions[index];
        final voteCount = pollVotes.values.where((v) => v == index).length;
        final percentage = totalVotes > 0 ? voteCount / totalVotes : 0.0;
        final isSelected = pollVotes[currentUserId] == index;
        final isCorrect = isQuiz && index == correctOptionIndex;

        Color borderColor = Colors.grey.shade200;
        Color fillColor = Colors.white;
        Color textColor = Colors.black;

        if (hasVoted) {
          if (isQuiz) {
            if (isCorrect) {
              borderColor = Colors.green;
              fillColor = Colors.green.withValues(alpha: 0.1);
              textColor = Colors.green;
            } else if (isSelected) {
              borderColor = Colors.red;
              fillColor = Colors.red.withValues(alpha: 0.1);
              textColor = Colors.red;
            }
          } else {
            // Poll
            if (isSelected) {
              borderColor = AppTheme.primary;
              textColor = AppTheme.primary;
            }
          }
        }

        return GestureDetector(
          onTap: hasVoted ? null : () => onVote?.call(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              color: fillColor,
            ),
            child: Stack(
              children: [
                if (hasVoted) // Show progress bar for both Polls AND Quizzes
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.transparent,
                      color: isQuiz 
                        ? (isCorrect ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1))
                        : AppTheme.primary.withValues(alpha: 0.1),
                      minHeight: 48,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option, 
                          style: TextStyle(
                            color: textColor, 
                            fontWeight: hasVoted && isSelected ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                      ),
                      if (hasVoted) ...[
                        Text(
                          "${(percentage * 100).toStringAsFixed(1)}%", 
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(width: 8),
                        if (isQuiz && isCorrect)
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        if (isQuiz && isSelected && !isCorrect)
                          const Icon(Icons.cancel, color: Colors.red, size: 20),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
