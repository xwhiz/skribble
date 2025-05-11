import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({Key? key}) : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  late Timestamp loginTimestamp;
  bool isSendingButton = false;

  @override
  void initState() {
    super.initState();
    loginTimestamp = Timestamp.now();
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final String message = messageController.text.trim();
    // Generate a random name if not signed in
    final String userName = FirebaseAuth.instance.currentUser?.displayName ??
        'User-${(DateTime.now().millisecondsSinceEpoch % 10000)}';

    if (message.isNotEmpty) {
      setState(() {
        isSendingButton = true;
      });

      messageController.clear();

      try {
        await _firestore.collection('playerbook').add({
          'name': userName,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Scroll to bottom after sending
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
      } finally {
        setState(() {
          isSendingButton = false;
        });
      }
    }
  }

  Stream<QuerySnapshot> getMessages() {
    return _firestore.collection('playerbook').orderBy('timestamp').snapshots();
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
          child: StreamBuilder<QuerySnapshot>(
            stream: getMessages(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!.docs;
              final filteredMessages = messages.where((msg) {
                final Timestamp messageTimestamp =
                    msg['timestamp'] ?? Timestamp(0, 0);
                return messageTimestamp.compareTo(loginTimestamp) >= 0;
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

              return ListView.builder(
                controller: _scrollController,
                itemCount: filteredMessages.length,
                itemBuilder: (context, index) {
                  final messageData = filteredMessages[index];
                  final String senderName = messageData['name'];
                  final String message = messageData['message'];

                  final Color bgColor =
                      messageColors[index % messageColors.length];

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bgColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: TextStyle(
                              color: Color.fromARGB(255, 32, 42, 53),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            message,
                            style: TextStyle(
                              color: Color.fromARGB(179, 32, 42, 53),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Input area
        Container(
          height: 50, // Fixed height to prevent overflow
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
                  controller: messageController,
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
                    isDense: true, // Makes the field smaller
                  ),
                  style: TextStyle(fontSize: 14), // Smaller text
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, size: 20), // Smaller icon
                onPressed: sendMessage,
                color: Colors.blue,
                padding: EdgeInsets.all(4), // Smaller padding
                constraints: BoxConstraints(
                    minWidth: 36, minHeight: 36), // Smaller constraints
              ),
            ],
          ),
        ),
      ],
    );
  }
}
