import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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

//=== Page & State ===========================================================
class DrawingBoardPage extends StatefulWidget {
  const DrawingBoardPage({Key? key}) : super(key: key);
  @override
  State<DrawingBoardPage> createState() => _DrawingBoardPageState();
}

class _DrawingBoardPageState extends State<DrawingBoardPage> {
  bool _isOtherUserDrawing = false;
  String? _activeDrawerName;
  Timer? _otherUserActivityTimer;
  Timer? _syncThrottleTimer;
  bool _hasChangesToSync = false;
  // Add at the top of your _DrawingBoardPageState class:
  int? _lastUpdateTime;
  bool _isSyncing = false;
  String? _currentUserId = UniqueKey().toString(); // Simple user identification
  final List<DrawingElement> _elements = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4.0;
  late Map<DrawMode, Tool> _tools;
  late Tool _currentTool;
  final ScrollController _toolsController = ScrollController();

  // Timer countdown from 60s
  int _seconds = 60;
  Timer? _timer;

  // Format seconds as mm:ss
  String get _timerText {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_seconds > 0)
          _seconds--;
        else
          _timer?.cancel();
      });
    });
    _rebuildTools();

    // Start listening for updates from other users
    listenForUpdates();
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

// Sync drawing with Firebase
// Sync drawing with Firebase
  void syncWithFirebase() {
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
          .doc('game-id') // Use dynamic game IDs in production
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

// Listen for updates
  void listenForUpdates() {
    print("Starting to listen for drawing updates from Firebase");
    FirebaseFirestore.instance
        .collection('games')
        .doc('game-id') // Use dynamic game IDs in production
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
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
        _throttledSync(); // <-- Add this call
      }),
      fillAt: (pos) => setState(() {
        _fillShape(pos);
        _throttledSync(); // <-- Add this call
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: // Add to your AppBar
          AppBar(
        title: const Text('Skribbl Board'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_isSyncing)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
          IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
          IconButton(
              icon: const Icon(Icons.delete_outline), onPressed: _clearCanvas),
        ],
      ),
      body: Stack(children: [
        // Top bar: centered dummy word + right‐aligned timer
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Stack(children: [
            Center(
              child: Text(
                'HOUSE',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer),
                  const SizedBox(width: 4),
                  Text(_timerText, style: const TextStyle(fontSize: 16)),
                ]),
              ),
            ),
          ]),
        ),

        // Canvas
        Builder(builder: (ctx) {
          return GestureDetector(
            onPanStart: (d) {
              final box = ctx.findRenderObject() as RenderBox;
              _currentTool.onPanStart(box.globalToLocal(d.globalPosition));
              setState(() {});
            },
            onPanUpdate: (d) {
              final box = ctx.findRenderObject() as RenderBox;
              _currentTool.onPanUpdate(box.globalToLocal(d.globalPosition));
              setState(() {});
            },
            onPanEnd: (_) {
              _currentTool.onPanEnd();
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: _DrawingPainter(
                elements: _elements,
                previewTool: _currentTool,
              ),
            ),
          );
        }),

        // Bottom tools panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  controller: _toolsController,
                  children: DrawMode.values.map((mode) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => _selectTool(mode),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: sel ? Colors.blue.withOpacity(0.2) : null,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    sel ? Colors.blue : Colors.grey.shade300),
                          ),
                          child: Icon(icon,
                              color: sel ? Colors.blue : Colors.black54),
                        ),
                      ),
                    );
                  }).toList()
                    ..addAll([
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: const SizedBox(width: 8),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: 150,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(children: [
                            const Icon(Icons.line_weight, size: 16),
                            Expanded(
                              child: Slider(
                                min: 1,
                                max: 20,
                                value: _strokeWidth,
                                activeColor: _selectedColor,
                                onChanged: (v) => setState(() {
                                  _strokeWidth = v;
                                  _rebuildTools();
                                }),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Colors.black,
                    Colors.white,
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.yellow,
                    Colors.orange,
                    Colors.purple,
                    Colors.pink,
                    Colors.brown,
                    Colors.teal,
                    Colors.indigo,
                  ].map((c) {
                    final sel = c == _selectedColor;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedColor = c;
                          _rebuildTools();
                        }),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.black26, width: sel ? 2 : 1),
                          ),
                          child: sel
                              ? Icon(Icons.check,
                                  size: 16,
                                  color: c.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
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

//=== DrawingElement classes (unchanged) =====================================
abstract class DrawingElement {
  final Color color;
  final double strokeWidth;
  DrawingElement({required this.color, required this.strokeWidth});
  void draw(Canvas canvas);
  // Add this abstract method declaration:
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
      'type': 'freehand', // different for each type
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
    canvas.drawPaint(paint); // covers whole surface
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
