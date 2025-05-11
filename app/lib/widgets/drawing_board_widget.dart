import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//=== DrawMode enum ==========================================================
enum DrawMode { pencil, line, rectangle, circle, fill, eraser }

//=== Strategy API & Context =================================================
abstract class Tool {
  void onPanStart(Offset pos);
  void onPanUpdate(Offset pos);
  void onPanEnd();
  void drawPreview(Canvas canvas);
}

class DrawingContext {
  final List<DrawingElement> elements;
  final Color color;
  final double strokeWidth;
  final void Function(DrawingElement) addElement;
  final void Function(Offset) fillAt;

  DrawingContext({
    required this.elements,
    required this.color,
    required this.strokeWidth,
    required this.addElement,
    required this.fillAt,
  });
}

//=== Concrete Tools =========================================================
class PencilTool implements Tool {
  final DrawingContext ctx;
  List<Offset> _pts = [];
  PencilTool(this.ctx);

  @override
  void onPanStart(Offset pos) => _pts = [pos];

  @override
  void onPanUpdate(Offset pos) => _pts.add(pos);

  @override
  void onPanEnd() {
    if (_pts.length > 1) {
      ctx.addElement(FreehandDrawing(
        points: List.from(_pts),
        color: ctx.color,
        strokeWidth: ctx.strokeWidth,
      ));
    }
    _pts.clear();
  }

  @override
  void drawPreview(Canvas c) {
    if (_pts.length < 2) return;
    final paint = Paint()
      ..color = ctx.color
      ..strokeWidth = ctx.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(_pts.first.dx, _pts.first.dy);
    for (var p in _pts.skip(1)) path.lineTo(p.dx, p.dy);
    c.drawPath(path, paint);
  }
}

class LineTool implements Tool {
  final DrawingContext ctx;
  Offset? _start, _end;
  LineTool(this.ctx);

  @override
  void onPanStart(Offset pos) => _start = pos;

  @override
  void onPanUpdate(Offset pos) => _end = pos;

  @override
  void onPanEnd() {
    if (_start != null && _end != null) {
      ctx.addElement(LineDrawing(
        start: _start!,
        end: _end!,
        color: ctx.color,
        strokeWidth: ctx.strokeWidth,
      ));
    }
    _start = _end = null;
  }

  @override
  void drawPreview(Canvas c) {
    if (_start != null && _end != null) {
      final paint = Paint()
        ..color = ctx.color
        ..strokeWidth = ctx.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      c.drawLine(_start!, _end!, paint);
    }
  }
}

class RectangleTool implements Tool {
  final DrawingContext ctx;
  Offset? _start, _end;
  RectangleTool(this.ctx);

  @override
  void onPanStart(Offset pos) => _start = pos;

  @override
  void onPanUpdate(Offset pos) => _end = pos;

  @override
  void onPanEnd() {
    if (_start != null && _end != null) {
      ctx.addElement(RectangleDrawing(
        start: _start!,
        end: _end!,
        color: ctx.color,
        strokeWidth: ctx.strokeWidth,
        isFilled: false,
      ));
    }
    _start = _end = null;
  }

  @override
  void drawPreview(Canvas c) {
    if (_start != null && _end != null) {
      final paint = Paint()
        ..color = ctx.color
        ..strokeWidth = ctx.strokeWidth
        ..style = PaintingStyle.stroke;
      c.drawRect(Rect.fromPoints(_start!, _end!), paint);
    }
  }
}

class CircleTool implements Tool {
  final DrawingContext ctx;
  Offset? _start, _end;
  CircleTool(this.ctx);

  @override
  void onPanStart(Offset pos) => _start = pos;

  @override
  void onPanUpdate(Offset pos) => _end = pos;

  @override
  void onPanEnd() {
    if (_start != null && _end != null) {
      ctx.addElement(CircleDrawing(
        start: _start!,
        end: _end!,
        color: ctx.color,
        strokeWidth: ctx.strokeWidth,
        isFilled: false,
      ));
    }
    _start = _end = null;
  }

