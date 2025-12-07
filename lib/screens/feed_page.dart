import 'package:flutter/material.dart';
import 'dart:async';
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
  final ScrollController _scrollController = ScrollController();
  
  StreamSubscription? _postsSubscription;
  List<PostModel> _posts = [];
  bool _isLoadingInitial = true;
  String? _lastGrade;
  int _postsLimit = 10;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isFetchingMore && _postsLimit < 500) {
        _isFetchingMore = true;
        _postsLimit += 10;
        if (_lastGrade != null) {
          _setupPostsStream(_lastGrade!);
        }
      }
    }
  }

  void _setupPostsStream(String grade) {
    _postsSubscription?.cancel();
    _postsSubscription = _firebaseService.getPosts(grade, limit: _postsLimit).listen((newPosts) {
      if (mounted) {
        setState(() {
          _posts = newPosts;
          _isLoadingInitial = false;
          _isFetchingMore = false; // Reset flag when data arrives
        });
      }
    }, onError: (e) {
      print("Error fetching posts: $e");
      if (mounted) setState(() => _isFetchingMore = false);
    });
  }

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
                  BoxShadow(color: AppTheme.secondary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
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
      body: StreamBuilder<UserModel?>(
        stream: _firebaseService.getUserStream(AuthService().currentUser?.uid ?? ''),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting && _isLoadingInitial) {
             // Only show loading if we really don't have user data AND no posts yet
             // Actually, we need user data to know the grade.
             return const Center(child: LoadingWidget());
          }

          final user = userSnapshot.data;
          final userGrade = user?.grade ?? '';
          
          // Setup stream if grade changed (or first run)
          if (userGrade != _lastGrade) {
            _lastGrade = userGrade;
            _setupPostsStream(userGrade);
          }

          if (_isLoadingInitial && _posts.isEmpty) {
             return const Center(child: LoadingWidget());
          }

          final displayPosts = _posts.where((p) => !(user?.blockedUsers.contains(p.authorId) ?? false)).toList();

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: displayPosts.length + 1, // +1 for Header
            itemBuilder: (context, index) {
              if (index == 0) {
                 // Post Input Header
                 return Padding(
                   padding: const EdgeInsets.only(bottom: 20.0),
                   child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
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
                 );
              }

              if (displayPosts.isEmpty && index == 1) {
                  return Center(child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("No posts for Grade $userGrade yet.", style: Theme.of(context).textTheme.bodyMedium),
                    ));
              }
              
              if (displayPosts.isEmpty) return const SizedBox.shrink();

              final post = displayPosts[index - 1];
              final item = Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailsPage(postId: post.id, post: post)));
                  },
                  child: FeedCard(
                    postId: post.id, 
                    currentUserId: AuthService().currentUser?.uid ?? '',
                    type: post.type,
                    authorId: post.authorId,
                    author: post.authorName,
                    authorPhotoUrl: post.authorPhotoUrl,
                    school: post.school,
                    content: post.content,
                    likes: post.likes,
                    comments: post.comments,
                    isAchievement: post.isAchievement,
                    imageUrl: post.imageUrl, 
                    isEdited: post.isEdited,
                    isLiked: post.likedBy.contains(user?.id),
                    pollOptions: post.pollOptions,
                    pollVotes: post.pollVotes,
                    correctOptionIndex: post.correctOptionIndex,
                    onLike: () => _firebaseService.toggleLike(post.id, post.authorId),
                    onVote: (optionIndex) => _firebaseService.voteOnPoll(post.id, optionIndex),
                    postModel: post,
                  ),
                ),
              );

              // Only animate the first few items for initial load "wow" factor.
              // Scroll items should be instant for performance.
              // Index 0 is header, so posts start at index 1.
              if (index <= 5) {
                  return item.animate(delay: ((index - 1) * 100).ms).fade(duration: 400.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOut);
              }
              return item;
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
  final String? imageUrl; 
  final bool isEdited; // Add field
  final bool isLiked;
  final VoidCallback? onLike;
  final List<String> pollOptions;
  final Map<String, int> pollVotes;
  final int? correctOptionIndex;
  final Function(int)? onVote;
  final PostModel? postModel; // Add field for passing to edit screen

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
    this.imageUrl, 
    this.isEdited = false,
    this.isLiked = false,
    this.onLike,
    this.pollOptions = const [],
    this.pollVotes = const {},
    this.correctOptionIndex,
    this.onVote,
    this.postModel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isAchievement ? Border.all(color: AppTheme.accent.withValues(alpha: 0.5), width: 2) : Border.all(color: Colors.grey.shade100), // Light border instead of shadow
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
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      if (postModel != null) {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => CreatePostScreen(postToEdit: postModel)));
                      }
                    } else if (value == 'report') {
                      showDialog(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text("Report Post"),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(hintText: "Reason for reporting..."),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                              TextButton(
                                onPressed: () {
                                  if (controller.text.isEmpty) return;
                                  FirebaseService().reportContent(
                                    reporterId: currentUserId,
                                    contentId: postId,
                                    contentType: 'post',
                                    reason: controller.text,
                                  );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report submitted.")));
                                },
                                child: const Text("Report", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          );
                        }
                      );
                    } else if (value == 'block') {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Block $author?"),
                          content: const Text("You won't see their posts anymore."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                            TextButton(
                              onPressed: () async {
                                await FirebaseService().blockUser(currentUserId, authorId);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User blocked.")));
                              },
                              child: const Text("Block", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        )
                      );
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      if (currentUserId == authorId)
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text("Edit Post")])),

                      const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag_outlined, size: 20), SizedBox(width: 8), Text("Report Post")])),
                      
                      if (currentUserId != authorId)
                        const PopupMenuItem(value: 'block', child: Row(children: [Icon(Icons.block, size: 20, color: Colors.red), SizedBox(width: 8), Text("Block User", style: TextStyle(color: Colors.red))])),
                    ];
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: content, style: Theme.of(context).textTheme.bodyLarge),
                if (isEdited)
                  TextSpan(
                    text: " (edited)",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
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
