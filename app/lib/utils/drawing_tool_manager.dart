import 'package:flutter/material.dart';
import 'package:app/models/drawing_element_model.dart';
import 'package:app/viewmodels/drawing_view_model.dart';
import 'package:app/models/enums/draw_mode.dart';

class DrawingToolManager {
  final DrawingViewModel viewModel;
  DrawingElement? _previewElement;
  List<Offset> _points = [];
  Offset? _startPoint;
  bool _hasChangesToSync = false;

  DrawingToolManager(this.viewModel);

  DrawingElement? get previewElement => _previewElement;
  bool get hasChangesToSync => _hasChangesToSync;
  void clearSyncFlag() => _hasChangesToSync = false;

  void onPanStart(Offset position) {
    if (!viewModel.isMyTurn) return;

    _startPoint = position;
    _points = [position];

    switch (viewModel.selectedMode) {
      case DrawMode.pencil:
        _previewElement = FreehandDrawing(
          points: _points,
          color: viewModel.selectedColor,
          strokeWidth: viewModel.strokeWidth,
        );
        break;
      case DrawMode.eraser:
        _previewElement = FreehandDrawing(
          points: _points,
          color: Colors.white,
          strokeWidth: viewModel.strokeWidth * 2,
        );
        break;
      case DrawMode.line:
        _previewElement = LineDrawing(
          start: position,
          end: position,
          color: viewModel.selectedColor,
          strokeWidth: viewModel.strokeWidth,
        );
        break;
      case DrawMode.rectangle:
        _previewElement = RectangleDrawing(
          start: position,
          end: position,
          color: viewModel.selectedColor,
          strokeWidth: viewModel.strokeWidth,
          isFilled: false,
        );
        break;
      case DrawMode.circle:
        _previewElement = CircleDrawing(
          start: position,
          end: position,
          color: viewModel.selectedColor,
          strokeWidth: viewModel.strokeWidth,
          isFilled: false,
        );
        break;
      case DrawMode.fill:
        // Fill doesn't need a preview
        _fillShape(position);
        break;
    }
  }

  void onPanUpdate(Offset position) {
    if (_startPoint == null || !viewModel.isMyTurn) return;

    _points.add(position);

    switch (viewModel.selectedMode) {
      case DrawMode.pencil:
        _previewElement = FreehandDrawing(
          points: _points,
          color: viewModel.selectedColor,
          strokeWidth: viewModel.strokeWidth,
        );
        break;
      case DrawMode.eraser:
        _previewElement = FreehandDrawing(
          points: _points,
          color: Colors.white,
          strokeWidth: viewModel.strokeWidth * 2,
        );
        break;
      case DrawMode.line:
        _previewElement = LineDrawing(
          start: _startPoint!,
          end: position,
          color: viewModel.selectedColor,
          strokeWidth: viewModel.strokeWidth,
        );
        break;
      case DrawMode.rectangle:
        _previewElement = RectangleDrawing(
          start: _startPoint!,
          end: position,
          color: viewModel.selectedColor,
          strokeWidth: viewModel.strokeWidth,
          isFilled: false,
        );
        break;
      case DrawMode.circle:
        _previewElement = CircleDrawing(
          start: _startPoint!,
          end: position,
          color: viewModel.selectedColor,
          strokeWidth: viewModel.strokeWidth,
          isFilled: false,
        );
        break;
      case DrawMode.fill:
        // Fill doesn't update on pan
        break;
    }
  }

