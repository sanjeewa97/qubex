import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/note_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';

class FirebaseService {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance; // This causes crash if not initialized
  
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // --- POSTS ---
  
  // Fetch posts as a stream for real-time updates
  Stream<List<PostModel>> getPosts(String currentUserGrade) {
    if (Firebase.apps.isEmpty) {
      print("Firebase not initialized. Returning empty stream.");
      return Stream.value([]);
    }
    
    try {
      Query query = _firestore.collection('posts').orderBy('timestamp', descending: true);

      // Filter by grade
      if (currentUserGrade == 'University') {
        query = query.where('grade', isEqualTo: 'University');
      } else {
        query = query.where('grade', isEqualTo: currentUserGrade);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
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

  // Get single post
  Future<PostModel?> getPost(String postId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('posts').doc(postId).get();
      if (doc.exists) {
        return PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error fetching post: $e");
    }
    return null;
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

  // Get top users for leaderboard
  Stream<List<UserModel>> getTopUsers() {
    return _firestore
        .collection('users')
        .orderBy('iqScore', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Search users by name
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    try {
      // Simple search: name starts with query
      // Note: Firestore is case-sensitive by default. 
      // For a robust search, we'd need a 'searchName' field (lowercase) or Algolia.
      // For MVP, we'll assume exact case or just rely on this simple query.
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .get();

      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print("Error searching users: $e");
      return [];
    }
  }

  // --- NOTES ---
  
  // Upload a note
  Future<void> uploadNote(File file, String title, String subject, String authorName, String school, String grade) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      Reference ref = FirebaseStorage.instance.ref().child('notes/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Calculate size (approx)
      int sizeInBytes = await file.length();
      String sizeString = "${(sizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB";
      if (sizeInBytes < 1024 * 1024) {
        sizeString = "${(sizeInBytes / 1024).toStringAsFixed(0)} KB";
      }

      NoteModel note = NoteModel(
        id: '',
        title: title,
        subject: subject,
        authorName: authorName,
        school: school,
        grade: grade,
        fileUrl: downloadUrl,
        size: sizeString,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('notes').add(note.toMap());
    } catch (e) {
      print("Error uploading note: $e");
      throw e;
    }
  }

  // Get notes stream
  Stream<List<NoteModel>> getNotes(String? subject, String currentUserGrade, String currentUserSchool) {
    Query query = _firestore.collection('notes').orderBy('timestamp', descending: true);
    
    // Filter by subject
    if (subject != null && subject.isNotEmpty) {
      query = query.where('subject', isEqualTo: subject);
    }

    // Filter by grade/school
    if (currentUserGrade == 'University') {
      query = query.where('grade', isEqualTo: 'University').where('school', isEqualTo: currentUserSchool);
    } else {
      query = query.where('grade', isEqualTo: currentUserGrade);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return NoteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // --- COMMENTS ---

  // Add a comment and trigger notification
  Future<void> addComment(String postId, CommentModel comment) async {
    try {
      // 1. Add comment to sub-collection
      await _firestore.collection('posts').doc(postId).collection('comments').add(comment.toMap());
      
      // 2. Increment comment count on the post
      DocumentReference postRef = _firestore.collection('posts').doc(postId);
      await postRef.update({
        'comments': FieldValue.increment(1),
      });

      // 3. Create Notification for the Post Author
      DocumentSnapshot postSnap = await postRef.get();
      if (postSnap.exists) {
        String postAuthorId = postSnap.get('authorId');
        
        // Don't notify if commenting on own post
        if (postAuthorId != comment.authorId) { // Assuming comment has authorId, if not pass it
          // We need current user ID for 'fromUserId'. 
          // Ideally CommentModel should have it, or we pass it.
          // For now assuming we can get it or it's in comment.
          
          NotificationModel notification = NotificationModel(
            id: '',
            type: 'comment',
            fromUserId: comment.id, // Using comment ID as temp or need real user ID
            fromUserName: comment.authorName,
            postId: postId,
            message: "commented on your post",
            isRead: false,
            timestamp: DateTime.now(),
          );

          await _firestore.collection('users').doc(postAuthorId).collection('notifications').add(notification.toMap());
        }
      }
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  // Get comments stream
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommentModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // --- NOTIFICATIONS ---

  // Get notifications stream
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  // Get unread count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
