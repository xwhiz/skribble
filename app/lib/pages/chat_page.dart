import 'package:flutter/material.dart';
import 'package:app/data/dummy_data.dart';


class ChatPage extends StatefulWidget {
  ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  final colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: dummyMessages.length, 
            itemBuilder: (BuildContext context, int index) {
              return Container(
                color: colors[index % colors.length],
                child: Row(
                  children: [
                    Text(dummyMessages[index].user.name , style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),),
                    const SizedBox(width: 10),
                    Text(dummyMessages[index].content , style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),),
                  ],
                ),
              );
            }
          ),
        ),
      ],
    );
  }
}

