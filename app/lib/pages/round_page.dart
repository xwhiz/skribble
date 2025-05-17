import 'dart:ui';
import 'package:flutter/material.dart';

class RoundPage extends StatefulWidget {
  final VoidCallback onFinish;
  const RoundPage({super.key, required this.onFinish});

  @override
  State<RoundPage> createState() => _RoundPageState();
}

class _RoundPageState extends State<RoundPage> {
  @override
  void initState() {
    super.initState();
    // Wait for 2 seconds then call onFinish
    Future.delayed(const Duration(seconds: 2), widget.onFinish);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Black background
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.2), // Frosted glass effect
                borderRadius: BorderRadius.circular(20),
                // ignore: deprecated_member_use
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Text(
                'Round 1',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'ComicNeue',
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black45,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
