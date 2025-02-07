import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📩 **Send a message from the current user to another user**
  Future<void> sendMessage(String receiverId, String message) async {
    try {
      String? senderId = _auth.currentUser?.uid;
      if (senderId == null || message.trim().isEmpty) return;

      String chatId = getChatId(senderId, receiverId);

      var messageData = {
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save message to messages subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update last message for chat list
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': message.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'user1': senderId,
        'user2': receiverId,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  /// 📥 **Retrieve messages between two users in real-time**
  Stream<QuerySnapshot> getMessages(String receiverId) {
    String? senderId = _auth.currentUser?.uid;
    if (senderId == null) return const Stream.empty();

    String chatId = getChatId(senderId, receiverId);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// 🔍 **Get Chat ID (Ensures consistency in ordering)**
  String getChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join('_');
  }
}
