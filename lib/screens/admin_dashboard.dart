import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Very light grey/blue background
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: const BackButton(color: Colors.black),
                title: Text(
                  "Admin Dashboard",
                  style: TextStyle(
                    color: innerBoxIsScrolled ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Gradient Background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo to Violet
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // Decorative Circles
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      // Content
                      Positioned(
                        bottom: 60,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             const Text(
                              "Overview",
                              style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1),
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseService().getReports(),
                              builder: (context, snapshot) {
                                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                return Text(
                                  "$count Pending Reports",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: const Color(0xFF6366F1),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF6366F1),
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: "Pending"),
                        Tab(text: "Resolved"),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: const TabBarView(
            children: [
              _ReportsList(status: 'pending'),
              _ReportsList(status: 'resolved'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsList extends StatelessWidget {
  final String status;
  const _ReportsList({required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  "All Caught Up!",
                  style: TextStyle(color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "No $status reports found.",
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final report = docs[index];
            return _ReportCard(report: report);
          },
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final QueryDocumentSnapshot report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final data = report.data() as Map<String, dynamic>;
    final reportId = report.id;
    final contentId = data['contentId'];
    final contentType = data['contentType'];
    final reason = data['reason'];
    final status = data['status'];
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header with Badge & Reason
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: contentType == 'post' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        contentType == 'post' ? Icons.article : Icons.person,
                        size: 14,
                        color: contentType == 'post' ? Colors.blue[700] : Colors.orange[800],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        contentType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11, 
                          fontWeight: FontWeight.bold,
                          color: contentType == 'post' ? Colors.blue[700] : Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reason,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 2. Content Area
          if (contentType == 'user')
            _buildUserContent(contentId)
          else
            _buildPostContent(contentId),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 3. Action Bar (Glassy look)
          if (isPending)
            Container(
              color: const Color(0xFFFAFAFA),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                   Expanded(
                    child: TextButton.icon(
                      onPressed: () => FirebaseService().resolveReport(reportId),
                      icon: const Icon(Icons.check, size: 18, color: Colors.grey),
                      label: Text("Dismiss", style: TextStyle(color: Colors.grey[700])),
                    ),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey[300]),
                  
                  // Contextual Delete/Ban
                  if (contentType == 'post')
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                           await FirebaseService().deletePost(contentId);
                           await FirebaseService().resolveReport(reportId);
                        },
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.orange),
                        label: const Text("Delete", style: TextStyle(color: Colors.orange)),
                      ),
                    ),
                  
                  if (contentType == 'post') Container(width: 1, height: 24, color: Colors.grey[300]),

                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _handleBan(context, contentId, contentType, reportId),
                      icon: const Icon(Icons.block, size: 18, color: Colors.red),
                      label: const Text("Ban", style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildUserContent(String userId) {
    return FutureBuilder<UserModel?>(
      future: FirebaseService().getUser(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
        final user = snapshot.data;
        if (user == null) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text("User unavailable (Deleted or Banned)", style: TextStyle(color: Colors.red)),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: NetworkImage(user.photoUrl),
                backgroundColor: Colors.grey[200],
                child: user.photoUrl.isEmpty ? const Icon(Icons.person, size: 36, color: Colors.grey) : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                user.email,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 8),
              if (user.isBanned)
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                   decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
                   child: const Text("BANNED", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                 ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostContent(String postId) {
    return FutureBuilder<PostModel?>(
      future: FirebaseService().getPost(postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
        }
        final post = snapshot.data;
        if (post == null) {
           return const Padding(padding: EdgeInsets.all(20), child: Text("Post deleted", style: TextStyle(color: Colors.grey)));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(post.authorPhotoUrl),
                        backgroundColor: Colors.grey[200],
                      ),
                      const SizedBox(width: 8),
                      Text(post.authorName, style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(post.content, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
                ],
              ),
            ),
            if (post.imageUrl?.isNotEmpty == true)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(post.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _handleBan(BuildContext context, String contentId, String contentType, String reportId) async {
      String? userIdToBan;
      if (contentType == 'user') {
        userIdToBan = contentId;
      } else if (contentType == 'post') {
          final post = await FirebaseService().getPost(contentId);
          userIdToBan = post?.authorId;
      }

      if (userIdToBan != null && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Ban User?"),
            content: const Text("This action cannot be easily undone. The user will be listed as banned."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              TextButton(
                onPressed: () async {
                  await FirebaseService().banUserSystem(userIdToBan!);
                  await FirebaseService().resolveReport(reportId);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Ban Forever", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
  }
}
