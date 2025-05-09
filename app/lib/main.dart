//import 'package:app/pages/chat_interface.dart';
import 'package:app/pages/splash_screen.dart';
import 'package:app/viewmodels/main_view_model.dart';
import 'package:provider/provider.dart';
import 'package:app/services/firestore_service.dart';

import 'firebase_options.dart';

//import 'package:app/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // await setupLogging(); // initialize logging
  // log.info("App started"); // log app start
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // ignore: avoid_print
    print("Firebase initialized successfully");
  } catch (e) {
    // ignore: avoid_print
    print("Error initializing Firebase: $e");
  }

  runApp(const App());
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
