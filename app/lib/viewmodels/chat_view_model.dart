import 'package:app/data/constants.dart';
import 'package:app/models/room_model.dart';
import 'package:app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/models/chat_message_model.dart';

class ChatViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final String roomId;
  ChatViewModel({required this.roomId});

  Future<void> sendMessage(
    String message,
    String sender,
    String playerId,
    String roomId,
  ) async {
    try {
      if (message.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(K.roomCollection)
            .doc(roomId)
            .collection('messages')
            .add({
              'text': message,
              'sender': sender,
              'timestamp': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Stream<List<ChatMessage>> getMessagesStream(String roomCode) {
    return FirebaseFirestore.instance
        .collection(K.roomCollection)
        .where('roomCode', isEqualTo: roomCode)
        .limit(1)
        .get()
        .asStream()
        .map((event) {
          var doc = event.docs.first;

          var room = RoomModel.fromJson(doc.data());

          return [] as List<ChatMessage>;
        });

    // return FirebaseFirestore.instance
    //   .collection('Room')
    //   .doc
    // .collectionGroup('playerMessages')
    // .where('roomId', isEqualTo: roomId) // 🔍 filter
    // .orderBy('timestamp')
    // .snapshots()
    // .map(
    //   (snapshot) =>
    //       snapshot.docs
    //           .map((doc) => ChatMessage.fromDocument(doc))
    //           .toList(),
    // );
  }
}