  @override
  void drawPreview(Canvas c) {
    if (_start != null && _end != null) {
      final center = Offset(
        (_start!.dx + _end!.dx) / 2,
        (_start!.dy + _end!.dy) / 2,
      );
      final radius = (_start! - _end!).distance / 2;
      final paint = Paint()
        ..color = ctx.color
        ..strokeWidth = ctx.strokeWidth
        ..style = PaintingStyle.stroke;
      c.drawCircle(center, radius, paint);
    }
  }
}

class EraserTool implements Tool {
  final DrawingContext ctx;
  List<Offset> _pts = [];
  EraserTool(this.ctx);

  @override
  void onPanStart(Offset pos) => _pts = [pos];

  @override
  void onPanUpdate(Offset pos) => _pts.add(pos);

  @override
  void onPanEnd() {
    if (_pts.length > 1) {
      ctx.addElement(FreehandDrawing(
        points: List.from(_pts),
        color: Colors.white,
        strokeWidth: ctx.strokeWidth * 2,
      ));
    }
    _pts.clear();
  }

  @override
  void drawPreview(Canvas c) {
    if (_pts.length < 2) return;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = ctx.strokeWidth * 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(_pts.first.dx, _pts.first.dy);
    for (var p in _pts.skip(1)) path.lineTo(p.dx, p.dy);
    c.drawPath(path, paint);
  }
}

class FillTool implements Tool {
  final DrawingContext ctx;
  FillTool(this.ctx);

  @override
  void onPanStart(Offset pos) => ctx.fillAt(pos);

  @override
  void onPanUpdate(Offset pos) {}

  @override
  void onPanEnd() {}

  @override
  void drawPreview(Canvas canvas) {}
}

//=== Main Drawing Board Widget ==================================================
class DrawingBoardWidget extends StatefulWidget {
  const DrawingBoardWidget({Key? key}) : super(key: key);

  @override
  State<DrawingBoardWidget> createState() => _DrawingBoardWidgetState();
}

class _DrawingBoardWidgetState extends State<DrawingBoardWidget> {
  // Widget state variables
  bool _isDrawingTurn = false; // Whether it's this user's turn to draw
  String? _currentDrawerId; // ID of the current active drawer
  bool _isObserver = true; // By default, all users are observers

  // Username for display purposes (in a real app, you'd use authentication)
  final String _username = "User-${Random().nextInt(1000)}";
  String? _activeDrawerName;
  Timer? _syncThrottleTimer;
  bool _hasChangesToSync = false;

  // Drawing state
  int? _lastUpdateTime;
  bool _isSyncing = false;
  String? _currentUserId = UniqueKey().toString(); // Simple user identification
  final List<DrawingElement> _elements = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4.0;
  late Map<DrawMode, Tool> _tools;
  late Tool _currentTool;
  final ScrollController _toolsController = ScrollController();

  // Timer countdown
  int _seconds = 60;
  Timer? _timer;

