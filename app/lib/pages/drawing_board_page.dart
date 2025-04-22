import 'package:flutter/material.dart';
import 'dart:math';

enum DrawMode { pencil, line, rectangle, circle, fill, eraser }

class DrawingBoardPage extends StatefulWidget {
  const DrawingBoardPage({super.key});

  @override
  State<DrawingBoardPage> createState() => _DrawingBoardPageState();
}

class _DrawingBoardPageState extends State<DrawingBoardPage> {
  List<DrawingElement> _elements = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4.0;
  DrawMode _drawMode = DrawMode.pencil;
  bool _isDrawing = false;

  // Add a scroll controller for horizontal tool options
  final ScrollController _toolsController = ScrollController();

  // Common colors for drawing
  final List<Color> _colors = [
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
  ];

  Offset? _startPoint;
  Offset? _endPoint;
  List<Offset> _currentPoints = [];

  void _startDrawing(Offset offset) {
    setState(() {
      _isDrawing = true;
      _startPoint = offset;
      _endPoint = offset;
      _currentPoints = [offset];
    });
  }

  void _updateDrawing(Offset offset) {
    if (!_isDrawing) return;

    setState(() {
      _endPoint = offset;
      if (_drawMode == DrawMode.pencil || _drawMode == DrawMode.eraser) {
        _currentPoints.add(offset);
      }
    });
  }

  void _stopDrawing() {
    if (!_isDrawing) return;

    if (_startPoint != null && _endPoint != null) {
      setState(() {
        switch (_drawMode) {
          case DrawMode.pencil:
            _elements.add(FreehandDrawing(
              points: List.from(_currentPoints),
              color: _selectedColor,
              strokeWidth: _strokeWidth,
            ));
            break;
          case DrawMode.eraser:
            _elements.add(FreehandDrawing(
              points: List.from(_currentPoints),
              color: Colors.white, // Canvas background color
              strokeWidth: _strokeWidth * 2,
            ));
            break;
          case DrawMode.line:
            _elements.add(LineDrawing(
              start: _startPoint!,
              end: _endPoint!,
              color: _selectedColor,
              strokeWidth: _strokeWidth,
            ));
            break;
          case DrawMode.rectangle:
            _elements.add(RectangleDrawing(
              start: _startPoint!,
              end: _endPoint!,
              color: _selectedColor,
              strokeWidth: _strokeWidth,
              isFilled: false,
            ));
            break;
          case DrawMode.circle:
            _elements.add(CircleDrawing(
              start: _startPoint!,
              end: _endPoint!,
              color: _selectedColor,
              strokeWidth: _strokeWidth,
              isFilled: false,
            ));
            break;
          case DrawMode.fill:
            // Handled in onTapDown
            break;
        }
        _currentPoints = [];
        _startPoint = null;
        _endPoint = null;
        _isDrawing = false;
      });
    }
  }

// Only the _fillShape method needs to be updated, so I'll provide just that method

  void _fillShape(Offset position) {
    bool shapeFilled = false;

    // For rectangles and circles, modify them in place
    for (int i = _elements.length - 1; i >= 0; i--) {
      final element = _elements[i];

      if (element is RectangleDrawing && !element.isFilled) {
        Rect rect = Rect.fromPoints(element.start, element.end);
        if (rect.contains(position)) {
          setState(() {
            _elements[i] = RectangleDrawing(
              start: element.start,
              end: element.end,
              color: _selectedColor,
              strokeWidth: element.strokeWidth,
              isFilled: true,
            );
          });
          shapeFilled = true;
          break;
        }
      } else if (element is CircleDrawing && !element.isFilled) {
        final center = Offset(
          (element.start.dx + element.end.dx) / 2,
          (element.start.dy + element.end.dy) / 2,
        );
        final radius = (element.start - element.end).distance / 2;
        if ((position - center).distance <= radius) {
          setState(() {
            _elements[i] = CircleDrawing(
              start: element.start,
              end: element.end,
              color: _selectedColor,
              strokeWidth: element.strokeWidth,
              isFilled: true,
            );
          });
          shapeFilled = true;
          break;
        }
      }
    }

    // Look for potential closed paths formed by multiple elements
    if (!shapeFilled) {
      // Find all line segments (from lines or freehand drawings)
      List<LineSegment> allSegments = [];

      for (var element in _elements) {
        if (element is LineDrawing) {
          allSegments.add(LineSegment(element.start, element.end));
        } else if (element is FreehandDrawing) {
          for (int i = 0; i < element.points.length - 1; i++) {
            allSegments
                .add(LineSegment(element.points[i], element.points[i + 1]));
          }
        }
      }

      // Try to find closed shapes formed by these segments
      List<List<LineSegment>> closedShapes = _findClosedShapes(allSegments);

      for (var shape in closedShapes) {
        if (_isPointInsidePolygon(shape, position)) {
          // Create a filled polygon
          List<Offset> points = [];
          if (shape.isNotEmpty) {
            points.add(shape[0].start);
            for (var segment in shape) {
              points.add(segment.end);
            }
          }

          setState(() {
            _elements.add(FilledPathDrawing(
              points: points,
              color: _selectedColor.withOpacity(0.7), // Semi-transparent fill
              strokeWidth: 1.0,
              outlineColor: _selectedColor,
            ));
          });

          shapeFilled = true;
          break;
        }
      }
    }

    // If no shape found and filled, fill the entire canvas
    if (!shapeFilled) {
      setState(() {
        // Get the size of the canvas
        final Size canvasSize = MediaQuery.of(context).size;

        // Create a full-canvas rectangle with the selected fill color
        _elements.add(RectangleDrawing(
          start: Offset.zero,
          end: Offset(canvasSize.width, canvasSize.height),
          color: _selectedColor,
          strokeWidth: 0,
          isFilled: true,
        ));
      });
    }
  }

