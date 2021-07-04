import 'package:flutter/material.dart';
import 'package:p2p_chat_android/page/chat/message.dart';
import 'package:p2p_chat_android/util/functions.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

import '../../constants.dart';
import 'chat_input_field.dart';

class ChatPage extends StatefulWidget {
  final ChatClient chat;
  ChatPage(this.chat, {Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState(chat);
}

class _ChatPageState extends AbstractChatPageState<ChatPage> {

  @override
  final ChatClient chat;

  _ChatPageState(this.chat);

  @override
  void initState() {
    super.initState();
    chat.setMessageCallback(this.onNewMessage);
  }

}

abstract class AbstractChatPageState<T extends StatefulWidget> extends State<T> {

  List<Message> messages = [];
  Chat? get chat;
  UserData myUserData = ANONYMOUS_USER;

  @override
  void initState() {
    super.initState();
    getUserData().then((userData) => setState(() {
      myUserData = userData;
    }));
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
                    MessageWidget(message: messages[index], userData: myUserData,),
              ),
            ),
          ),
          ChatInputField(onSendClick: this.sendText),
        ],
      ),
    );
  }

  void sendText(String text) {
    if (chat == null) {
      return;
    }
    final message = chat!.sendText(text);
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
                chat is ChatServer ? 'server' : 'client',
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
  @override
  void dispose() {
    chat?.close();
    super.dispose();
  }
}



class ChatServerPage extends StatefulWidget {

  final ChatServer? chatServer;

  // optional chatServer. If not provided, one will be created in this page
  ChatServerPage({Key? key, this.chatServer}) : super(key: key);

  @override
  _ChatServerPageState createState() => _ChatServerPageState(chatServer);
}

class _ChatServerPageState extends AbstractChatPageState<ChatServerPage> {

  ChatServer? chatServer;
  @override
  Chat? get chat => chatServer;

  _ChatServerPageState(this.chatServer);

  @override
  void initState() {
    super.initState();
    if (chatServer == null) {
      startChatServer();
    } else {
      chatServer!.setMessageCallback(this.onNewMessage);
    }
  }

  Future<void> startChatServer() async {
    var address = await getDesktopIpAddress();
    chatServer = await ChatServer.from(address, this.onNewMessage);

    chatServer!.start();
  }
}