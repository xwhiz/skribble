//import 'package:app/pages/chat_interface.dart';
import 'package:app/pages/splash_screen.dart';
import 'package:app/viewmodels/matchmaking_view_model.dart';
import 'package:provider/provider.dart';
import 'package:app/services/firestore_service.dart';

import 'firebase_options.dart';

//import 'package:app/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'logger.dart'; // import your logger

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

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MatchmakingViewModel(
            FirestoreService(),
          ),
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


