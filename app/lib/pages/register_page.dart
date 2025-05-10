import 'dart:ui';

import 'package:app/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  Future<void> register() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      // After user is created, update the user's display name with the player's name
      User? user = userCredential.user;
      if (user != null) {
        await user.updateProfile(displayName: nameController.text.trim());
        await user.reload();
      }

      // Navigate back to login page after successful registration
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: ${e.message}")),
      );
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
              Color(0xFFCFDEF3), // Light purple/blue
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
                      const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(179, 32, 42, 53),
                          letterSpacing: 1.5,
                          fontFamily: 'ComicNeue', // Font
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: "Enter your name",
                          hintStyle: const TextStyle(
                            color: Color.fromARGB(179, 32, 42, 53),
                            fontSize: 14,
                            fontFamily: 'ComicNeue',
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(179, 32, 42, 53),
                              width: 2,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          color: Color.fromARGB(179, 32, 42, 53),
                          fontFamily: 'ComicNeue',
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: "Email",
                          hintStyle: const TextStyle(
                            color: Color.fromARGB(179, 32, 42, 53),
                            fontSize: 14,
                            fontFamily: 'ComicNeue',
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(179, 32, 42, 53),
                              width: 2,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          color: Color.fromARGB(179, 32, 42, 53),
                          fontFamily: 'ComicNeue',
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: const TextStyle(
                            color: Color.fromARGB(179, 32, 42, 53),
                            fontSize: 14,
                            fontFamily: 'ComicNeue',
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(179, 32, 42, 53),
                              width: 2,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          color: Color.fromARGB(179, 32, 42, 53),
                          fontFamily: 'ComicNeue',
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 400,

                        child: ElevatedButton(
                          onPressed: () async {
                            await register();
                            if (FirebaseAuth.instance.currentUser != null) {
                              // Only navigate if login was successful
                              Navigator.pushReplacement(
                                // ignore: use_build_context_synchronously
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
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
                            "Register",
                            style: TextStyle(
                              fontSize: 24,
                              color: Color.fromARGB(179, 32, 42, 53),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // go back to login
                        },
                        style: ButtonStyle(
                          overlayColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          backgroundColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          shadowColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          splashFactory: NoSplash.splashFactory,
                          padding: WidgetStateProperty.all(EdgeInsets.zero),
                        ),
                        child: const Text(
                          "Already have an account? Sign In",
                          style: TextStyle(
                            color: Color.fromARGB(179, 32, 42, 53),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ComicNeue',
                            decoration: TextDecoration.none,
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