  // Find possible closed shapes from a collection of line segments
  List<List<LineSegment>> _findClosedShapes(List<LineSegment> segments) {
    List<List<LineSegment>> closedShapes = [];

    // Simple implementation to find triangles
    if (segments.length < 3) return closedShapes;

    // Check each possible combination of 3 segments
    for (int i = 0; i < segments.length; i++) {
      for (int j = i + 1; j < segments.length; j++) {
        for (int k = j + 1; k < segments.length; k++) {
          var s1 = segments[i];
          var s2 = segments[j];
          var s3 = segments[k];

          // Check if these three segments form a triangle
          if (_segmentsConnect(s1, s2) &&
              _segmentsConnect(s2, s3) &&
              _segmentsConnect(s3, s1)) {
            closedShapes.add([s1, s2, s3]);
          }
        }
      }
    }

    return closedShapes;
  }

  // Check if two segments connect (share an endpoint)
  bool _segmentsConnect(LineSegment a, LineSegment b) {
    double tolerance = 10.0; // Allow some tolerance for connections

    return (a.start - b.start).distance < tolerance ||
        (a.start - b.end).distance < tolerance ||
        (a.end - b.start).distance < tolerance ||
        (a.end - b.end).distance < tolerance;
  }

  // Check if a point is inside a polygon using ray casting algorithm
  bool _isPointInsidePolygon(List<LineSegment> segments, Offset point) {
    if (segments.isEmpty) return false;

    // Extract vertices from segments
    List<Offset> vertices = [];
    if (segments.isNotEmpty) {
      vertices.add(segments[0].start);
      for (var segment in segments) {
        vertices.add(segment.end);
      }
    }

    if (vertices.length < 3) return false;

    // Ray casting algorithm
    bool isInside = false;
    int j = vertices.length - 1;

    for (int i = 0; i < vertices.length; i++) {
      if ((vertices[i].dy > point.dy) != (vertices[j].dy > point.dy) &&
          (point.dx <
              vertices[i].dx +
                  (vertices[j].dx - vertices[i].dx) *
                      (point.dy - vertices[i].dy) /
                      (vertices[j].dy - vertices[i].dy))) {
        isInside = !isInside;
      }
      j = i;
    }

    return isInside;
  }

  // Old implementation - kept for reference but not used
  bool _isPointInsideClosedPath(List<Offset> points, Offset point) {
    if (points.length < 3)
      return false; // Need at least 3 points to form a shape

    // Check if the path is reasonably closed
    double closureThreshold = 20.0; // Adjust based on your needs
    if ((points.first - points.last).distance > closureThreshold) {
      return false; // Path is not closed
    }

    // Ray casting algorithm
    bool isInside = false;
    int j = points.length - 1;

    for (int i = 0; i < points.length; i++) {
      if ((points[i].dy > point.dy) != (points[j].dy > point.dy) &&
          (point.dx <
              points[i].dx +
                  (points[j].dx - points[i].dx) *
                      (point.dy - points[i].dy) /
                      (points[j].dy - points[i].dy))) {
        isInside = !isInside;
      }
      j = i;
    }

    return isInside;
  }

  void _clearCanvas() {
    setState(() {
      _elements = [];
    });
  }

