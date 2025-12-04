import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import 'profile_setup_screen.dart';
import 'edit_profile_screen.dart';

import '../widgets/loading_widget.dart';
import 'notifications_page.dart';
import 'chat_screen.dart';
import '../models/post_model.dart';
import 'feed_page.dart'; // For FeedCard
import 'post_details_page.dart';
import 'onboarding_screen.dart';

class ProfilePage extends StatefulWidget {
  final String? userId; // If null, show current user
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final FirebaseService firebaseService = FirebaseService();
    final user = authService.currentUser;

    if (user == null) return const Center(child: Text("Please login"));

    final targetUserId = widget.userId ?? user.uid;
    final isCurrentUser = widget.userId == null || widget.userId == user.uid;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<UserModel?>(
        stream: Stream.fromFuture(firebaseService.getUser(targetUserId)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget());
          }

          final userModel = snapshot.data;
          final name = userModel?.name ?? user.displayName ?? "User";
          final school = userModel?.school ?? "Unknown School";
          final photoUrl = userModel?.photoUrl.isNotEmpty == true ? userModel!.photoUrl : user.photoURL;

          return NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 400,
                  pinned: true,
                  backgroundColor: AppTheme.primary,
                  leading: isCurrentUser 
                    ? null 
                    : IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                  actions: [
                    if (isCurrentUser)
                      IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()));
                        },
                        icon: StreamBuilder<int>(
                          stream: firebaseService.getUnreadNotificationCount(user.uid),
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;
                            return Stack(
                              children: [
                                const Icon(Icons.notifications_rounded, color: Colors.white),
                                if (count > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    if (isCurrentUser)
                      IconButton(
                        onPressed: () async {
                          final shouldSignOut = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Sign Out"),
                              content: const Text("Are you sure you want to sign out?"),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Sign Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );

                          if (shouldSignOut == true) {
                            await authService.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                                (route) => false,
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                              child: photoUrl == null 
                                ? const Icon(Icons.person, size: 50, color: AppTheme.primary)
                                : null,
                            ),
                          ).animate().scale(),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ).animate().fadeIn().slideY(begin: 0.5, end: 0),
                          Text(
                            school,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ).animate().fadeIn().slideY(begin: 0.5, end: 0, delay: 100.ms),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatItem(label: "IQ Score", value: "${userModel?.iqScore ?? 0}"),
                              Container(height: 20, width: 1, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
                              _StatItem(label: "Rank", value: userModel?.rank ?? "Novice"),
                              Container(height: 20, width: 1, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
                              _StatItem(label: "Solved", value: "${userModel?.solvedCount ?? 0}"),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (!isCurrentUser || isCurrentUser) // Show buttons for both
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (isCurrentUser) {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(user: userModel)));
                                        } else {
                                          _startChat(context, user.uid, targetUserId, userModel!);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppTheme.primary,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      child: Text(isCurrentUser ? "Edit Profile" : "Message", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppTheme.primary,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: "Activity"),
                        Tab(text: "Badges"),
                        Tab(text: "About"),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Activity Tab
                _buildActivityTab(firebaseService, targetUserId),
                
                // Badges Tab
                _buildBadgesTab(),

                // About Tab
                _buildAboutTab(userModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityTab(FirebaseService firebaseService, String targetUserId) {
    return StreamBuilder<List<PostModel>>(
      stream: firebaseService.getUserPosts(targetUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingWidget());
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.post_add, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("No activity yet", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
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
              ).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.1, end: 0),
            );
          },
        );
      },
    );
  }

  Widget _buildBadgesTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        _AchievementItem(title: "First Question", desc: "Asked your first question", icon: Icons.star, color: Colors.amber),
        _AchievementItem(title: "Helper", desc: "Answered 5 questions", icon: Icons.handshake, color: Colors.blue),
        _AchievementItem(title: "Scholar", desc: "Uploaded 10 notes", icon: Icons.book, color: Colors.purple),
        _AchievementItem(title: "Top 10", desc: "Reached top 10 in leaderboard", icon: Icons.emoji_events, color: Colors.orange),
      ],
    );
  }

  Widget _buildAboutTab(UserModel? userModel) {
    if (userModel == null) return const SizedBox();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _InfoTile(icon: Icons.school, title: "School", value: userModel.school),
        _InfoTile(icon: Icons.class_, title: "Grade", value: userModel.grade),
        if (userModel.stream.isNotEmpty)
          _InfoTile(icon: Icons.category, title: "Stream", value: userModel.stream),
        _InfoTile(icon: Icons.cake, title: "Age", value: "${userModel.age} Years"),
        _InfoTile(icon: Icons.person, title: "Gender", value: userModel.gender),
      ],
    );
  }

  void _startChat(BuildContext context, String currentUserId, String otherUserId, UserModel otherUser) async {
    try {
      final chatId = await FirebaseService().createChat(currentUserId, otherUserId);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: chatId, otherUser: otherUser),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to start chat")));
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _AchievementItem({required this.icon, required this.color, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(desc, style: Theme.of(context).textTheme.bodySmall),
            ],
          )
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondary, size: 20),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