  void onPanEnd() {
    if (_startPoint == null || !viewModel.isMyTurn) return;

    switch (viewModel.selectedMode) {
      case DrawMode.pencil:
        if (_points.length > 1) {
          viewModel.addDrawingElement(FreehandDrawing(
            points: List.from(_points),
            color: viewModel.selectedColor,
            strokeWidth: viewModel.strokeWidth,
          ));
          _hasChangesToSync = true;
        }
        break;
      case DrawMode.eraser:
        if (_points.length > 1) {
          viewModel.addDrawingElement(FreehandDrawing(
            points: List.from(_points),
            color: Colors.white,
            strokeWidth: viewModel.strokeWidth * 2,
          ));
          _hasChangesToSync = true;
        }
        break;
      case DrawMode.line:
        viewModel.addDrawingElement(LineDrawing(
          start: _startPoint!,
          end: _points.last,
          color: viewModel.selectedColor,
          strokeWidth: viewModel.strokeWidth,
        ));
        _hasChangesToSync = true;
        break;
      case DrawMode.rectangle:
        viewModel.addDrawingElement(RectangleDrawing(
          start: _startPoint!,
          end: _points.last,
          color: viewModel.selectedColor,
          strokeWidth: viewModel.strokeWidth,
          isFilled: false,
        ));
        _hasChangesToSync = true;
        break;
      case DrawMode.circle:
        viewModel.addDrawingElement(CircleDrawing(
          start: _startPoint!,
          end: _points.last,
          color: viewModel.selectedColor,
          strokeWidth: viewModel.strokeWidth,
          isFilled: false,
        ));
        _hasChangesToSync = true;
        break;
      case DrawMode.fill:
        // Fill is handled in onPanStart
        _hasChangesToSync = true;
        break;
    }

    _previewElement = null;
    _startPoint = null;
    _points.clear();
  }

  void _fillShape(Offset pos) {
    if (!viewModel.isMyTurn) return;

    bool applied = false;
    Size? canvasSize; // This would ideally be provided by the widget
    Rect? clippingRect;

    if (canvasSize != null) {
      clippingRect =
          Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height * 0.6);
    }

    // Try to fill specific shapes first
    for (var e in viewModel.elements.reversed) {
      if (e is RectangleDrawing && !e.isFilled) {
        final rect = Rect.fromPoints(e.start, e.end);
        if (rect.contains(pos)) {
          viewModel.addDrawingElement(RectangleDrawing(
            start: e.start,
            end: e.end,
            color: viewModel.selectedColor,
            strokeWidth: e.strokeWidth,
            isFilled: true,
          ));
          applied = true;
          break;
        }
      } else if (e is CircleDrawing && !e.isFilled) {
        final center =
            Offset((e.start.dx + e.end.dx) / 2, (e.start.dy + e.end.dy) / 2);
        final radius = (e.start - e.end).distance / 2;

        if ((pos - center).distance <= radius) {
          viewModel.addDrawingElement(CircleDrawing(
            start: e.start,
            end: e.end,
            color: viewModel.selectedColor,
            strokeWidth: e.strokeWidth,
            isFilled: true,
          ));
          applied = true;
          break;
        }
      } else if (e is FreehandDrawing && e.points.length > 2) {
        if (_isPointInPath(pos, e.points)) {
          viewModel.addDrawingElement(FillPolygonDrawing(
            points: List.from(e.points),
            color: viewModel.selectedColor,
          ));
          applied = true;
          break;
        }
      }
    }

    // If no specific shape was filled, use a clipped fill
    if (!applied) {
      if (clippingRect != null) {
        viewModel.addDrawingElement(ClippedFillDrawing(
          color: viewModel.selectedColor,
          clipRect: clippingRect,
        ));
      } else {
        // Fallback - just use a rectangle that represents the drawing area
        viewModel.addDrawingElement(RectangleDrawing(
          start: Offset.zero,
          end: Offset(2000, 2000), // Large enough to cover canvas but not chat
          color: viewModel.selectedColor,
          strokeWidth: 0,
          isFilled: true,
        ));
      }
    }

    _hasChangesToSync = true;
  }

  // A simple way to check if a point is inside a polygon
  bool _isPointInPath(Offset point, List<Offset> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy)) &&
          (point.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (point.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx)) {
        inside = !inside;
      }
    }
    return inside;
  }

  void clearCanvas() {
    viewModel.clearCanvas();
    _hasChangesToSync = true;
  }

  void undo() {
    viewModel.undo();
    _hasChangesToSync = true;
  }

  // Reset the tool state
  void clear() {
    _previewElement = null;
    _startPoint = null;
    _points.clear();
  }
}

// Additional drawing element type for filled polygon
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
