import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'search_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GroupInfoScreen extends StatelessWidget {
  final String chatId;

  const GroupInfoScreen({super.key, required this.chatId});

  void _leaveGroup(BuildContext context) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Group"),
        content: const Text("Are you sure you want to leave this group?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Leave", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseService().leaveGroupChat(chatId, currentUser.uid);
        if (context.mounted) {
          Navigator.popUntil(context, (route) => route.isFirst); // Go back to home
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to leave group")),
          );
        }
      }
    }
  }

  void _addMember(BuildContext context) {
    // Navigate to a user selection screen (reusing SearchPage or similar)
    // For now, let's just show a snackbar as placeholder or implement a simple dialog
    // Ideally, we reuse the search logic from CreateGroupScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemberScreen(chatId: chatId),
      ),
    );
  }

  Future<void> _updateGroupImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);
      try {
        await FirebaseService().updateGroupImage(chatId, imageFile);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Group icon updated")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to update group icon")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Group Info", style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.secondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<ChatModel>(
        stream: FirebaseService().getChatStream(chatId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Group not found"));
          }

          final chat = snapshot.data!;
          final isAdmin = chat.adminIds?.contains(currentUser?.uid) ?? false;

          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                width: double.infinity,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: isAdmin ? () => _updateGroupImage(context) : null,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: chat.groupImage != null ? NetworkImage(chat.groupImage!) : null,
                            backgroundColor: Colors.grey[200],
                            child: chat.groupImage == null ? const Icon(Icons.group, size: 40, color: Colors.grey) : null,
                          ),
                        ),
                        if (isAdmin)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 12, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      chat.groupName ?? "Group Chat",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${chat.participants.length} members",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Members List
              Expanded(
                child: ListView.builder(
                  itemCount: chat.participants.length,
                  itemBuilder: (context, index) {
                    final userId = chat.participants[index];
                    return FutureBuilder<UserModel?>(
                      future: FirebaseService().getUser(userId),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) return const SizedBox.shrink();
                        final user = userSnapshot.data!;
                        final isUserAdmin = chat.adminIds?.contains(userId) ?? false;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(user.photoUrl),
                          ),
                          title: Text(user.name),
                          subtitle: isUserAdmin ? const Text("Admin", style: TextStyle(color: AppTheme.primary, fontSize: 12)) : null,
                          trailing: (isAdmin && userId != currentUser?.uid) 
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () {
                                  // TODO: Remove member
                                },
                              )
                            : null,
                        );
                      },
                    );
                  },
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    if (isAdmin)
                      ListTile(
                        leading: const Icon(Icons.person_add, color: AppTheme.primary),
                        title: const Text("Add Member", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                        onTap: () => _addMember(context),
                      ),
                    ListTile(
                      leading: const Icon(Icons.exit_to_app, color: Colors.red),
                      title: const Text("Leave Group", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      onTap: () => _leaveGroup(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AddMemberScreen extends StatefulWidget {
  final String chatId;
  const AddMemberScreen({super.key, required this.chatId});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isLoading = false;

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await FirebaseService().searchUsers(query);
      // TODO: Filter out existing members
      setState(() {
        _searchResults = results;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addMember(UserModel user) async {
    try {
      await FirebaseService().addMemberToGroup(widget.chatId, user.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${user.name} added to group")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add member")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Member"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: const InputDecoration(
                hintText: "Search users...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundImage: NetworkImage(user.photoUrl)),
                        title: Text(user.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _addMember(user),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
