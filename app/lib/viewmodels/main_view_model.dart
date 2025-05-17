import 'dart:async';
import 'dart:convert';

import 'package:app/data/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/room_model.dart';
import '../services/firestore_service.dart';
import 'drawing_view_model.dart';

class MainViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;

  MainViewModel(this._firestoreService);

  RoomModel? _room;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<DocumentSnapshot>? _roomSubscription; // Add this line
  final FirebaseAuth _auth = FirebaseAuth.instance; // Define _auth

  RoomModel? get room => _room;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Stream<DocumentSnapshot>? _roomStream;
  String? get currentRoomId => _room?.roomCode;

  bool get isGameCompleted => _room!.currentRound! - 1 == _room?.totalRounds;
  bool get isCurrentDrawingCompleted =>
      _room!.guessedCorrectly!.length >= _room!.players!.length - 1;

  DrawingViewModel? _drawingViewModel;

  Map<String, int> currentRoundScores = {};

  Future<void> joinPublicRoom() async {
    _setLoading(true);
    _error = null;

    try {
      await _cleanupPreviousRoom();

      // Ensure guest users are signed in anonymously
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        throw Exception('User not authenticated');
      }

      final result = await _firestoreService.joinPublicRoom();

      print("Result from FirestoreService: $result");

      if (result['roomId'] != null) {
        final roomDoc = await FirebaseFirestore.instance
            .collection('Room')
            .doc(result['roomId'])
            .get();
        if (roomDoc.exists && roomDoc.data() != null) {
          _room = RoomModel.fromJson(roomDoc.data()!);
          _subscribeToRoom(result['roomId']);
        } else {
          _error = 'Room document not found or is empty.';
          print("Room document not found or is empty.");
        }
      } else {
        _error = 'Failed to join room: Invalid result';
        print("Invalid result received from FirestoreService: $result");
      }
    } catch (e, stackTrace) {
      if (e is FirebaseAuthException) {
        _error = 'Authentication error: ${e.message}';
      } else if (e is FirebaseException) {
        _error = 'Firestore error: ${e.message}';
      } else if (e is TimeoutException) {
        _error = 'Request timed out. Please try again.';
      } else {
        _error = 'Unexpected error: $e';
      }

      print("Error: $_error");
      print("StackTrace: $stackTrace");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> joinPrivateRoom(String roomCode) async {
    _setLoading(true);
    _error = null;

    try {
      // Clean up previous room first
      await _cleanupPreviousRoom();

      // If no guestName is provided, handle it based on authentication state
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _error = 'User not authenticated and guest name not provided';
        return;
      }

      // Pass the guest name or handle the user authentication
      final result = await _firestoreService.joinPrivateRoom(roomCode);

      if (result == true) {
        final roomDoc = await FirebaseFirestore.instance
            .collection('Room')
            .doc(roomCode)
            .get();

        if (roomDoc.exists && roomDoc.data() != null) {
          _room = RoomModel.fromJson(roomDoc.data()!);
          _subscribeToRoom(roomCode);
        } else {
          _error = 'Room document not found or empty';
        }
      } else {
        _error = 'Failed to join private room';
      }
    } catch (e) {
      _error = 'Failed to join room: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Update leaveRoom method
  Future<void> leaveRoom() async {
    await _cleanupPreviousRoom();
    notifyListeners();
  }

  Future<void> sendMessage(
    String username,
    String message,
    String roomCode,
    String userId,
  ) async {
    await _firestoreService.sendMessage(username, message, roomCode, userId);
  }

  Future<String> getNextDrawerId() async {
    if (_room == null) {
      print('No active room');
      return '';
    }

    final roomCode = _room!.roomCode;
    final nextDrawerId = await _firestoreService.getNextDrawerId(roomCode);
    print("Next drawer ID: $nextDrawerId");
    return nextDrawerId;
  }

  Future<void> startNextTurn() async {
    await _firestoreService.startNextTurn(_room!.roomCode);
    notifyListeners();
  }

  void _subscribeToRoom(String roomId) {
    // Cancel any existing subscription first
    _roomSubscription?.cancel();

    _roomStream = _firestoreService.listenToRoom(roomId);
    _roomSubscription = _roomStream!.listen((snapshot) {
      // Fixed: Save the subscription
      if (snapshot.exists) {
        _room = RoomModel.fromJson(snapshot.data() as Map<String, dynamic>);
        notifyListeners();
      }
    });
  }

  DrawingViewModel getDrawingViewModel() {
    if (_drawingViewModel == null && currentRoomId != null) {
      _drawingViewModel = DrawingViewModel(
        roomId: currentRoomId!,
      );
    }
    return _drawingViewModel!;
  }

  Future<void> _cleanupPreviousRoom() async {
    if (_roomSubscription != null) {
      _roomSubscription?.cancel();
      _roomSubscription = null;
    }

    // Dispose the drawing view model if it exists
    if (_drawingViewModel != null) {
      // No need to manually call dispose, just clear the reference
      _drawingViewModel = null;
    }

    // If we have a current room, leave it properly
    if (_room != null) {
      try {
        await _firestoreService.leaveRoom(_room!.roomCode);
      } catch (e) {
        print('Error leaving room: $e');
      }
      _room = null;
    }
  }

  Future<void> createRoom({
    bool isPrivate = true,
    int maxPlayers = K.maxPlayers,
    int totalRounds = K.totalRounds,
    int roundDuration = K.roundDuration,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _cleanupPreviousRoom();

      final result = await _firestoreService.createRoom(
          isPrivate: isPrivate,
          maxPlayers: maxPlayers,
          totalRounds: totalRounds,
          roundDuration: roundDuration);

      final roomDoc =
          await FirebaseFirestore.instance.collection('Room').doc(result).get();

      if (roomDoc.exists && roomDoc.data() != null) {
        _room = RoomModel.fromJson(roomDoc.data()!);
        _subscribeToRoom(result);
      } else {
        _error = 'Room document not found or empty';
      }
    } catch (e) {
      _error = 'Failed to create room: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addCorrectGuessAndScore(String userId, int addedScore) async {
    if (_room == null) {
      print('No active room');
      return;
    }

    final roomCode = _room!.roomCode;
    await _firestoreService.addCorrectGuessAndScore(
      roomCode,
      userId,
      addedScore,
    );
  }

  Future<void> removeRoom() async {
    if (_room == null) {
      print('No active room');
      return;
    }

    final roomCode = _room!.roomCode;
    await _firestoreService.removeRoom(roomCode);
    _room = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _roomSubscription = null;
    _drawingViewModel = null;
    super.dispose();
  }
}
