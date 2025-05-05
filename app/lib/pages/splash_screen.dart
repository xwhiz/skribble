import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:lottie/lottie.dart';
import 'auth_gate.dart'; // import your AuthGate here

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/images/splash_lottie.json'),

            Text(
              'SKRIBBLE',
              style: TextStyle(
                fontSize: 40,
                fontFamily: 'ComicNeue',
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(179, 32, 42, 53),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
