import 'package:flutter/material.dart';
import 'package:app/models/drawing_element_model.dart';

class DrawingPainter extends CustomPainter {
  final List<DrawingElement> elements;
  final DrawingElement? previewElement;
  final Size? canvasSize;

  DrawingPainter({
    required this.elements,
    this.previewElement,
    this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Optional clipping if canvasSize is provided
    if (canvasSize != null) {
      canvas
          .clipRect(Rect.fromLTWH(0, 0, canvasSize!.width, canvasSize!.height));
    }

    // Paint all existing elements
    for (var element in elements) {
      element.draw(canvas);
    }

    // Draw preview element if available
    if (previewElement != null) {
      previewElement!.draw(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true; // Always repaint to ensure smooth drawing
  }
}
