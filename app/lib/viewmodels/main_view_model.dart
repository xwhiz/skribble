import 'package:app/data/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../services/firestore_service.dart';
import 'package:app/data/constants.dart';

class MainViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;

  MainViewModel(this._firestoreService);

  RoomModel? _room;
  bool _isLoading = false;
  String? _error;

  RoomModel? get room => _room;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<DocumentSnapshot>? _roomStream;
  String? get currentRoomId => _room?.roomCode;

  Future<void> createRoom({
    bool isPrivate = true,
    int maxPlayers = K.maxPlayers,
    int totalRounds = K.totalRounds,
    int roundDuration = K.roundDuration,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await _firestoreService.createRoom(isPrivate: true);
      final roomDoc =
          await FirebaseFirestore.instance.collection('Room').doc(result).get();

      _room = RoomModel.fromJson(roomDoc.data()!);
      _subscribeToRoom(result);
    } catch (e) {
      _error = 'Failed to create room: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> joinPublicRoom() async {
    _setLoading(true);
    _error = null;
    // print("Joining room...");

    try {
      final result = await _firestoreService.joinPublicRoom();
      print("result: $result");
      final roomDoc =
          await FirebaseFirestore.instance
              .collection('Room')
              .doc(result['roomId'])
              .get();
      print("roomDoc: $roomDoc");
      _room = RoomModel.fromJson(roomDoc.data()!);
      _subscribeToRoom(result['roomId']);
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
      final result = await _firestoreService.joinPrivateRoom(roomCode);
      if (result == true) {
        final roomDoc =
            await FirebaseFirestore.instance
                .collection('Room')
                .doc(roomCode)
                .get();

        _room = RoomModel.fromJson(roomDoc.data()!);
        _subscribeToRoom(roomCode);
      } else {
        _error = 'Failed to join private room:';
      }
    } catch (e) {
      _error = 'Failed to join room: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  void leaveRoom() async {
    if (_room != null) {
      await _firestoreService.leaveRoom(_room!.roomCode);
      _room = null;
      _roomStream = null;
      notifyListeners();
    }
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
    _roomStream = _firestoreService.listenToRoom(roomId);
    _roomStream!.listen((snapshot) {
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
}
