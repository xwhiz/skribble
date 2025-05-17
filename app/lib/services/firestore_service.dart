import 'dart:math';

import 'package:app/data/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Collection reference
  CollectionReference get playerbookCollection => _db.collection('playerbook');
  CollectionReference get wordBankRef => _db.collection('wordbank');
  String userName =
      FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown User';

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
      var docReference =
          FirebaseFirestore.instance.collection(K.roomCollection).doc(roomId);

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

  Future<Map<String, dynamic>> joinPublicRoom({required bool isGuest}) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore db = FirebaseFirestore.instance;

    if (auth.currentUser == null) {
      throw Exception("User not authenticated");
    }

    final User currentUser = auth.currentUser!;

    String userId = currentUser.uid;

    String userName = currentUser.displayName ?? 'Anonymous';

    try {
      // Step 1: Look for available public rooms
      QuerySnapshot availableRooms = await db
          .collection('Room')
          .where('status', isEqualTo: 'waiting')
          .where('isPrivate', isEqualTo: false)
          .where('currentPlayers', isLessThan: K.maxPlayers)
          .orderBy('currentPlayers', descending: true)
          .limit(1)
          .get();

      if (availableRooms.docs.isNotEmpty) {
        // Join an existing room

        print('Joining existing room');

        String roomId = availableRooms.docs[0].id;
        DocumentReference roomRef = db.collection(K.roomCollection).doc(roomId);

        await db.runTransaction((transaction) async {
          DocumentSnapshot roomSnapshot = await transaction.get(roomRef);

          if (!roomSnapshot.exists) {
            throw Exception('Room no longer exists.');
          }

          Map<String, dynamic> roomData =
              roomSnapshot.data() as Map<String, dynamic>;

          List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
          List<String> drawingQueue =
              List<String>.from(roomData['drawingQueue'] ?? []);

          if (players.any((player) => player['userId'] == currentUser?.uid)) {
            print("User already in room");
            return {'roomId': roomId, 'isNewRoom': false};
          }

          drawingQueue.add(currentUser!.uid);
          print("line 106 {drawingQueue: $drawingQueue}");
          // Update player count
          transaction.update(roomRef, {
            'currentPlayers': roomData['currentPlayers'] + 1,
            'drawingQueue': drawingQueue,
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
        });
        return {'roomId': roomId, 'isNewRoom': false};
      } else {
        // No room found – create a new public room
        String newRoomId = await createRoom(
          isPrivate: false,
          maxPlayers: K.maxPlayers,
          totalRounds: K.totalRounds,
          roundDuration: K.roundDuration,
        );
        return {'roomId': newRoomId, 'isNewRoom': true};
      }
    } catch (e, stackTrace) {
      print('Transaction failed: $e');
      print('StackTrace: $stackTrace');
      throw Exception('Failed to join a public room: $e');
    }
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
      'drawingQueue': [currentUser.uid],
      'roundDuration': roundDuration,
      'createdAt': DateTime.now(),
      'drawingStartAt': DateTime.now(),
      'drawing': {
        'elements': [],
        'lastUpdatedBy': '',
        'lastUpdatedAt': DateTime.now(),
      },
    });

    await startDrawing(roomCode);

    return roomCode;
  }

  // Join a specific room by ID (for mid-game joining)
  Future<bool> joinPrivateRoom(String id) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User not authenticated or guest name not provided');
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
        (player) => player['userId'] == currentUser?.uid,
      );

      if (alreadyJoined) {
        return true; // Player is already in the room
      }

      // Determine the player's name
      final String playerName = currentUser.displayName ?? "Anonymous";

      // Add player to room and update count
      await _db.collection('Room').doc(id).update({
        'currentPlayers': FieldValue.increment(1),
        'players': FieldValue.arrayUnion([
          {
            'userId': currentUser.uid, // For guest users, use 'anonymous'
            'username': playerName,
            'joinedAt': DateTime.now(),
            'score': 0,
            'isDrawing': false,
            'isReady': roomData['status'] !=
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

      // Find the player to remove from players list
      int playerIndex = players.indexWhere(
        (player) => player['userId'] == currentUser.uid,
      );
      if (playerIndex == -1) {
        return; // Player not found
      }

      //Find the player to remove from drawing Queue
      players.removeAt(playerIndex);
      List<String> drawingQueue =
          List<String>.from(roomData['drawingQueue'] ?? []);
      int playerDrawingQueueIndex =
          drawingQueue.indexWhere((userId) => userId == currentUser.uid);
      drawingQueue.removeAt(playerDrawingQueueIndex);

      // Check if this player is the current drawer
      bool isDrawer = roomData['currentDrawerId'] == currentUser.uid;
      if (isDrawer) {
        startDrawing(roomId);
      }

      // Update room
      if (players.isEmpty) {
        // If last player, delete the room
        transaction.delete(roomRef);
      } else {
        // Otherwise update the room
        Map<String, dynamic> updateData = {
          'currentPlayers': FieldValue.increment(-1),
          'players': players,
          'drawingQueue': drawingQueue,
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
  Future<void> startDrawing(String roomId) async {
    try {
      final User? currentUser = _auth.currentUser;
      DocumentReference roomRef = _db.collection('Room').doc(roomId);
      DocumentSnapshot roomSnapshot = await roomRef.get();

      if (!roomSnapshot.exists) {
        return;
      }

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic> roomData =
          roomSnapshot.data() as Map<String, dynamic>;
      List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
      List<String> drawingQueue =
          List<String>.from(roomData['drawingQueue'] ?? []);

      // print("Players: $players");
      // print("Drawing Queue: ${roomData['drawingQueue']}");

      //Get darwer ID and update queue
      String drawerId = drawingQueue[0];
      if (currentUser.uid == drawerId) {
        drawingQueue.removeAt(0);
        drawingQueue.add(drawerId);

        drawerId = drawingQueue[0];

        print("Drawing queue: $drawingQueue");

        // // Check if there are at least 2 players
        // if (players.length < 2) {
        //   return false;
        // }

        // Choose a random word
        // String word = _getRandomWord();
        // String hint = _generateHint(word);
        // String hiddenWord = _generateHiddenWord(word);

        // Update room status
        await roomRef.update({
          // 'status': 'playing',
          'currentRound': 1,
          'currentDrawerId': drawerId,
          'currentWord': "Hello",
          'hiddenWord': "Hello",
          'drawingStartAt': DateTime.now(),
          'drawing': {
            'elements': [],
            'lastUpdatedBy': drawerId,
            'lastUpdatedAt': DateTime.now(),
          },
          'drawingQueue': drawingQueue,
        });

        // // Update the drawer status in players array
        // List<dynamic> updatedPlayers = players.map((player) {
        //   return {...player, 'isDrawing': player['userId'] == drawerId};
        // }).toList();

        // await roomRef.update({'players': updatedPlayers});
      } else {
        print("Not drawer");
      }
    } catch (e) {
      print('Error starting game: $e');
    }
  }

  // Stream to listen for room updates
  Stream<DocumentSnapshot> listenToRoom(String roomId) {
    return _db.collection(K.roomCollection).doc(roomId).snapshots();
  }

  // Sync drawing with Firebase
  Future<void> syncDrawing(
      String roomId, List<Map<String, dynamic>> elements, String userId) async {
    try {
      await _db.collection('Room').doc(roomId).update({
        'drawing': {
          'elements': elements,
          'lastUpdatedBy': userId,
          'lastUpdatedAt': DateTime.now(),
        }
      });
    } catch (e) {
      print('Error syncing drawing: $e');
      throw e;
    }
  }

  // Claim drawing turn - make this user the current drawer
  Future<void> claimDrawingTurn(String roomId, String userId) async {
    try {
      DocumentReference roomRef = _db.collection('Room').doc(roomId);
      DocumentSnapshot roomSnapshot = await roomRef.get();

      if (!roomSnapshot.exists) {
        throw Exception('Room not found');
      }

      await roomRef.update({
        'currentDrawerId': userId,
        'drawing': {
          'elements': [],
          'lastUpdatedBy': userId,
          'lastUpdatedAt': DateTime.now(),
        }
      });
    } catch (e) {
      print('Error claiming drawing turn: $e');
      throw e;
    }
  }

  // Release drawing turn
  Future<void> releaseDrawingTurn(String roomId, String userId) async {
    try {
      DocumentReference roomRef = _db.collection('Room').doc(roomId);
      DocumentSnapshot roomSnapshot = await roomRef.get();

      if (!roomSnapshot.exists) {
        throw Exception('Room not found');
      }

      Map<String, dynamic>? data = roomSnapshot.data() as Map<String, dynamic>?;
      if (data != null && data['currentDrawerId'] == userId) {
        await roomRef.update({'currentDrawerId': ''});
      }
    } catch (e) {
      print('Error releasing drawing turn: $e');
      throw e;
    }
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