  void _undoLastElement() {
    if (_elements.isNotEmpty) {
      setState(() {
        _elements.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Skribbl Board",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoLastElement,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearCanvas,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Canvas area
          Builder(
            builder: (context) => GestureDetector(
              onPanStart: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final offset = renderBox.globalToLocal(details.globalPosition);
                if (_drawMode == DrawMode.fill) {
                  _fillShape(offset);
                } else {
                  _startDrawing(offset);
                }
              },
              onPanUpdate: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                _updateDrawing(renderBox.globalToLocal(details.globalPosition));
              },
              onPanEnd: (details) => _stopDrawing(),
              child: Container(
                color: Colors.white,
                child: CustomPaint(
                  painter: _DrawingPainter(
                    elements: _elements,
                    currentMode: _drawMode,
                    currentColor: _selectedColor,
                    currentStrokeWidth: _strokeWidth,
                    startPoint: _startPoint,
                    endPoint: _endPoint,
                    currentPoints: _currentPoints,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),

          // Bottom tools panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 130,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tool selection
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      controller: _toolsController,
                      children: [
                        _buildTool(Icons.brush, DrawMode.pencil, "Draw"),
                        // _buildTool(Icons.show_chart, DrawMode.line, "Line"),
                        // _buildTool(
                        //     Icons.crop_square, DrawMode.rectangle, "Rectangle"),
                        // _buildTool(
                        //     Icons.circle_outlined, DrawMode.circle, "Circle"),
                        _buildTool(
                            Icons.format_color_fill, DrawMode.fill, "Fill"),
                        // _buildTool(
                        //     Icons.auto_fix_normal, DrawMode.eraser, "Eraser"),
                        // const SizedBox(width: 8),
                        // Brush size slider
                        Container(
                          width: 150,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.line_weight, size: 16),
                              Expanded(
                                child: Slider(
                                  min: 1.0,
                                  max: 20.0,
                                  value: _strokeWidth,
                                  activeColor: _selectedColor,
                                  onChanged: (value) {
                                    setState(() => _strokeWidth = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Color selection
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _colors.map((color) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black26,
                                  width: _selectedColor == color ? 2 : 1,
                                ),
                                boxShadow: _selectedColor == color
                                    ? [
                                        BoxShadow(
                                            color: color.withOpacity(0.5),
                                            blurRadius: 6)
                                      ]
                                    : null,
                              ),
                              child: _selectedColor == color
                                  ? Icon(Icons.check,
                                      color: color.computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white,
                                      size: 16)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTool(IconData icon, DrawMode mode, String tooltip) {
    final isSelected = _drawMode == mode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: () => setState(() => _drawMode = mode),
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

// New helper class to represent line segments
class LineSegment {
  final Offset start;
  final Offset end;

  LineSegment(this.start, this.end);
}

abstract class DrawingElement {
  final Color color;
  final double strokeWidth;

  DrawingElement({required this.color, required this.strokeWidth});

  void draw(Canvas canvas);
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }
}

class LineDrawing extends DrawingElement {
  final Offset start;
  final Offset end;

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
}

class RectangleDrawing extends DrawingElement {
  final Offset start;
  final Offset end;
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
      ..strokeCap = StrokeCap.round
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke;

    canvas.drawRect(Rect.fromPoints(start, end), paint);
  }
}

class CircleDrawing extends DrawingElement {
  final Offset start;
  final Offset end;
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke;

    final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final radius = (start - end).distance / 2;
    canvas.drawCircle(center, radius, paint);
  }
}

class FillPoint extends DrawingElement {
  final Offset position;
  final double size;

  FillPoint({
    required this.position,
    required Color color,
    required this.size,
  }) : super(color: color, strokeWidth: 1.0);

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, size, paint);
  }
}

class FilledPathDrawing extends DrawingElement {
  final List<Offset> points;
  final Color outlineColor;

  FilledPathDrawing({
    required this.points,
    required Color color,
    required double strokeWidth,
    required this.outlineColor,
  }) : super(color: color, strokeWidth: strokeWidth);

  @override
  void draw(Canvas canvas) {
    if (points.length < 3) return;

    // Draw the fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    canvas.drawPath(path, fillPaint);

    // Draw the outline
    final outlinePaint = Paint()
      ..color = outlineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, outlinePaint);
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingElement> elements;
  final DrawMode currentMode;
  final Color currentColor;
  final double currentStrokeWidth;
  final Offset? startPoint;
  final Offset? endPoint;
  final List<Offset> currentPoints;

  _DrawingPainter({
    required this.elements,
    required this.currentMode,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.startPoint,
    required this.endPoint,
    required this.currentPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all saved elements
    for (var element in elements) {
      element.draw(canvas);
    }

    // Draw the current stroke being drawn
    if (startPoint != null && endPoint != null) {
      final paint = Paint()
        ..color = currentMode == DrawMode.eraser ? Colors.white : currentColor
        ..strokeWidth = currentMode == DrawMode.eraser
            ? currentStrokeWidth * 2
            : currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      switch (currentMode) {
        case DrawMode.pencil:
        case DrawMode.eraser:
          if (currentPoints.length >= 2) {
            final path = Path();
            path.moveTo(currentPoints.first.dx, currentPoints.first.dy);

            for (int i = 1; i < currentPoints.length; i++) {
              path.lineTo(currentPoints[i].dx, currentPoints[i].dy);
            }

            canvas.drawPath(path, paint);
          }
          break;
        case DrawMode.line:
          canvas.drawLine(startPoint!, endPoint!, paint);
          break;
        case DrawMode.rectangle:
          canvas.drawRect(Rect.fromPoints(startPoint!, endPoint!), paint);
          break;
        case DrawMode.circle:
          final center = Offset(
            (startPoint!.dx + endPoint!.dx) / 2,
            (startPoint!.dy + endPoint!.dy) / 2,
          );
          final radius = (startPoint! - endPoint!).distance / 2;
          canvas.drawCircle(center, radius, paint);
          break;
        default:
          break;
      }
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) => true;
}
