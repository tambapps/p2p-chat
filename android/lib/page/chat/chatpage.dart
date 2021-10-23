import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:p2p_chat_android/model/models.dart';
import 'package:p2p_chat_android/page/chat/message.dart';
import 'package:p2p_chat_android/util/functions.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

import '../../constants.dart';
import 'chat_input_field.dart';

class ChatPage extends StatefulWidget {
  final Context ctx;
  final Conversation conversation;
  final ChatClient chat;
  final List<Message>? messages;
  ChatPage(this.ctx, this.conversation, this.chat, {Key? key, this.messages}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState(chat, ctx, conversation, messages);
}

class _ChatPageState extends AbstractChatPageState<ChatPage> {

  @override
  String get stateLabel => 'client';
  @override
  final ChatClient chat;

  _ChatPageState(this.chat, Context ctx, Conversation conversation, List<Message>? messages) : super(ctx, conversation, messages);

  @override
  void initState() {
    super.initState();
    chat.setMessageCallback(this.onNewMessage);
  }

}

abstract class AbstractChatPageState<T extends StatefulWidget> extends State<T> {


  final Context ctx;
  final Conversation conversation;

  List<Message> messages = [];

  String get stateLabel;

  Chat? get chat;
  UserData myUserData = ANONYMOUS_USER;

  AbstractChatPageState(this.ctx, this.conversation, List<Message>? messages) {
    if (messages != null) {
      this.messages.addAll(messages);
    }
  }

  @override
  void initState() {
    super.initState();
    getUserData().then((userData) => setState(() {
      myUserData = userData;
    }));
    if (messages.isEmpty) {
      // messages may already have been fetched and supplied to this page. If it's not the case, let's fetch them
      ctx.dbHelper.findAndConvertAllMessagesByConversationId(conversation.id).then((messages) => setState(() {
        this.messages.addAll(messages);
      }));
    }
  }
  void onNewMessage(Message message) {
    ctx.dbHelper.insertNewMessage(conversation.id, message.userData, MessageType.TEXT, Uint8List.fromList(message.text.codeUnits), message.sentAt)
        .then((value) => setState(() {
          this.messages.add(message);
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body:  Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  MessageWidget(message: messages[index], userData: myUserData,),
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
                conversation.name ?? "unknown",
              overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16),
              ),
              Text(
                stateLabel,
                style: TextStyle(fontSize: 12),
              )
            ],
          )
        ],
      ),
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
  final List<Message>? messages;
  final Context ctx;
  final Conversation conversation;

  // optional chatServer. If not provided, one will be created in this page
  ChatServerPage(this.ctx, this.conversation, {Key? key, this.chatServer, this.messages}) : super(key: key);

  @override
  _ChatServerPageState createState() => _ChatServerPageState(chatServer, ctx, conversation, messages);
}

class _ChatServerPageState extends AbstractChatPageState<ChatServerPage> {

  ChatServer? chatServer;
  @override
  Chat? get chat => chatServer;

  @override
  String get stateLabel => 'server';

  _ChatServerPageState(this.chatServer, Context ctx, Conversation conversation,
      List<Message>? messages) : super(ctx, conversation, messages);

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