  // Format seconds as mm:ss
  String get _timerText {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Add this getter at the class level
  double get toolbarHeight => _isDrawingTurn ? 50.0 : 35.0;

  @override
  void initState() {
    super.initState();
    print("Drawing Board initializing with userId: $_currentUserId");
    print("Username: $_username");

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_seconds > 0)
          _seconds--;
        else {
          _timer?.cancel();
          // Optionally release the drawing turn when time is up
          if (_isDrawingTurn) {
            _releaseDrawingTurn();
          }
        }
      });
    });
    _rebuildTools();

    // Start listening for updates from other users
    listenForUpdates();

    // Wait a bit before setting up drawing session to ensure Firebase is connected
    Future.delayed(Duration(milliseconds: 500), () {
      _setupDrawingSession();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _syncThrottleTimer?.cancel();
    _toolsController.dispose();
    super.dispose();
  }

  void _rebuildTools() {
    _tools = {
      for (var mode in DrawMode.values) mode: _makeTool(mode),
    };
    _currentTool = _tools[_selectedMode]!;
  }

  void _throttledSync() {
    _hasChangesToSync = true;

    if (_syncThrottleTimer == null || !_syncThrottleTimer!.isActive) {
      _syncThrottleTimer = Timer(const Duration(milliseconds: 300), () {
        if (_hasChangesToSync) {
          syncWithFirebase();
          _hasChangesToSync = false;
        }
      });
    }
  }

  // Get the full drawing state as JSON
  Map<String, dynamic> exportDrawing() {
    return {
      'elements': _elements.map((e) => e.toJson()).toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Import a drawing from JSON
  void importDrawing(Map<String, dynamic> json) {
    final elementsList = json['elements'] as List;
    setState(() {
      _elements.clear();
      for (var elem in elementsList) {
        try {
          _elements.add(DrawingElement.fromJson(elem));
        } catch (e) {
          print('Error parsing element: $e');
        }
      }
    });
  }

  void _setupDrawingSession() async {
    print("Setting up drawing session...");
    try {
      // First, check if there's an active drawing session
      final docRef =
          FirebaseFirestore.instance.collection('games').doc('game-id');
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();

        if (data != null && data['currentDrawerId'] != null) {
          // There's an active drawer
          setState(() {
            _currentDrawerId = data['currentDrawerId'];
            _activeDrawerName = data['currentDrawerName'] ?? 'Unknown';
            _isDrawingTurn = _currentDrawerId == _currentUserId;
            _isObserver = !_isDrawingTurn;
          });

          print(
              "Current drawer is: ${data['currentDrawerName'] ?? 'Unknown'} (ID: ${data['currentDrawerId']})");
          print("My turn? $_isDrawingTurn");
        } else {
          print("No active drawer found, trying to become one");
          // No active drawer, try to become one
          _claimDrawingTurn();
        }
      } else {
        print("Game document doesn't exist yet, trying to become first drawer");
        // Document doesn't exist yet, try to become the first drawer
        _claimDrawingTurn();
      }
    } catch (e) {
      print("Error setting up drawing session: $e");
    }
  }

  void _claimDrawingTurn() async {
    print("Attempting to claim drawing turn...");

    try {
      // First check if there's already a drawer
      final docRef =
          FirebaseFirestore.instance.collection('games').doc('game-id');
      final snapshot = await docRef.get();

      if (!snapshot.exists ||
          snapshot.data() == null ||
          snapshot.data()!['currentDrawerId'] == null) {
        // No active drawer, claim the turn directly
        await docRef.set({
          'currentDrawerId': _currentUserId,
          'currentDrawerName': _username,
          'turnStartedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));

        setState(() {
          _currentDrawerId = _currentUserId;
          _isDrawingTurn = true;
          _isObserver = false;
          _activeDrawerName = _username;
        });

        print("Successfully claimed drawing turn as first drawer");
      } else if (snapshot.data()!['currentDrawerId'] == _currentUserId) {
        // This user is already the drawer, just update the state
        setState(() {
          _isDrawingTurn = true;
          _isObserver = false;
        });

        print("Already the active drawer");
      } else {
        // Someone else is already drawing
        setState(() {
          _currentDrawerId = snapshot.data()!['currentDrawerId'];
          _activeDrawerName = snapshot.data()!['currentDrawerName'];
          _isDrawingTurn = false;
          _isObserver = true;
        });

        print(
            "Cannot claim turn: ${_activeDrawerName ?? 'Someone else'} is already drawing");

        // Show a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${_activeDrawerName ?? 'Someone else'} is currently drawing"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error claiming drawing turn: $e");
      // Try again with a simpler approach if transaction failed
      _forceClaimDrawingTurn();
    }
  }

  void _forceClaimDrawingTurn() async {
    print("FORCE-claiming drawing turn...");

    try {
      final docRef =
          FirebaseFirestore.instance.collection('games').doc('game-id');

      // First, clear any existing drawing data to start fresh
      await docRef.set({
        'currentDrawerId': _currentUserId,
        'currentDrawerName': _username,
        'turnStartedAt': DateTime.now().millisecondsSinceEpoch,
        'drawing': {
          'elements': [],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      });

      setState(() {
        _currentDrawerId = _currentUserId;
        _isDrawingTurn = true;
        _isObserver = false;
        _activeDrawerName = _username;
        _elements.clear(); // Clear local elements too
      });

      print("Successfully FORCE-claimed drawing turn");

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You've forcefully taken control of drawing"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error force-claiming drawing turn: $e");

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to take control: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _releaseDrawingTurn() async {
    // Only the current drawer can release their turn
    if (_currentDrawerId == _currentUserId) {
      try {
        await FirebaseFirestore.instance
            .collection('games')
            .doc('game-id')
            .update({'currentDrawerId': null, 'currentDrawerName': null});

        setState(() {
          _isDrawingTurn = false;
          _isObserver = true;
        });

        print("Drawing turn released");
      } catch (e) {
        print("Error releasing drawing turn: $e");
      }
    }
  }

  // Sync drawing with Firebase
  void syncWithFirebase() {
    // Only sync if it's this user's turn to draw
    if (!_isDrawingTurn) {
      print("Not your turn to draw - sync canceled");
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final drawingData = exportDrawing();

      // Add user ID to identify who made this change
      final dataToSync = {
        'drawing': drawingData,
        'lastEditBy': _currentUserId,
      };

      // Update local timestamp tracker
      _lastUpdateTime = drawingData['timestamp'];

      // This creates/updates a document at games/game-id with fields
      FirebaseFirestore.instance
          .collection('games')
          .doc('game-id')
          .set(dataToSync, SetOptions(merge: true))
          .then((_) {
        print('Drawing synced to Firebase');
        setState(() => _isSyncing = false);
      }).catchError((e) {
        print('Error syncing drawing: $e');
        setState(() => _isSyncing = false);
      });
    } catch (e) {
      print('Error preparing drawing data: $e');
      setState(() => _isSyncing = false);
    }
  }

  void listenForUpdates() {
    print("Starting to listen for drawing updates from Firebase");
    FirebaseFirestore.instance
        .collection('games')
        .doc('game-id')
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();

          // Update drawer information
          if (data != null && data['currentDrawerId'] != null) {
            final newDrawerId = data['currentDrawerId'];
            final newDrawerName = data['currentDrawerName'] ?? 'Unknown';

            print("Current drawer update: $newDrawerName (ID: $newDrawerId)");
            print("My user ID: $_currentUserId");

            setState(() {
              _currentDrawerId = newDrawerId;
              _activeDrawerName = newDrawerName;
              _isDrawingTurn = newDrawerId == _currentUserId;
              _isObserver = !_isDrawingTurn;
            });

            print("Am I drawing? $_isDrawingTurn");
          } else if (data != null && data['currentDrawerId'] == null) {
            // No active drawer
            print("No active drawer found in Firestore");
            setState(() {
              _currentDrawerId = null;
              _activeDrawerName = null;
            });
          }

          // Handle drawing updates
          if (data != null && data['drawing'] != null) {
            print('Received drawing update from Firebase');

            // Check if this update is from another user
            final timestamp = data['drawing']['timestamp'] as int;
            final lastUpdateTime = _lastUpdateTime ?? 0;

            // Only process updates that are newer than our last sync
            if (timestamp > lastUpdateTime) {
              setState(() {
                importDrawing(data['drawing']);
                _lastUpdateTime = timestamp;
              });
            }
          }
        } else {
          print("Game document does not exist yet");
        }
      },
      onError: (e) => print('Error listening to drawing updates: $e'),
    );
  }

  Tool _makeTool(DrawMode mode) {
    final ctx = DrawingContext(
      elements: _elements,
      color: _selectedColor,
      strokeWidth: _strokeWidth,
      addElement: (e) => setState(() {
        _elements.add(e);
        // Sync after each change
        _throttledSync();
      }),
      fillAt: (pos) => setState(() {
        _fillShape(pos);
        _throttledSync();
      }),
    );
    switch (mode) {
      case DrawMode.pencil:
        return PencilTool(ctx);
      case DrawMode.line:
        return LineTool(ctx);
      case DrawMode.rectangle:
        return RectangleTool(ctx);
      case DrawMode.circle:
        return CircleTool(ctx);
      case DrawMode.eraser:
        return EraserTool(ctx);
      case DrawMode.fill:
        return FillTool(ctx);
    }
  }

  DrawMode _selectedMode = DrawMode.pencil;
  void _selectTool(DrawMode mode) {
    setState(() {
      _selectedMode = mode;
      _rebuildTools();
    });
  }

  void _fillShape(Offset pos) {
    setState(() {
      bool applied = false;

      // iterate top‐down
      for (var e in _elements.reversed) {
        if (e is RectangleDrawing) {
          final rect = Rect.fromPoints(e.start, e.end);
          if (rect.contains(pos)) {
            _elements.add(RectangleDrawing(
              start: e.start,
              end: e.end,
              color: _selectedColor,
              strokeWidth: e.strokeWidth,
              isFilled: true,
            ));
            applied = true;
            break;
          }
        }
        if (e is CircleDrawing) {
          final center = Offset(
            (e.start.dx + e.end.dx) / 2,
            (e.start.dy + e.end.dy) / 2,
          );
          final radius = (e.start - e.end).distance / 2;
          if ((pos - center).distance <= radius) {
            _elements.add(CircleDrawing(
              start: e.start,
              end: e.end,
              color: _selectedColor,
              strokeWidth: e.strokeWidth,
              isFilled: true,
            ));
            applied = true;
            break;
          }
        }
        if (e is FreehandDrawing) {
          final path = Path()..moveTo(e.points.first.dx, e.points.first.dy);
          for (var p in e.points.skip(1)) path.lineTo(p.dx, p.dy);
          path.close();
          if (path.contains(pos)) {
            _elements.add(FillPolygonDrawing(
              points: List.from(e.points),
              color: _selectedColor,
            ));
            applied = true;
            break;
          }
        }
      }

      if (!applied) {
        // full‐canvas fill
        _elements.add(FillCanvasDrawing(color: _selectedColor));
      }
    });
  }

  void _clearCanvas() => setState(() {
        _elements.clear();
        syncWithFirebase();
      });

  void _undo() => setState(() {
        if (_elements.isNotEmpty) _elements.removeLast();
        syncWithFirebase();
      });

  // New implementation for _showBrushSizes method
  void _showBrushSizes(BuildContext context) {
    final sizes = [2.0, 5.0, 10.0, 15.0];

    // Get the button position
    final RenderBox buttonBox = context.findRenderObject() as RenderBox;
    final buttonPos = buttonBox.localToGlobal(Offset.zero);

    // Get screen size
    final screenSize = MediaQuery.of(context).size;

    // Calculate position - explicitly above toolbar
    final double popupBottom = screenSize.height - buttonPos.dy - 500;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 100),
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: popupBottom),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 180,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: sizes.map((brushSize) {
                    final isSelected = (_strokeWidth - brushSize).abs() < 0.5;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _strokeWidth = brushSize;
                          _rebuildTools();
                        });
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color:
                                isSelected ? Colors.blue : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Container(
                            height: brushSize,
                            width: 20,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              borderRadius:
                                  BorderRadius.circular(brushSize / 2),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // New implementation for _showColorPalette method
  void _showColorPalette(BuildContext context) {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    // Get the button position
    final RenderBox buttonBox = context.findRenderObject() as RenderBox;
    final buttonPos = buttonBox.localToGlobal(Offset.zero);

    // Get screen size
    final screenSize = MediaQuery.of(context).size;

    // Calculate position - explicitly above toolbar
    final double popupBottom = screenSize.height - buttonPos.dy - 500;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 100),
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: popupBottom),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 230,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: colors.map((color) {
                        final isSelected = _selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                              _rebuildTools();
                            });
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSelected ? Colors.blue : Colors.black12,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 4)
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Add method to allow external timer control

  // Add this method to the DrawingBoardWidget class
  void handleTimeUp(String nextDrawerId, String nextDrawerName) {
    if (_isDrawingTurn) {
      // Only release if this user is currently drawing
      _releaseDrawingTurn();
    }

    // Update the state variables
    setState(() {
      _currentDrawerId = nextDrawerId;
      _activeDrawerName = nextDrawerName;
      _isDrawingTurn = _currentUserId == nextDrawerId;
      _isObserver = !_isDrawingTurn;
    });

    // Force update in Firebase
    FirebaseFirestore.instance.collection('games').doc('game-id').update({
      'currentDrawerId': nextDrawerId,
      'currentDrawerName': nextDrawerName,
      'turnStartedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(children: [
        // This is the updated Drawer status indicator
        if (_currentDrawerId != null &&
            !_isDrawingTurn) // Only show if someone else is drawing
          Positioned(
            top: 0, // Move to top since we removed the other header
            left: 0,
            right: 0,
            child: Container(
              color: Colors.blue.withOpacity(0.1),
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  "${_activeDrawerName ?? 'Someone'} is drawing...",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ),
          ),

        // Canvas - position with more space at bottom to prevent overflow
        Positioned.fill(
          top: _isDrawingTurn
              ? 0
              : 0, // Adjust based on whether the status bar is showing
          bottom: toolbarHeight + 10, // Increased bottom padding
          child: Builder(builder: (ctx) {
            return GestureDetector(
              onPanStart: _isDrawingTurn
                  ? (d) {
                      final box = ctx.findRenderObject() as RenderBox;
                      _currentTool
                          .onPanStart(box.globalToLocal(d.globalPosition));
                      setState(() {});
                    }
                  : null,
              onPanUpdate: _isDrawingTurn
                  ? (d) {
                      final box = ctx.findRenderObject() as RenderBox;
                      _currentTool
                          .onPanUpdate(box.globalToLocal(d.globalPosition));
                      setState(() {});
                    }
                  : null,
              onPanEnd: _isDrawingTurn
                  ? (_) {
                      _currentTool.onPanEnd();
                    }
                  : null,
              child: ClipRect(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _DrawingPainter(
                    elements: _elements,
                    previewTool: _currentTool,
                  ),
                ),
              ),
            );
          }),
        ),

        // Sync indicator
        if (_isSyncing)
          Positioned(
            top: 16,
            right: 60,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ),

        // Take turn button
        if (_currentDrawerId == null)
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  print("Take turn button pressed");
                  _claimDrawingTurn();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  "Take your turn to draw!",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),

        // Force take turn button
        if (_currentDrawerId != null && !_isDrawingTurn)
          Positioned(
            bottom: 10, // Position closer to bottom
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  print("FORCE taking drawing turn");
                  _forceClaimDrawingTurn();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8), // Smaller padding
                ),
                child: Text(
                  "Take Turn (Override)",
                  style: TextStyle(
                      fontSize: 12, color: Colors.white), // Smaller text
                ),
              ),
            ),
          ),

        // Drawing tools - more compact single row
        if (_isDrawingTurn)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: toolbarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  // Add scroll view for drawing tools
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      controller: _toolsController,
                      children: [
                        // Drawing tools with smaller buttons
                        ...DrawMode.values.map((mode) {
                          final icon = {
                            DrawMode.pencil: Icons.brush,
                            DrawMode.line: Icons.show_chart,
                            DrawMode.rectangle: Icons.crop_square,
                            DrawMode.circle: Icons.circle_outlined,
                            DrawMode.fill: Icons.format_color_fill,
                            DrawMode.eraser: Icons.auto_fix_normal,
                          }[mode]!;
                          final sel = _selectedMode == mode;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: GestureDetector(
                              onTap: () => _selectTool(mode),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color:
                                      sel ? Colors.blue.withOpacity(0.2) : null,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: sel
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  size: 16,
                                  color: sel ? Colors.blue : Colors.black54,
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(width: 4),

                        // Current color button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: GestureDetector(
                            onTap: () => _showColorPalette(context),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _selectedColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black26),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 3)
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 4),

                        // Brush size button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: GestureDetector(
                            onTap: () => _showBrushSizes(context),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: Container(
                                  height: _strokeWidth.clamp(1, 12),
                                  width: 20,
                                  decoration: BoxDecoration(
                                    color: _selectedColor,
                                    borderRadius:
                                        BorderRadius.circular(_strokeWidth / 2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right side buttons (fixed position)
                  Row(
                    children: [
                      // Undo button
                      IconButton(
                        icon: Icon(Icons.undo, size: 16),
                        onPressed: _undo,
                        padding: EdgeInsets.all(2),
                        constraints:
                            BoxConstraints(minWidth: 34, minHeight: 34),
                      ),

                      // Clear canvas button
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 16),
                        onPressed: _clearCanvas,
                        padding: EdgeInsets.all(2),
                        constraints:
                            BoxConstraints(minWidth: 34, minHeight: 34),
                      ),

                      // Remove the end turn button since we'll handle that automatically with the timer
                    ],
                  ),
                ],
              ),
            ),
          ),

        // For non-drawing users, add a status indicator at the bottom
        if (!_isDrawingTurn)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 6, horizontal: 16), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ], // Smaller shadow
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility,
                      size: 14, color: Colors.blue.shade700), // Smaller icon
                  const SizedBox(width: 4), // Smaller spacing
                  Text(
                    "Observer mode",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                      fontSize: 12, // Smaller text
                    ),
                  ),
                ],
              ),
            ),
          ),
      ]);
    });
  }
}

