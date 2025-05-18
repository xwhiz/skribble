import 'dart:convert';
import 'dart:math';

import 'package:app/data/constants.dart';
import 'package:app/models/room_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  Future<Map<String, dynamic>> joinPublicRoom() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore db = FirebaseFirestore.instance;

    if (auth.currentUser == null) {
      throw Exception("User not authenticated");
    }

    final User currentUser = auth.currentUser!;

    try {
      // Step 1: Look for available public rooms
      QuerySnapshot availableRooms = await db
          .collection(K.roomCollection)
          .where('isPrivate', isEqualTo: false)
          .where('currentPlayers', isLessThan: K.maxPlayers)
          .orderBy('currentPlayers', descending: true)
          .limit(1)
          .get();

      print(availableRooms.docs);

      if (availableRooms.docs.isNotEmpty) {
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

          if (players.any((player) => player['userId'] == currentUser.uid)) {
            print("User already in room");
            return {'roomId': roomId, 'isNewRoom': false};
          }

          drawingQueue.add(currentUser.uid);
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
      'drawingQueue': [],
      'guessedCorrectly': [],
      'roundDuration': roundDuration,
      'createdAt': DateTime.now(),
      'drawingStartAt': null,
      'drawing': {
        'elements': [],
        'lastUpdatedBy': '',
        'lastUpdatedAt': DateTime.now(),
      },
    });

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

    try {
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
            // isdrawer, then trigger next turn otherwise remove player from guessed correctly
            'guessedCorrectly': isDrawer
                ? players.map((e) => e['userId'] as String).toList()
                : players
                    .where((player) => player['userId'] != currentUser.uid)
                    .map((e) => e['userId'] as String)
                    .toList(),
          };

          transaction.update(roomRef, updateData);
        }
      });
    } catch (e) {
      print('Error leaving room: $e');
      rethrow;
    }
  }

  Future<String> getNextDrawerId(String roomId) async {
    DocumentReference roomRef = _db.collection('Room').doc(roomId);
    DocumentSnapshot roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      return '';
    }

    Map<String, dynamic> roomData = roomSnapshot.data() as Map<String, dynamic>;
    List<String> drawingQueue =
        List<String>.from(roomData['drawingQueue'] ?? []);

    if (drawingQueue.isEmpty) {
      return '';
    }
    return drawingQueue.last;
  }

  Future<String> getRandomWord() async {
    final jsonString = await rootBundle.loadString("assets/wordbank.json");
    var json = jsonDecode(jsonString);
    List<Map<String, dynamic>> wordObjects =
        List<Map<String, dynamic>>.from(json);

    List<String> words = wordObjects.map((e) => e['word'] as String).toList();
    words.shuffle();
    return words.take(1).toList()[0];
  }

  Future<void> startNextTurn(String roomId) async {
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

      RoomModel room =
          RoomModel.fromJson(roomSnapshot.data() as Map<String, dynamic>);
      var players = room.players!;
      var drawingQueue = room.drawingQueue!;
      int currentRound = room.currentRound!;
      String currentDrawerId = room.currentDrawerId!;

      if (currentDrawerId != '' && currentDrawerId != currentUser.uid) {
        print("Current drawer is not the current user");
        return;
      }

      await roomRef.update({'isChangingTurn': true});

      if (drawingQueue.isEmpty) {
        // This means the round has been finished.
        currentRound += 1;
        drawingQueue = players.map((e) => e.userId).toList();
      }

      if (drawingQueue.isNotEmpty) {
        currentDrawerId = drawingQueue.removeLast();
      }

      String? word = await getRandomWord();
      String hiddenWord = word.split('').map((e) => '_').join(' ');

      // Run this code in a transaction
      await _db.runTransaction((transaction) async {
        transaction.update(roomRef, {
          'currentRound': currentRound,
          'currentDrawerId': currentDrawerId,
          'currentWord': word,
          'hiddenWord': hiddenWord,
          'drawingStartAt': DateTime.now(),
          'drawing': {
            'elements': [],
            'lastUpdatedBy': currentDrawerId,
            'lastUpdatedAt': DateTime.now(),
          },
          'drawingQueue': drawingQueue,
          'guessedCorrectly': [],
          'isChangingTurn': false,
        });
      });
    } catch (e) {
      print('Error starting game: $e');
    }
  }

  Future<void> addCorrectGuessAndScore(
    String roomId,
    String userId,
    int addedScore,
  ) async {
    try {
      final players = await _db
          .collection('Room')
          .doc(roomId)
          .get()
          .then((value) => value.data()?['players'] as List<dynamic>? ?? []);

      List<dynamic> updatedPlayers = players.map((player) {
        if (player['userId'] == userId) {
          return {
            ...player,
            'score': player['score'] + addedScore,
          };
        } else {
          return player;
        }
      }).toList();

      await _db.collection('Room').doc(roomId).update({
        'guessedCorrectly': FieldValue.arrayUnion([userId]),
        'players': updatedPlayers,
      });
    } catch (e) {
      print('Error adding correct guess: $e');
    }
  }

  Future<void> removeRoom(String roomId) async {
    try {
      await _db.collection('Room').doc(roomId).delete();
    } catch (e) {
      print('Error removing room: $e');
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
      rethrow;
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
      rethrow;
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
      rethrow;
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
}
