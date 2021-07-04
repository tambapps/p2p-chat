import 'package:flutter/material.dart';
import 'package:p2p_chat_android/page/chat/message.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

import '../../constants.dart';
import 'chat_input_field.dart';

class ChatPage extends StatefulWidget {
  final ChatClient chat;
  ChatPage(this.chat, {Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState(chat);
}


class _ChatPageState extends State<ChatPage> {

  final ChatClient chat;

  _ChatPageState(this.chat);

  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    chat.setMessageCallback(this.onNewMessage);
  }

  void onNewMessage(Message message) {
    setState(() {
      this.messages.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body:  Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) =>
                    MessageWidget(message: messages[index], userData: UserData('Android smartphone'),),
              ),
            ),
          ),
          ChatInputField(onSendClick: this.sendText),
        ],
      ),
    );
  }

  void sendText(String text) {
    final message = chat.sendText(text);
    onNewMessage(message);
  }
  AppBar buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          BackButton(),
          SizedBox(width: kDefaultPadding * 0.75),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Kristin Watson",
                style: TextStyle(fontSize: 16),
              ),
              Text(
                "Active 3m ago",
                style: TextStyle(fontSize: 12),
              )
            ],
          )
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.local_phone),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.videocam),
          onPressed: () {},
        ),
        SizedBox(width: kDefaultPadding / 2),
      ],
    );
  }
}