import 'dart:ui';
import 'package:flutter/material.dart';

abstract class DrawingElement {
  final Color color;
  final double strokeWidth;

  DrawingElement({required this.color, required this.strokeWidth});

  void draw(Canvas canvas);

  Map<String, dynamic> toJson();

  factory DrawingElement.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final color = Color(json['color'] as int);
    final strokeWidth = (json['strokeWidth'] as num).toDouble();

    switch (type) {
      case 'freehand':
        final pointsData = json['points'] as List;
        final points = pointsData
            .map((p) =>
                Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
            .toList();
        return FreehandDrawing(
          points: points,
          color: color,
          strokeWidth: strokeWidth,
        );

      case 'line':
        return LineDrawing(
          start: Offset(
            (json['startX'] as num).toDouble(),
            (json['startY'] as num).toDouble(),
          ),
          end: Offset(
            (json['endX'] as num).toDouble(),
            (json['endY'] as num).toDouble(),
          ),
          color: color,
          strokeWidth: strokeWidth,
        );

      case 'rectangle':
        return RectangleDrawing(
          start: Offset(
            (json['startX'] as num).toDouble(),
            (json['startY'] as num).toDouble(),
          ),
          end: Offset(
            (json['endX'] as num).toDouble(),
            (json['endY'] as num).toDouble(),
          ),
          color: color,
          strokeWidth: strokeWidth,
          isFilled: json['isFilled'] as bool,
        );

      case 'circle':
        return CircleDrawing(
          start: Offset(
            (json['startX'] as num).toDouble(),
            (json['startY'] as num).toDouble(),
          ),
          end: Offset(
            (json['endX'] as num).toDouble(),
            (json['endY'] as num).toDouble(),
          ),
          color: color,
          strokeWidth: strokeWidth,
          isFilled: json['isFilled'] as bool,
        );

      case 'fillpolygon':
        final pointsData = json['points'] as List;
        final points = pointsData
            .map((p) =>
                Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
            .toList();
        return FillPolygonDrawing(
          points: points,
          color: color,
        );

      case 'fillcanvas':
        return FillCanvasDrawing(
          color: color,
        );

      case 'clippedfill':
        return ClippedFillDrawing(
          color: color,
          clipRect: Rect.fromLTRB(
            (json['left'] as num).toDouble(),
            (json['top'] as num).toDouble(),
            (json['right'] as num).toDouble(),
            (json['bottom'] as num).toDouble(),
          ),
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
    for (var p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

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
    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
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

  FillPolygonDrawing({
    required this.points,
    required Color color,
  }) : super(color: color, strokeWidth: 0);

  @override
  void draw(Canvas canvas) {
    if (points.length < 3) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
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
  FillCanvasDrawing({
    required Color color,
  }) : super(color: color, strokeWidth: 0);

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

// Add this class to your drawing elements

// This class fills only within a specific rectangle, preventing fill from affecting chat area
class ClippedFillDrawing extends DrawingElement {
  final Rect clipRect;

  ClippedFillDrawing({
    required Color color,
    required this.clipRect,
  }) : super(color: color, strokeWidth: 0);

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Save the canvas state
    canvas.save();

    // Clip to the drawing area only
    canvas.clipRect(clipRect);

    // Fill only within the clipped area
    canvas.drawRect(clipRect, paint);

    // Restore the canvas to its previous state
    canvas.restore();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'clippedfill',
      'color': color.value,
      'strokeWidth': strokeWidth,
      'left': clipRect.left,
      'top': clipRect.top,
      'right': clipRect.right,
      'bottom': clipRect.bottom,
    };
  }

  static DrawingElement fromJson(Map<String, dynamic> json) {
    return ClippedFillDrawing(
      color: Color(json['color'] as int),
      clipRect: Rect.fromLTRB(
        (json['left'] as num).toDouble(),
        (json['top'] as num).toDouble(),
        (json['right'] as num).toDouble(),
        (json['bottom'] as num).toDouble(),
      ),
    );
  }
}
