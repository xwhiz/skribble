import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatWidget extends StatefulWidget {
  final String roomId;
  final String guestName;

  // ignore: use_super_parameters
  const ChatWidget({Key? key, required this.roomId, required this.guestName})
      : super(key: key);

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

  Future<void> _sendMessage() async {
    final String message = _messageController.text.trim();
    if (message.isEmpty) return;

    final User? currentUser = _auth.currentUser;
    final String userName = currentUser?.displayName?.isNotEmpty == true
        ? currentUser!.displayName!
        : widget.guestName;

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
        'userId': currentUser?.uid ?? 'anonymous',
        'username': userName,
        'content': message,
        'timestamp': Timestamp
            .now(), // Use client timestamp instead of serverTimestamp()
      };

      // Add message to room's messages array
      await roomRef.update({
        'messages': FieldValue.arrayUnion([messageData])
      });

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

  @override
  Widget build(BuildContext context) {
    final List<Color> messageColors = [
      const Color(0xFFFFD3B6),
      const Color(0xFFFFAAA5),
      const Color(0xFFFCB0B3),
      const Color(0xFFAEDFF7),
      const Color(0xFFF7D6E0),
      const Color(0xFFB5EAD7),
    ];

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

              final messages = (data['messages'] as List<dynamic>? ?? [])
                  .map((msg) => _ChatMessage.fromJson(msg))
                  .where((msg) {
                // Only show messages after login
                final messageTimestamp = msg.timestamp ?? Timestamp.now();
                return messageTimestamp.compareTo(_loginTimestamp) >= 0;
              }).toList();

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

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors
                                        .grey, // You can change this color
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.only(
                                  bottom: 4), // Optional spacing below text
                              child: Text(
                                '${message.username}: ${message.content}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color.fromARGB(255, 32, 42, 53),
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
}

// Simple internal chat message class
class _ChatMessage {
  final String userId;
  final String username;
  final String content;
  final Timestamp? timestamp;

  _ChatMessage({
    required this.userId,
    required this.username,
    required this.content,
    this.timestamp,
  });

  factory _ChatMessage.fromJson(Map<String, dynamic> json) {
    return _ChatMessage(
      userId: json['userId'] as String? ?? 'anonymous',
      username: json['username'] as String? ?? 'Anonymous',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] as Timestamp?,
    );
  }
}
