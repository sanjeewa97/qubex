import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/note_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

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
  
  // Fetch posts by a specific user
  Stream<List<PostModel>> getUserPosts(String userId) {
    try {
      return _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return PostModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print("Error fetching user posts: $e");
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

  // Save user FCM token
  Future<void> saveUserToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    } catch (e) {
      print("Error saving user token: $e");
    }
  }
  
  // Create or update user
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      print("Error updating user: $e");
    }
  }

  // Upload profile photo
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$userId.jpg');

      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update user document with new photo URL
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': downloadUrl,
        'avatarUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      print("Error uploading profile photo: $e");
      rethrow;
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
      // Case-insensitive search using searchName
      String searchKey = query.toLowerCase();
      
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('searchName', isGreaterThanOrEqualTo: searchKey)
          .where('searchName', isLessThan: '${searchKey}z')
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
  // --- CHAT ---

  // Create or get existing chat
  Future<String> createChat(String currentUserId, String otherUserId) async {
    try {
      // Check if chat already exists
      QuerySnapshot snapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in snapshot.docs) {
        List<dynamic> participants = doc['participants'];
        if (participants.contains(otherUserId)) {
          return doc.id; // Chat exists
        }
      }

      // Create new chat
      DocumentReference ref = await _firestore.collection('chats').add({
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': {
          currentUserId: 0,
          otherUserId: 0,
        },
      });
      return ref.id;
    } catch (e) {
      print("Error creating chat: $e");
      throw e;
    }
  }

  // Create group chat
  Future<String> createGroupChat(String name, File? image, List<String> userIds) async {
    try {
      String? imageUrl;
      if (image != null) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_group_${userIds.hashCode}';
        Reference ref = FirebaseStorage.instance.ref().child('group_images/$fileName');
        UploadTask uploadTask = ref.putFile(image);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      Map<String, int> unreadCounts = {};
      for (var id in userIds) {
        unreadCounts[id] = 0;
      }

      DocumentReference ref = await _firestore.collection('chats').add({
        'participants': userIds,
        'lastMessage': 'Group created',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': unreadCounts,
        'isGroup': true,
        'groupName': name,
        'groupImage': imageUrl,
        'adminIds': [userIds.first], // Assuming first user is creator/admin
      });
      return ref.id;
    } catch (e) {
      print("Error creating group chat: $e");
      throw e;
    }
  }

  // Leave group chat
  Future<void> leaveGroupChat(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'participants': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayRemove([userId]), // Remove from admins if applicable
      });
    } catch (e) {
      print("Error leaving group chat: $e");
      throw e;
    }
  }

  // Add member to group
  Future<void> addMemberToGroup(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'participants': FieldValue.arrayUnion([userId]),
        'unreadCounts.$userId': 0, // Initialize unread count
      });
    } catch (e) {
      print("Error adding member to group: $e");
      throw e;
    }
  }

  // Update group image
  Future<void> updateGroupImage(String chatId, File image) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_group_$chatId';
      Reference ref = FirebaseStorage.instance.ref().child('group_images/$fileName');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('chats').doc(chatId).update({
        'groupImage': imageUrl,
      });
    } catch (e) {
      print("Error updating group image: $e");
      throw e;
    }
  }
  
  // Upload chat attachment
  Future<String> uploadChatAttachment(File file, String chatId) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      Reference ref = FirebaseStorage.instance.ref().child('chat_attachments/$chatId/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading chat attachment: $e");
      throw e;
    }
  }

  // Get chats stream
  Stream<List<ChatModel>> getChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatModel.fromFirestore(doc);
      }).toList();
    });
  }

  // Get single chat stream
  Stream<ChatModel> getChatStream(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      return ChatModel.fromFirestore(doc);
    });
  }

  // Get messages stream
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromFirestore(doc);
      }).toList();
    });
  }

  // Send message
  Future<void> sendMessage(String chatId, MessageModel message, List<String> otherUserIds) async {
    try {
      // 1. Add message to sub-collection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // 2. Update chat metadata (last message, time, unread count)
      Map<String, dynamic> updates = {
        'lastMessage': message.attachmentUrl != null 
            ? (message.attachmentType == 'image' ? '📷 Image' : '📎 Attachment') 
            : message.content,
        'lastMessageTime': FieldValue.serverTimestamp(),
      };

      for (var userId in otherUserIds) {
        updates['unreadCounts.$userId'] = FieldValue.increment(1);
      }

      await _firestore.collection('chats').doc(chatId).update(updates);
    } catch (e) {
      print("Error sending message: $e");
      throw e;
    }
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCounts.$userId': 0,
      });
    } catch (e) {
      print("Error marking chat as read: $e");
    }
  }
}
