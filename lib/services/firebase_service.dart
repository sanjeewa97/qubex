import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance; // This causes crash if not initialized
  
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // --- POSTS ---
  
  // Fetch posts as a stream for real-time updates
  Stream<List<PostModel>> getPosts() {
    if (Firebase.apps.isEmpty) {
      print("Firebase not initialized. Returning empty stream.");
      return Stream.value([]);
    }
    
    try {
      return _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return PostModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print("Error fetching posts: $e");
      return Stream.value([]);
    }
  }

  // Create a new post
  Future<void> createPost(PostModel post) async {
    try {
      await _firestore.collection('posts').add(post.toMap());
    } catch (e) {
      print("Error creating post: $e");
    }
  }

  // --- USERS ---

  // Get user details
  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
    return null;
  }
  
  // Create or update user
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      print("Error updating user: $e");
    }
  }
}
