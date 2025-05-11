import 'package:app/pages/splash_screen.dart';
import 'package:app/viewmodels/main_view_model.dart';
import 'package:provider/provider.dart';
import 'package:app/services/firestore_service.dart';

import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print("Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully!");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  runApp(MyApp());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MainViewModel(FirestoreService()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
          useMaterial3: true,
        ),
        home: SplashScreen(),
      ),
    );
  }
}