//=== Painter ================================================================
class _DrawingPainter extends CustomPainter {
  final List<DrawingElement> elements;
  final Tool previewTool;

  _DrawingPainter({required this.elements, required this.previewTool});

  @override
  void paint(Canvas canvas, Size size) {
    for (var e in elements) e.draw(canvas);
    previewTool.drawPreview(canvas);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter old) => true;
}

//=== DrawingElement classes =================================================
abstract class DrawingElement {
  final Color color;
  final double strokeWidth;
  DrawingElement({required this.color, required this.strokeWidth});
  void draw(Canvas canvas);
  Map<String, dynamic> toJson();

  factory DrawingElement.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final color = Color(json['color'] as int);
    final strokeWidth = json['strokeWidth'] as double;

    switch (type) {
      case 'freehand':
        final pointsData = json['points'] as List;
        final points = pointsData
            .map((p) => Offset(p['x'] as double, p['y'] as double))
            .toList();
        return FreehandDrawing(
          points: points,
          color: color,
          strokeWidth: strokeWidth,
        );
      case 'line':
        return LineDrawing(
          start: Offset(json['startX'] as double, json['startY'] as double),
          end: Offset(json['endX'] as double, json['endY'] as double),
          color: color,
          strokeWidth: strokeWidth,
        );
      case 'rectangle':
        return RectangleDrawing(
          start: Offset(json['startX'] as double, json['startY'] as double),
          end: Offset(json['endX'] as double, json['endY'] as double),
          color: color,
          strokeWidth: strokeWidth,
          isFilled: json['isFilled'] as bool,
        );
      case 'circle':
        return CircleDrawing(
          start: Offset(json['startX'] as double, json['startY'] as double),
          end: Offset(json['endX'] as double, json['endY'] as double),
          color: color,
          strokeWidth: strokeWidth,
          isFilled: json['isFilled'] as bool,
        );
      case 'fillpolygon':
        final pointsData = json['points'] as List;
        final points = pointsData
            .map((p) => Offset(p['x'] as double, p['y'] as double))
            .toList();
        return FillPolygonDrawing(
          points: points,
          color: color,
        );
      case 'fillcanvas':
        return FillCanvasDrawing(
          color: color,
        );
      default:
        throw FormatException('Unknown drawing element type: $type');
    }
  }
}

