// components/chat_component.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/models/message_model.dart';
import 'package:app/components/chat_bubble_component.dart';
import 'package:app/viewmodels/chat_viewmodel.dart';

class ChatComponent extends StatelessWidget {
  const ChatComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(),
      child: _ChatComponentContent(),
    );
  }
}

class _ChatComponentContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ChatViewModel>(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Chat messages
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: viewModel.chatStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data!;
                
                return ListView.builder(
                  controller: viewModel.scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.userId == viewModel.currentUserId;
                    
                    return ChatBubble(
                      message: message, 
                      isCurrentUser: isCurrentUser,
                    );
                  },
                );
              },
            ),
          ),
          
          // Chat input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: viewModel.messageController,
                    decoration: const InputDecoration(
                      hintText: "Type your guess here...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    onSubmitted: (_) => viewModel.sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: viewModel.sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}