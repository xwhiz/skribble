// test/widgets/drawing_board_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:app/widgets/drawing_board_widget.dart';
import 'package:app/viewmodels/drawing_view_model.dart';
import 'package:app/models/enums/draw_mode.dart';

// Create mock class using mocktail (simpler than mockito)
class MockDrawingViewModel extends Mock implements DrawingViewModel {}

void main() {
  late MockDrawingViewModel mockViewModel;

  setUp(() {
    mockViewModel = MockDrawingViewModel();

    // Setup default mock behavior
    when(() => mockViewModel.elements).thenReturn([]);
    when(() => mockViewModel.selectedColor).thenReturn(Colors.black);
    when(() => mockViewModel.strokeWidth).thenReturn(3.0);
    when(() => mockViewModel.selectedMode).thenReturn(DrawMode.pencil);
  });

  Widget createTestableWidget() {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<DrawingViewModel>.value(
          value: mockViewModel,
          child: const DrawingBoardWidget(roomId: 'test-room'),
        ),
      ),
    );
  }

  // TEST 1: Drawing board shows canvas when it's user's turn
  testWidgets('shows drawing canvas and tools when it is user\'s turn',
      (WidgetTester tester) async {
    // ARRANGE
    when(() => mockViewModel.isMyTurn).thenReturn(true);
    when(() => mockViewModel.currentDrawerId).thenReturn('test-user-id');

    // ACT
    await tester.pumpWidget(createTestableWidget());

    // ASSERT
    // Use findsWidgets instead of findsOneWidget for CustomPaint
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byIcon(Icons.edit), findsOneWidget); // Pencil tool
    expect(find.byIcon(Icons.crop_square), findsOneWidget); // Rectangle tool
    expect(find.byIcon(Icons.undo), findsOneWidget); // Undo button
  });

  // TEST 2: Shows claim button when no active drawer
  testWidgets(
      'shows claim drawing turn button when not user\'s turn and no active drawer',
      (WidgetTester tester) async {
    // ARRANGE
    when(() => mockViewModel.isMyTurn).thenReturn(false);
    when(() => mockViewModel.currentDrawerId).thenReturn(null);

    // ACT
    await tester.pumpWidget(createTestableWidget());

    // ASSERT
    expect(find.text('Claim drawing turn'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  // TEST 3: Shows observer mode when another user is drawing
  testWidgets('shows observer mode when another user is drawing',
      (WidgetTester tester) async {
    // ARRANGE
    when(() => mockViewModel.isMyTurn).thenReturn(false);
    when(() => mockViewModel.currentDrawerId).thenReturn('another-user-id');

    // ACT
    await tester.pumpWidget(createTestableWidget());

    // ASSERT
    expect(find.text('Observer mode'), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });

  // TEST 4: Tool selection changes drawing mode
  testWidgets('selecting a tool changes the drawing mode',
      (WidgetTester tester) async {
    // ARRANGE
    when(() => mockViewModel.isMyTurn).thenReturn(true);
    when(() => mockViewModel.currentDrawerId).thenReturn('test-user-id');

    // ACT
    await tester.pumpWidget(createTestableWidget());
    await tester.tap(find.byIcon(Icons.circle_outlined)); // Tap circle tool
    await tester.pump();

    // ASSERT
    verify(() => mockViewModel.selectMode(DrawMode.circle)).called(1);
  });

  // TEST 5: Clear canvas functionality
  testWidgets('clear button triggers canvas clearing',
      (WidgetTester tester) async {
    // ARRANGE
    when(() => mockViewModel.isMyTurn).thenReturn(true);
    when(() => mockViewModel.currentDrawerId).thenReturn('test-user-id');

    // Mock the clearCanvas method since that's what your DrawingToolManager calls
    when(() => mockViewModel.clearCanvas()).thenAnswer((_) async {});
    when(() => mockViewModel.syncDrawingToFirebase()).thenAnswer((_) async {});

    // ACT
    await tester.pumpWidget(createTestableWidget());
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    // ASSERT - Verify the correct method was called
    verify(() => mockViewModel.clearCanvas()).called(1);
  });
}
