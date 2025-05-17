import 'dart:math';
import 'dart:ui';
import 'package:app/models/chat_message_model.dart';
import 'package:app/viewmodels/main_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatWidget extends StatefulWidget {
  final String roomId;

  // ignore: use_super_parameters
  const ChatWidget({Key? key, required this.roomId}) : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Timestamp _loginTimestamp;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loginTimestamp = Timestamp.now();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat messages
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream:
                _firestore.collection('Room').doc(widget.roomId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data == null) {
                return const Center(child: Text('Room not found'));
              }

              final messages = List<dynamic>.from(data['messages'] ?? [])
                  .map((msg) => ChatMessage.fromJson(msg))
                  .toList();

              // Auto-scroll to bottom when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
              return messages.isEmpty
                  ? const Center(child: Text('No messages yet'))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];

                        Color color = Colors.black;
                        if (message.type == "correct") {
                          color = Colors.green;
                        } else if (message.type == "veryClose") {
                          color = Colors.yellow;
                        } else if (message.type == "alreadyGuessed") {
                          color = Colors.orange.withAlpha(100);
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: color,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              padding: EdgeInsets.only(
                                  bottom: 4), // Optional spacing below text
                              child: Text(
                                '${message.username}: ${message.content}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
            },
          ),
        ),

        // Message input
        // Input area
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type guess here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  style: TextStyle(fontSize: 14),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: _isSending
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.send, size: 20),
                onPressed: _isSending ? null : _sendMessage,
                color: Colors.blue,
                padding: EdgeInsets.all(4),
                constraints: BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    final vm = Provider.of<MainViewModel>(context, listen: false);
    final User? currentUser = _auth.currentUser;
    final String message = _messageController.text.trim();

    if (message.isEmpty) return;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final String userName = currentUser.displayName ?? 'Anonymous';
    final word = vm.room!.currentWord!;
    bool correctGuess = message.toLowerCase() == word.toLowerCase();
    int distance = levenshteinDistance(message, word);
    bool alreadyGuessed = vm.room!.guessedCorrectly != null &&
        vm.room!.guessedCorrectly!.contains(currentUser.uid);

    print("Distance: $distance");

    setState(() {
      _isSending = true;
    });
    _messageController.clear();

    try {
      // Get current room document
      DocumentReference roomRef =
          _firestore.collection('Room').doc(widget.roomId);

      // Create message with client-side timestamp (will still be ordered properly)
      final messageData = {
        'userId': currentUser.uid,
        'username': userName,
        'content': message,
        'timestamp': Timestamp.now(),
        'type': "text",
      };

      if (alreadyGuessed) {
        messageData['type'] = "alreadyGuessed";
        await roomRef.update({
          'messages': FieldValue.arrayUnion([messageData])
        });
        return;
      }

      if (correctGuess) {
        final correctData = {
          'userId': currentUser.uid,
          'username': userName,
          'content': "$userName guessed correctly!",
          'timestamp': Timestamp.now(),
          'type': "correct",
        };

        int totolPlayers = vm.room!.players!.length;
        int alreadyGuessedPlayers = vm.room!.guessedCorrectly != null
            ? vm.room!.guessedCorrectly!.length
            : 0;
        var drawingStartedAt = vm.room!.drawingStartAt!;
        var timeElapsed = DateTime.now().difference(drawingStartedAt.toDate());
        int remainingTime = vm.room!.roundDuration! - timeElapsed.inSeconds;

        // I want to find score based on remaining time and number of players remaining
        int score = remainingTime * (totolPlayers - alreadyGuessedPlayers);

        await Future.wait([
          roomRef.update({
            'messages': FieldValue.arrayUnion([correctData])
          }),
          vm.addCorrectGuessAndScore(currentUser.uid, score),
        ]);
      } else if (distance <= 2) {
        final veryCloseData = {
          'userId': currentUser.uid,
          'username': userName,
          'content': "$message is very close!",
          'timestamp': Timestamp.now(),
          'type': "veryClose",
        };
        await roomRef.update({
          'messages': FieldValue.arrayUnion([messageData, veryCloseData])
        });
      } else {
        await roomRef.update({
          'messages': FieldValue.arrayUnion([messageData])
        });
      }

      // Auto-scroll to bottom
      Future.delayed(Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Failed to send message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  int levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < v0.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      List<int> temp = v0;
      v0 = v1;
      v1 = temp;
    }
    return v0[t.length];
  }
}
