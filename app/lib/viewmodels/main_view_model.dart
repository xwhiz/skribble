import 'package:app/data/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
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

  RoomModel? get room => _room;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<DocumentSnapshot>? _roomStream;
  String? get currentRoomId => _room?.roomCode;

  DrawingViewModel? _drawingViewModel;

  DrawingViewModel getDrawingViewModel() {
    if (_drawingViewModel == null && currentRoomId != null) {
      _drawingViewModel = DrawingViewModel(
        roomId: currentRoomId!,
      );
    }
    return _drawingViewModel!;
  }

  // Add/update this method to properly clean up before joining a new room
  Future<void> _cleanupPreviousRoom() async {
    // Cancel any existing room subscription
    if (_roomSubscription != null) {
      // Fixed: Use _roomSubscription, not _roomStream
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

  // Update the createRoom method
  Future<void> createRoom({
    bool isPrivate = true,
    int maxPlayers = K.maxPlayers,
    int totalRounds = K.totalRounds,
    int roundDuration = K.roundDuration,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // Clean up previous room first
      await _cleanupPreviousRoom();

      // Create the new room
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
        // Don't manually set currentRoomId as it's a getter
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

  // Similarly update the joinPublicRoom and joinPrivateRoom methods
  Future<void> joinPublicRoom() async {
    _setLoading(true);
    _error = null;

    try {
      // Clean up previous room first
      await _cleanupPreviousRoom();

      final result = await _firestoreService.joinPublicRoom();
      print("result: $result");

      if (result != null && result['roomId'] != null) {
        final roomDoc = await FirebaseFirestore.instance
            .collection('Room')
            .doc(result['roomId'])
            .get();

        if (roomDoc.exists && roomDoc.data() != null) {
          _room = RoomModel.fromJson(roomDoc.data()!);
          _subscribeToRoom(result['roomId']);
          // Don't manually set currentRoomId as it's a getter
        } else {
          _error = 'Room document not found or empty';
        }
      } else {
        _error = 'Failed to join room: Invalid result';
      }
    } catch (e) {
      _error = 'Failed to join room: $e';
      print(e.toString());
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
