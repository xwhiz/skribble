import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/models/chat_message_model.dart';

class ChatViewModel {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String roomId;

  ChatViewModel({required this.roomId});

  Future<void> sendMessage(String messageText) async {
    if (messageText.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final message = ChatMessage(
      name: user.displayName ?? 'Anonymous',
      message: messageText.trim(),
      timestamp: Timestamp.now(),
    );

    await _db.collection('playerbook').add(message.toMap(roomId));
  }

  Stream<List<ChatMessage>> getMessagesStream(Timestamp loginTime) {
    return _db
        .collection('playerbook')
        .where('roomId', isEqualTo: roomId)
        .orderBy('timestamp')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatMessage.fromDocument(doc))
                  .where((msg) => msg.timestamp.compareTo(loginTime) >= 0)
                  .toList(),
        );
  }
}
