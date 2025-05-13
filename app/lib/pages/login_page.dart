import 'dart:ui';

//import 'package:app/pages/game_screen.dart';
import 'package:app/pages/guest_login.dart';
import 'package:app/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'register_page.dart';
import 'package:flutter/gestures.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String? playerName;
  Future<void> login() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Get the logged-in user's name (displayName)
      User? user = userCredential.user;
      if (user != null) {
        setState(() {
          playerName = user.displayName;
        });
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: ${e.message}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0EAFC), // Soft blue
              Color(0xFFCFDEF3), // Very light purple/blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    // ignore: deprecated_member_use
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Welcome Back!",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(179, 32, 42, 53),
                          letterSpacing: 1.5,
                          fontFamily: 'ComicNeue', // Applying Comic Neue font
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 400,
                        child: TextField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            hintText: "Email",
                            hintStyle: TextStyle(
                              color: const Color.fromARGB(179, 32, 42, 53),
                              fontSize: 14,
                              fontFamily: 'ComicNeue',
                              // Applying Comic Neue font
                            ),
                            filled: true,
                            // ignore: deprecated_member_use
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: const Color.fromARGB(179, 32, 42, 53),
                                width: 2,
                              ), // Highlight effect
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 20,
                            ),
                          ),
                          style: TextStyle(
                            color: Color.fromARGB(179, 32, 42, 53),
                            fontFamily: 'ComicNeue',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 400,
                        child: TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: TextStyle(
                              color: const Color.fromARGB(179, 32, 42, 53),
                              fontSize: 14,
                              fontFamily:
                                  'ComicNeue', // Applying Comic Neue font
                            ),
                            filled: true,
                            // ignore: deprecated_member_use
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: const Color.fromARGB(179, 32, 42, 53),
                                width: 2,
                              ), // Highlight effect
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 20,
                            ),
                          ),
                          style: TextStyle(
                            color: Color.fromARGB(179, 32, 42, 53),
                            fontFamily: 'ComicNeue',
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 400,
                        child: ElevatedButton(
                          onPressed: () async {
                            await login();
                            if (FirebaseAuth.instance.currentUser != null) {
                              Navigator.pushReplacement(
                                // ignore: use_build_context_synchronously
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomePage(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            // ignore: deprecated_member_use
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 24,
                              color: Color.fromARGB(179, 32, 42, 53),
                              fontWeight: FontWeight.bold,
                              fontFamily:
                                  'ComicNeue', // Applying Comic Neue font
                            ),
                          ),
                        ),
                      ),
                      if (playerName != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Welcome, $playerName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'ComicNeue', // Applying Comic Neue font
                          ),
                        ),
                      ],
                      const SizedBox(height: 23),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Color.fromARGB(179, 32, 42, 53),
                            fontSize: 18,
                            fontFamily: 'ComicNeue',
                          ),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Register',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => RegisterPage()),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10), // Add some space between
                      SizedBox(
                        width: 400,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GuestLogin(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            // ignore: deprecated_member_use
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Play As Guest",
                            style: TextStyle(
                              fontSize: 24,
                              color: Color.fromARGB(179, 32, 42, 53),
                              fontWeight: FontWeight.bold,
                              fontFamily:
                                  'ComicNeue', // Applying Comic Neue font
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
