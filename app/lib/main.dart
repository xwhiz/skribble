import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:app/pages/drawing_board_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Add debug output
    print("Initializing Firebase...");

    // Try initializing with options
    await Firebase.initializeApp(
      // You may need Firebase options here if auto-detection fails
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print("Firebase initialized successfully!");
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Continue without Firebase for debugging
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skribbl Clone',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DrawingBoardPage(),
    );
  }
}
