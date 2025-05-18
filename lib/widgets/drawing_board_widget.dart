import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/viewmodels/drawing_view_model.dart';
import 'package:app/models/enums/draw_mode.dart';
import 'package:app/utils/drawing_tool_manager.dart';
import 'package:app/utils/ui_helper.dart';
import 'package:app/widgets/drawing_painter.dart';

class DrawingBoardWidget extends StatefulWidget {
  final String roomId;

  const DrawingBoardWidget({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  State<DrawingBoardWidget> createState() => _DrawingBoardWidgetState();
}

class _DrawingBoardWidgetState extends State<DrawingBoardWidget> {
  late DrawingViewModel _viewModel;
  late DrawingToolManager _toolManager;
  final ScrollController _toolsController = ScrollController();
  Timer? _syncThrottleTimer;

  @override
  void initState() {
    super.initState();
    // Get the view model from provider
    _viewModel = Provider.of<DrawingViewModel>(context, listen: false);
    _toolManager = DrawingToolManager(_viewModel);

    // Set up throttled syncing
    _setupThrottledSync();
  }

  @override
  void dispose() {
    _toolsController.dispose();
    _syncThrottleTimer?.cancel();
    super.dispose();
  }

  void _setupThrottledSync() {
    _syncThrottleTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (_toolManager.hasChangesToSync && _viewModel.isMyTurn) {
        _viewModel.syncDrawingToFirebase();
        _toolManager.clearSyncFlag();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingViewModel>(
      builder: (context, viewModel, child) {
        _viewModel = viewModel; // Update reference to get latest changes

        return Stack(
          children: [
            Column(
              children: [
                // Drawing canvas
                Expanded(
                  child: ClipRect(
                    child: GestureDetector(
                      onPanStart: viewModel.isMyTurn
                          ? (details) {
                              _toolManager.onPanStart(details.localPosition);
                              setState(() {});
                            }
                          : null,
                      onPanUpdate: viewModel.isMyTurn
                          ? (details) {
                              _toolManager.onPanUpdate(details.localPosition);
                              setState(() {});
                            }
                          : null,
                      onPanEnd: viewModel.isMyTurn
                          ? (details) {
                              _toolManager.onPanEnd();
                              setState(() {});
                            }
                          : null,
                      child: Container(
                        color: Colors.white,
                        width: double.infinity,
                        height: double.infinity,
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: DrawingPainter(
                              elements: viewModel.elements,
                              previewElement: _toolManager.previewElement,
                              canvasSize: Size(
                                MediaQuery.of(context).size.width,
                                MediaQuery.of(context).size.height * 0.6,
                              ),
                            ),
                            willChange: true,
                            isComplex: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom toolbar exactly like in the screenshot
                if (viewModel.isMyTurn)
                  Container(
                    height: 50,
                    color: Colors.white,
                    child: Row(
                      children: [
                        // Left side tools in a compact row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: _toolsController,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Drawing tools
                              _buildToolButton(
                                icon: Icons.edit,
                                isSelected:
                                    viewModel.selectedMode == DrawMode.pencil,
                                onPressed: () =>
                                    viewModel.selectMode(DrawMode.pencil),
                                tooltip: 'Pencil',
                              ),
                              _buildToolButton(
                                icon: Icons.show_chart,
                                isSelected:
                                    viewModel.selectedMode == DrawMode.line,
                                onPressed: () =>
                                    viewModel.selectMode(DrawMode.line),
                                tooltip: 'Line',
                              ),
                              _buildToolButton(
                                icon: Icons.crop_square,
                                isSelected: viewModel.selectedMode ==
                                    DrawMode.rectangle,
                                onPressed: () =>
                                    viewModel.selectMode(DrawMode.rectangle),
                                tooltip: 'Rectangle',
                              ),
                              _buildToolButton(
                                icon: Icons.circle_outlined,
                                isSelected:
                                    viewModel.selectedMode == DrawMode.circle,
                                onPressed: () =>
                                    viewModel.selectMode(DrawMode.circle),
                                tooltip: 'Circle',
                              ),
                              _buildToolButton(
                                icon: Icons.format_color_fill,
                                isSelected:
                                    viewModel.selectedMode == DrawMode.fill,
                                onPressed: () =>
                                    viewModel.selectMode(DrawMode.fill),
                                tooltip: 'Fill',
                              ),
                              _buildToolButton(
                                icon: Icons.mode_edit_outline_outlined,
                                isSelected:
                                    viewModel.selectedMode == DrawMode.eraser,
                                onPressed: () =>
                                    viewModel.selectMode(DrawMode.eraser),
                                tooltip: 'Eraser',
                              ),

                              // Small divider
                              SizedBox(width: 4),

                              // Color selector button
                              Builder(
                                builder: (context) => GestureDetector(
                                  onTap: () => DrawingUIHelper.showColorPalette(
                                    context,
                                    _viewModel.selectedColor,
                                    (color) => _viewModel.setColor(color),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: _viewModel.selectedColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 1)
                                      ],
                                    ),
                                  ),
                                  behavior: HitTestBehavior.opaque,
                                ),
                              ),

                              // Brush size selector
                              Builder(
                                builder: (context) => GestureDetector(
                                  onTap: () => DrawingUIHelper.showBrushSizes(
                                    context,
                                    _viewModel.strokeWidth,
                                    _viewModel.selectedColor,
                                    (width) => _viewModel.setStrokeWidth(width),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Icon(Icons.brush,
                                        color: Colors.grey.shade700, size: 18),
                                  ),
                                  behavior: HitTestBehavior.opaque,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Spacer to push edit buttons to right
                        Spacer(),

                        // Editing tools
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.undo, size: 22),
                              onPressed: () => _toolManager.undo(),
                              color: Colors.grey.shade700,
                              padding: EdgeInsets.all(8),
                              constraints:
                                  BoxConstraints(maxWidth: 36, minWidth: 36),
                              tooltip: 'Undo',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 22),
                              onPressed: () => _toolManager.clearCanvas(),
                              color: Colors.grey.shade700,
                              padding: EdgeInsets.all(8),
                              constraints:
                                  BoxConstraints(maxWidth: 36, minWidth: 36),
                              tooltip: 'Clear',
                            ),
                          ],
                        ),
                        SizedBox(width: 4),
                      ],
                    ),
                  ),

                // Observer mode or claim turn buttons
                if (!viewModel.isMyTurn &&
                    viewModel.currentDrawerId != null &&
                    viewModel.currentDrawerId!.isNotEmpty)
                  Container(
                    height: 30,
                    color: Colors.grey[200],
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility,
                            size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          "Observer mode",
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!viewModel.isMyTurn)
                  Center(
                    child: ElevatedButton(
                      onPressed: viewModel.claimDrawingTurn,
                      child: const Text('Claim drawing turn'),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Tool button builder - keep this small UI helper in the widget
  Widget _buildToolButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey.shade700,
            size: 20,
          ),
        ),
      ),
    );
  }
}
