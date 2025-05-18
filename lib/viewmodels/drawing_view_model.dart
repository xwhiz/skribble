import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/models/drawing_element_model.dart';
import 'package:app/models/enums/draw_mode.dart';

class DrawingViewModel extends ChangeNotifier {
  final String roomId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DrawingElement> _elements = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 5.0;
  DrawMode _selectedMode = DrawMode.pencil;
  String? _currentDrawerId;
  bool _isMyTurn = false;
  StreamSubscription? _roomSubscription;
  int _lastUpdateTimestamp = 0;

  // Getters
  List<DrawingElement> get elements => _elements;
  Color get selectedColor => _selectedColor;
  double get strokeWidth => _strokeWidth;
  DrawMode get selectedMode => _selectedMode;
  String? get currentDrawerId => _currentDrawerId;
  bool get isMyTurn => _isMyTurn;
  String? get currentUserId => _auth.currentUser?.uid;

  DrawingViewModel({required this.roomId}) {
    _initializeRoom();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  void _initializeRoom() {
    // Listen for room changes
    _roomSubscription = _firestore
        .collection('Room')
        .doc(roomId)
        .snapshots()
        .listen(_handleRoomUpdate);
  }

  void _handleRoomUpdate(DocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      print('Room document does not exist');
      return;
    }

    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      print('Room data is null');
      return;
    }

    // Update current drawer info
    final newDrawerId = data['currentDrawerId'] as String?;
    final bool wasMyTurn = _isMyTurn;

    _currentDrawerId = newDrawerId;
    _isMyTurn = currentUserId != null && currentUserId == newDrawerId;

    // Handle drawing data updates - only if we're not the current drawer
    // or if this is the first time we're observing
    if (!_isMyTurn && data['drawing'] != null) {
      final drawingData = data['drawing'] as Map<String, dynamic>;
      print('Drawing data: $drawingData');
      final timestamp = (drawingData['timestamp'] ?? 0) as int;

      // Only process updates newer than our last update and not from ourselves
      if (timestamp > _lastUpdateTimestamp) {
        _lastUpdateTimestamp = timestamp;
        _importDrawing(drawingData);
      }
    }

    // If turn state changed, notify listeners
    if (wasMyTurn != _isMyTurn) {
      notifyListeners();
    }
  }

  void _importDrawing(Map<String, dynamic> drawingData) {
    try {
      final elementsList = drawingData['elements'] as List<dynamic>;
      final newElements = elementsList
          .map((elem) => DrawingElement.fromJson(elem as Map<String, dynamic>))
          .toList();

      _elements = newElements;
      notifyListeners();
    } catch (e) {
      print('Error importing drawing: $e');
    }
  }

  Map<String, dynamic> _exportDrawing() {
    return {
      'elements': _elements.map((e) => e.toJson()).toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Sync the current drawing state to Firebase
  Future<void> syncDrawingToFirebase() async {
    if (!_isMyTurn || currentUserId == null) {
      print('Cannot sync: not my turn to draw');
      return;
    }

    try {
      final drawingData = _exportDrawing();
      _lastUpdateTimestamp = drawingData['timestamp'] as int;

      await _firestore.collection('Room').doc(roomId).update({
        'drawing': drawingData,
        'lastUpdatedBy': currentUserId,
      });

      print('Drawing synced to Firebase');
    } catch (e) {
      print('Error syncing drawing: $e');
    }
  }

  // Claim the drawing turn
  Future<void> claimDrawingTurn() async {
    if (currentUserId == null) {
      print('Cannot claim turn: user not logged in');
      return;
    }

    try {
      final docRef = _firestore.collection('Room').doc(roomId);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        print('Room document does not exist');
        return;
      }

      final data = snapshot.data();
      final currentDrawerId = data?['currentDrawerId'] as String?;

      // Check if drawer is null, empty string, or if we're already the drawer
      if (currentDrawerId == null ||
          currentDrawerId.isEmpty ||
          currentDrawerId == currentUserId) {
        // Clear canvas when claiming turn
        _elements.clear();

        await docRef.update({
          'currentDrawerId': currentUserId,
          'turnStartedAt': DateTime.now().millisecondsSinceEpoch,
          'drawing': {
            'elements': [],
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }
        });

        _isMyTurn = true;
        _currentDrawerId = currentUserId;
        notifyListeners();

        print('Successfully claimed drawing turn');
      } else {
        // Someone else is drawing - print their ID for debugging
        print(
            'Cannot claim turn: someone else is already drawing: $currentDrawerId');
      }
    } catch (e) {
      print('Error claiming drawing turn: $e');
    }
  }

  // Release the drawing turn
  Future<void> releaseDrawingTurn() async {
    if (!_isMyTurn ||
        currentUserId == null ||
        _currentDrawerId != currentUserId) {
      print('Cannot release turn: not the current drawer');
      return;
    }

    try {
      await _firestore.collection('Room').doc(roomId).update({
        'currentDrawerId': '', // Use empty string instead of null
      });

      _isMyTurn = false;
      notifyListeners();

      print('Drawing turn released');
    } catch (e) {
      print('Error releasing drawing turn: $e');
    }
  }

  // Drawing actions
  void setColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void selectMode(DrawMode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  void addDrawingElement(DrawingElement element) {
    _elements.add(element);
    notifyListeners();
  }

  void clearCanvas() {
    _elements.clear();
    notifyListeners();
  }

  void undo() {
    if (_elements.isNotEmpty) {
      _elements.removeLast();
      notifyListeners();
    }
  }
}
