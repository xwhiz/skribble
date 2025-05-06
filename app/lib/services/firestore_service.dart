import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

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


  // Matchmaking Service
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final maxPlayersPerRoom = 8;
  
  //room collection reference
  CollectionReference get _roomsCollection => _db.collection('Room');
    
  Future<String> createRoom() async{
    String roomCode = _generateRoomCode();

    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Room data structure
    Map<String, dynamic> roomData = {
      'roomCode': roomCode,
      'createdAt': FieldValue.serverTimestamp(),
      'currentPlayers': 1,
      'maxPlayers': maxPlayersPerRoom,
      'status': 'notFull', // full, notFUll
      'players': [
        {
          'uid': currentUser.uid,
          'displayName': currentUser.displayName ?? 'Player',
          'score': 0,
          'joinedAt': FieldValue.serverTimestamp()
        }
      ],
    };

    DocumentReference roomRef = await _roomsCollection.add(roomData);
    print('Room created with ID: ${roomRef.id}');
    return roomRef.id;
  }

  // Join a room
  Future<Map<String, dynamic>> joinRoom() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    } 
  
    // Find Available Room with Space
    QuerySnapshot availableRooms = await _roomsCollection
      .where('status', isEqualTo: 'notFull')
      .where('currentPlayers', isLessThan: maxPlayersPerRoom)
      .orderBy('currentPlayers', descending: true)
      .limit(1)
      .get(); 

    if (availableRooms.docs.isNotEmpty) {
      // Join existing room
      DocumentReference roomRef = availableRooms.docs.first.reference;
      DocumentSnapshot roomSnap = availableRooms.docs.first;
      Map<String, dynamic> roomData = roomSnap.data() as Map<String, dynamic>;
      
      // Add player to room
      List players = roomData['players'] ?? [];
      players.add({
        'uid': currentUser.uid,
        'displayName': currentUser.displayName ?? 'Player',
        'score': 0,
        'joinedAt': FieldValue.serverTimestamp()
      });
      
      // Update room data
      bool roomFull = players.length >= maxPlayersPerRoom;
      await roomRef.update({
        'currentPlayers': FieldValue.increment(1),
        'players': players,
        'status': roomFull ? 'full' : 'notFull',
      });
      
      return {
        'roomId': roomRef.id,
        'isNewRoom': false,
        'status': players.length >= maxPlayersPerRoom ? 'full' : 'notFull',
      };
    } else {
      // Create new room since none are available
      String roomId = await createRoom();
      return {
        'roomId': roomId,
        'isNewRoom': true,
        'status': 'notFull',
      };
    }
  }

  // Leave a room
  Future<void> leaveRoom(String roomId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    DocumentReference roomRef = _roomsCollection.doc(roomId);
    DocumentSnapshot roomSnap = await roomRef.get();
    
    if (!roomSnap.exists) {
      throw Exception('Room not found');
    }
    
    Map<String, dynamic> roomData = roomSnap.data() as Map<String, dynamic>;
    List players = roomData['players'] ?? [];
    
    // Remove current player
    players.removeWhere((player) => player['uid'] == currentUser.uid);
    
    if (players.isEmpty) {
      // Delete room if no players left
      await roomRef.delete();
    } else {
      // Update room data
      await roomRef.update({
        'currentPlayers': FieldValue.increment(-1),
        'players': players,
        'status': 'notFull',
      });
    }
  }
  
    // Listen to room changes
  Stream<DocumentSnapshot> listenToRoom(String roomId) {
    return _roomsCollection.doc(roomId).snapshots();
  }



  // Generate a random 6-character room code
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length)))
    );
  }
   
}