class FreehandDrawing extends DrawingElement {
  final List<Offset> points;
  FreehandDrawing({
    required this.points,
    required Color color,
    required double strokeWidth,
  }) : super(color: color, strokeWidth: strokeWidth);

  @override
  void draw(Canvas canvas) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var p in points.skip(1)) path.lineTo(p.dx, p.dy);
    canvas.drawPath(path, paint);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'freehand',
      'color': color.value,
      'strokeWidth': strokeWidth,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    };
  }
}

class LineDrawing extends DrawingElement {
  final Offset start, end;
  LineDrawing({
    required this.start,
    required this.end,
    required Color color,
    required double strokeWidth,
  }) : super(color: color, strokeWidth: strokeWidth);

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, paint);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'line',
      'color': color.value,
      'strokeWidth': strokeWidth,
      'startX': start.dx,
      'startY': start.dy,
      'endX': end.dx,
      'endY': end.dy,
    };
  }
}

class RectangleDrawing extends DrawingElement {
  final Offset start, end;
  final bool isFilled;
  RectangleDrawing({
    required this.start,
    required this.end,
    required Color color,
    required double strokeWidth,
    required this.isFilled,
  }) : super(color: color, strokeWidth: strokeWidth);

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke;
    canvas.drawRect(Rect.fromPoints(start, end), paint);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'rectangle',
      'color': color.value,
      'strokeWidth': strokeWidth,
      'startX': start.dx,
      'startY': start.dy,
      'endX': end.dx,
      'endY': end.dy,
      'isFilled': isFilled,
    };
  }
}

