import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/loading_widget.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().currentUser?.uid;
    if (currentUserId == null) return const Scaffold(body: Center(child: Text("Error: Not logged in")));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Blocked Users", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: StreamBuilder<UserModel?>(
        stream: FirebaseService().getUserStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget());
          }
          
          final blockedIds = snapshot.data?.blockedUsers ?? [];
          if (blockedIds.isEmpty) {
             return const Center(child: Text("You haven't blocked anyone yet."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: blockedIds.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final blockedId = blockedIds[index];
              return FutureBuilder<UserModel?>(
                future: FirebaseService().getUser(blockedId),
                builder: (context, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 50, child: Center(child: LoadingWidget(size: 20)));
                  }
                  
                  final user = userSnap.data;
                  if (user == null) return const SizedBox.shrink(); // User might be deleted
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                      child: user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(user.school),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () async {
                        await FirebaseService().unblockUser(currentUserId, blockedId);
                        // StreamBuilder will auto-refresh the list
                      },
                      child: const Text("Unblock"),
                    ),
                  );
                }
              );
            },
          );
        }
      )
    );
  }
}
