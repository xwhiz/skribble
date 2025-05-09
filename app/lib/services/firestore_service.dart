import 'package:app/data/constants.dart';
import 'package:app/models/chat_message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/data/constants.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Collection reference
  CollectionReference get playerbookCollection => _db.collection('playerbook');
  String userName =
      FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown User';

  // Future<void> sendMessage(String sender, String message, String roomId) async {
  //   try {
  //     if (message.isNotEmpty) {
  //       await FirebaseFirestore.instance
  //           .collection('rooms')
  //           .doc(roomId)
  //           .collection('messages')
  //           .add({
  //             'text': message,
  //             'sender': sender,
  //             'timestamp': FieldValue.serverTimestamp(),
  //           });
  //     }
  //   } catch (e) {
  //     print('Error sending message: $e');
  //   }
  // }
  Future<void> sendMessage(
    String sender,
    String message,
    String roomId,
    String playerId,
  ) async {
    try {
      if (message.isEmpty) {
        return;
      }
      var docReference = FirebaseFirestore.instance
          .collection(K.roomCollection)
          .doc(roomId);

      await docReference.update({
        'messages': FieldValue.arrayUnion([
          {
            'name': sender,
            'message': message,
            'userId': playerId,
            'timestamp': DateTime.now(),
          },
        ]),
      });

      print('Message sent successfully!');
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Join a room or create a new one if no rooms are available
  Future<Map<String, dynamic>> joinPublicRoom() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    // Transaction to ensure atomicity
    return _db.runTransaction<Map<String, dynamic>>((transaction) async {
      // Check for available rooms (status: 'waiting', not full)
      // try {
      var availableRooms =
          await _db
              .collection('Room')
              .where('status', isEqualTo: 'waiting')
              .where('isPrivate', isEqualTo: false)
              .where('currentPlayers', isLessThan: K.maxPlayers)
              .orderBy('currentPlayers', descending: true)
              .limit(1)
              .get();
      print('Available rooms: ${availableRooms.docs.length}');
      // print(availableRooms);
      // } catch (e, stack) {
      //   print('Failed to join room: $e');
      //   print('Stack trace: $stack');
      // }
      // print(availableRooms);
      String roomId;
      bool isNewRoom = false;

      if (availableRooms.docs.isNotEmpty) {
        // Join an existing room
        print('Joining existing room');
        roomId = availableRooms.docs[0].id;
        DocumentReference roomRef = _db.collection('Room').doc(roomId);

        // Get the current data
        DocumentSnapshot roomSnapshot = await transaction.get(roomRef);
        Map<String, dynamic> roomData =
            roomSnapshot.data() as Map<String, dynamic>;

        // Update player count
        transaction.update(roomRef, {
          'currentPlayers': roomData['currentPlayers'] + 1,
          'players': FieldValue.arrayUnion([
            {
              'userId': currentUser.uid,
              'username': currentUser.displayName ?? 'Anonymous',
              'joinedAt': DateTime.now(),
              'score': 0,
              'isDrawing': false,
            },
          ]),
        });
      } else {
        // Create a new room with a 6-character code
        String roomCode = _generateRoomCode();
        DocumentReference newRoomRef = _db.collection('Room').doc(roomCode);
        roomId = roomCode;
        isNewRoom = true;

        // Initialize the room
        transaction.set(newRoomRef, {
          'roomCode': roomCode,
          'status': 'waiting',
          'maxPlayers': 8,
          'currentPlayers': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'currentRound': 0,
          'totalRounds': 3,
          'currentDrawerId': '',
          'currentWord': '',
          'hint': '',
          'hiddenWord': '- - - - - -', // Default placeholder
          'timeLeft': '60:00',
          'players': [
            {
              'userId': currentUser.uid,
              'username': currentUser.displayName ?? 'Anonymous',
              'joinedAt': Timestamp.now(),
              'score': 0,
              'isDrawing': false,
            },
          ],
        });
        print("No available rooms, created a new one");
      }

      return {'roomId': roomId, 'isNewRoom': isNewRoom};
    });
  }

  // Create a new room
  Future<String> createRoom({
    bool isPrivate = false,
    int maxPlayers = K.maxPlayers,
    int totalRounds = K.totalRounds,
    int roundDuration = K.roundDuration,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    String roomCode = _generateRoomCode();
    await _db.collection('Room').doc(roomCode).set({
      'roomCode': roomCode,
      'status': 'waiting',
      'maxPlayers': maxPlayers,
      'currentPlayers': 1,
      'currentRound': 0,
      'totalRounds': totalRounds,
      'currentDrawerId': '',
      'currentWord': '',
      'hint': '',
      'hiddenWord': '- - - - - -', // Default placeholder
      'timeLeft': '$roundDuration : 00',
      'isPrivate': isPrivate,
      'messages': [],
      'players': [
        {
          'userId': currentUser.uid,
          'username': currentUser.displayName ?? 'Anonymous',
          'joinedAt': DateTime.now(),
          'score': 0,
          'isDrawing': false,
        },
      ],
      'roundDuration': roundDuration,
      'createdAt': DateTime.now(),
    });

    return roomCode;
  }

  // Join a specific room by ID (for mid-game joining)
  Future<bool> joinPrivateRoom(String id) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get room data
      DocumentSnapshot roomSnapshot =
          await _db.collection('Room').doc(id).get();

      if (!roomSnapshot.exists) {
        return false; // Room doesn't exist
      }

      Map<String, dynamic> roomData =
          roomSnapshot.data() as Map<String, dynamic>;

      // Check if room is full
      if (roomData['currentPlayers'] >= roomData['maxPlayers']) {
        return false; // Room is full
      }

      // Check if user is already in the room
      List<dynamic> players = roomData['players'] ?? [];
      bool alreadyJoined = players.any(
        (player) => player['userId'] == currentUser.uid,
      );

      if (alreadyJoined) {
        return true; // Player is already in the room
      }

      // Add player to room and update count
      await _db.collection('Room').doc(id).update({
        'currentPlayers': FieldValue.increment(1),
        'players': FieldValue.arrayUnion([
          {
            'userId': currentUser.uid,
            'username': currentUser.displayName ?? 'Anonymous',
            'joinedAt': DateTime.now(),
            'score': 0,
            'isDrawing': false,
            'isReady':
                roomData['status'] !=
                'waiting', // Auto-ready if game is in progress
          },
        ]),
      });

      return true;
    } catch (e) {
      print('Error joining room: $e');
      return false;
    }
  }

  // Leave room
  Future<void> leaveRoom(String roomId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Transaction to ensure consistency
    return _db.runTransaction((transaction) async {
      DocumentReference roomRef = _db.collection('Room').doc(roomId);

      // Get room data
      DocumentSnapshot roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) {
        return; // Room doesn't exist
      }

      Map<String, dynamic> roomData =
          roomSnapshot.data() as Map<String, dynamic>;
      List<dynamic> players = roomData['players'] ?? [];

      // Find the player to remove
      int playerIndex = players.indexWhere(
        (player) => player['userId'] == currentUser.uid,
      );
      if (playerIndex == -1) {
        return; // Player not found
      }

      // Check if this player is the current drawer
      bool isDrawer = roomData['currentDrawerId'] == currentUser.uid;

      // Remove player from list
      players.removeAt(playerIndex);

      // Update room
      if (players.isEmpty) {
        // If last player, delete the room
        transaction.delete(roomRef);
      } else {
        // Otherwise update the room
        Map<String, dynamic> updateData = {
          'currentPlayers': FieldValue.increment(-1),
          'players': players,
        };

        // If this was the drawer, choose next player
        if (isDrawer && roomData['status'] == 'playing') {
          // Choose next player as drawer (simple round-robin)
          if (players.isNotEmpty) {
            int nextDrawerIndex = 0; // Default to first player
            updateData['currentDrawerId'] = players[nextDrawerIndex]['userId'];
          }
        }

        transaction.update(roomRef, updateData);
      }
    });
  }

  // Start the game
  Future<bool> startGame(String roomId) async {
    try {
      DocumentReference roomRef = _db.collection('Room').doc(roomId);
      DocumentSnapshot roomSnapshot = await roomRef.get();

      if (!roomSnapshot.exists) {
        return false;
      }

      Map<String, dynamic> roomData =
          roomSnapshot.data() as Map<String, dynamic>;
      List<dynamic> players = roomData['players'] ?? [];

      // Check if there are at least 2 players
      if (players.length < 2) {
        return false;
      }

      // Choose a random player as the first drawer
      Random random = Random();
      int drawerIndex = random.nextInt(players.length);
      String drawerId = players[drawerIndex]['userId'];

      // Choose a random word
      String word = _getRandomWord();
      String hint = _generateHint(word);
      String hiddenWord = _generateHiddenWord(word);

      // Update room status
      await roomRef.update({
        'status': 'playing',
        'currentRound': 1,
        'currentDrawerId': drawerId,
        'currentWord': word,
        'hint': hint,
        'hiddenWord': hiddenWord,
        'gameStartTime': DateTime.now(),
        'timeLeft': '60:00',
      });

      // Update the drawer status in players array
      List<dynamic> updatedPlayers =
          players.map((player) {
            return {...player, 'isDrawing': player['userId'] == drawerId};
          }).toList();

      await roomRef.update({'players': updatedPlayers});

      return true;
    } catch (e) {
      print('Error starting game: $e');
      return false;
    }
  }

  // Stream to listen for room updates
  Stream<DocumentSnapshot> listenToRoom(String roomId) {
    return _db.collection(K.roomCollection).doc(roomId).snapshots();
  }

  // Generate a random room code
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  // Get a random word for the game
  String _getRandomWord() {
    final List<String> words = [
      'apple',
      'banana',
      'cat',
      'dog',
      'elephant',
      'fish',
      'giraffe',
      'house',
      'igloo',
      'jacket',
      'key',
      'lemon',
      'monkey',
      'notebook',
      'ocean',
      'pencil',
      'queen',
      'rabbit',
      'sun',
      'tree',
      'umbrella',
      'volcano',
      'watermelon',
      'yacht',
      'zebra',
      'airplane',
      'beach',
      'castle',
      'dragon',
    ];
    return words[Random().nextInt(words.length)];
  }

  // Generate a hint for the word
  String _generateHint(String word) {
    if (word.length <= 3) {
      return "It's a short word";
    } else {
      return "First letter: ${word[0].toUpperCase()}";
    }
  }

  // Generate a hidden version of the word (with dashes)
  String _generateHiddenWord(String word) {
    return word.split('').map((_) => '_ ').join('').trim();
  }
}