class CircleDrawing extends DrawingElement {
  final Offset start, end;
  final bool isFilled;
  CircleDrawing({
    required this.start,
    required this.end,
    required Color color,
    required double strokeWidth,
    required this.isFilled,
  }) : super(color: color, strokeWidth: strokeWidth);

  @override
  void draw(Canvas canvas) {
    final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final radius = (start - end).distance / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'circle',
      'color': color.value,
      'strokeWidth': strokeWidth,
      'startX': start.dx,
      'startY': start.dy,
      'endX': end.dx,
      'endY': end.dy,
      'isFilled': isFilled,
    };
  }
}

class FillPolygonDrawing extends DrawingElement {
  final List<Offset> points;
  FillPolygonDrawing({required this.points, required Color color})
      : super(color: color, strokeWidth: 0);

  @override
  void draw(Canvas canvas) {
    if (points.length < 3) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var p in points.skip(1)) path.lineTo(p.dx, p.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'fillpolygon',
      'color': color.value,
      'strokeWidth': strokeWidth,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    };
  }
}

class FillCanvasDrawing extends DrawingElement {
  FillCanvasDrawing({required Color color})
      : super(color: color, strokeWidth: 0);

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Instead of covering the whole surface, draw a rectangle that fits the canvas
    // This assumes the canvas is the size of the clipped area
    canvas.drawRect(Rect.largest, paint);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'fillcanvas',
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }
}
