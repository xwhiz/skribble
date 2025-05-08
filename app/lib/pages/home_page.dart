import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app/pages/create_room.dart';
import 'package:app/pages/game_layout.dart';
import 'package:app/pages/join_private_room.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/splash-animation.png',
                              height: 130,
                              fit: BoxFit.contain,
                            ),
                            const Positioned(
                              bottom: 0,
                              child: Text(
                                "SKRIBBLE",
                                style: TextStyle(
                                  fontSize: 18,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'ComicNeue',
                                  color: Colors.black,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                      color: Colors.black45,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildButton(
                                    context,
                                    icon: Icons.public,
                                    text: "Join Public Game",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => const GameLayout(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildButton(
                                    context,
                                    icon: Icons.privacy_tip,
                                    text: "Join Private Game",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => const JoinPrivateRoom(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildButton(
                                    context,
                                    icon: Icons.add,
                                    text: "Create Room",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CreateRoom(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 300,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color.fromARGB(179, 32, 42, 53)),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color.fromARGB(179, 32, 42, 53),
                fontWeight: FontWeight.normal,
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
