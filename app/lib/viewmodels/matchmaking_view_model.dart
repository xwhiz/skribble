import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../services/firestore_service.dart';

class MatchmakingViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;

  MatchmakingViewModel(this._firestoreService);

  RoomModel? _room;
  bool _isLoading = false;
  String? _error;

  RoomModel? get room => _room;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<DocumentSnapshot>? _roomStream;
  String? get currentRoomId => _room?.roomCode;

  Future<void> joinRoom() async {
    _setLoading(true);
    _error = null;
    print("Joining room...");

    try {
      final result = await _firestoreService.joinRoom();
      final roomDoc =
          await FirebaseFirestore.instance
              .collection('Room')
              .doc(result['roomId'])
              .get();

      _room = RoomModel.fromJson(roomDoc.data()!);
      _subscribeToRoom(result['roomId']);
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
