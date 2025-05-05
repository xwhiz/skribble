import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get playerbookCollection => _db.collection('playerbook');

  // Add a message to the playerbook collection
  Future<void> sendMessage(String sender, String message) async {
    try {
      await playerbookCollection.add({
        'name': sender,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error sending message: $e');
    }
  }

  // Get real-time updates from the playerbook collection
  Stream<QuerySnapshot> getMessages() {
    return playerbookCollection
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
