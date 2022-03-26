import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:p2p_chat_android/model/models.dart';
import 'package:p2p_chat_android/widgets/message.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

import '../android_network_provider.dart';
import '../widgets/text_input_field.dart';

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
  String get stateLabel => online ? 'client' : 'offline';
  @override
  ChatClient chat;

  _ChatPageState(this.chat, Context ctx, Conversation conversation, List<Message>? messages) : super(ctx, conversation, messages) {
    online = true;
    chat.onError = onError;
    chat.onDone = onDone;
  }

  @override
  void initState() {
    super.initState();
    chat.setMessageCallback(this.onNewMessage);
  }

  @override
  void goOnline() async {
    chat.close();
    chat = await ChatClient.from(chat.address, onNewMessage, onError: chat.onError, onDone: chat.onDone, userData: chat.userData);
  }

  void onError(e) {
    Fluttertoast.showToast(
        msg: "An error occurred: " + e.toString(),
        toastLength: Toast.LENGTH_SHORT
    );
    setState(() {
      online = false;
    });
  }

  void onDone() {
    Fluttertoast.showToast(
        msg: "Chat ended",
        toastLength: Toast.LENGTH_SHORT
    );
    if (mounted) {
      setState(() {
        online = false;
      });
    }
  }
}

abstract class AbstractChatPageState<T extends StatefulWidget> extends State<T> {


  final Context ctx;
  final Conversation conversation;

  List<Message> messages = [];
  Map<Message, int> messageIdMap = HashMap();

  String get stateLabel;

  Chat? get chat;
  // online = seeking or connected
  bool online = false;
  ScrollController _scrollController = ScrollController();
  bool shouldScrollDown = false;

  AbstractChatPageState(this.ctx, this.conversation, List<Message>? messages) {
    if (messages != null) {
      this.messages.addAll(messages);
    }
  }

  @override
  void initState() {
    super.initState();
    if (messages.isEmpty) {
      // messages may already have been fetched and supplied to this page. If it's not the case, let's fetch them
      fetchMessages(conversation.id);
    }
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        shouldScrollDown = true;
      });
    });
  }

  void fetchMessages(int conversationId) async {
    List<DatabaseMessage> dbMessages = await ctx.dbHelper.findAllMessagesByConversationId(conversationId);
    final messageIdMap = await ctx.dbHelper.convertMessages(dbMessages);
    setState(() {
      this.messageIdMap.addAll(messageIdMap);
      this.messages.addAll(messageIdMap.keys);
    });
  }

  void onNewMessage(Message message) {
    ctx.dbHelper.insertNewMessage(conversation.id, message.userData, MessageType.TEXT, Uint8List.fromList(message.text.codeUnits), message.sentAt)
        .then((value) => setState(() {
          this.messages.add(message);
          shouldScrollDown = true;
        }));
  }

  @override
  Widget build(BuildContext context) {
    if (shouldScrollDown) {
      Future.delayed(const Duration(milliseconds: 100), scrollDown);
      shouldScrollDown = false;
    }
    return Scaffold(
      appBar: buildAppBar(),
      body:  Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  MessageWidget(message: messages[index], userData: ctx.userData, previousMessage: index > 0 ? messages[index - 1] : null, deleteCallback: this.deleteMessage,),
            ),
          ),
          if (canSendMessages()) ConversationTextInputField(onSendClick: this.sendText),
        ],
      ),
    );
  }

  void deleteMessage(Message message) {
    final int? messageId = messageIdMap[message];
    if (messageId == null) {
      return;
    }
    ctx.dbHelper.deleteMessage(messageId).then((value) => setState(() {
      messages.remove(message);
      messageIdMap.remove(message);
    }));
  }

  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.fastOutSlowIn,);
  }

  bool canSendMessages() {
    return true;
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
      centerTitle: true,
      actions: buildActions(),
      leading: BackButton(),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
      ),
    );
  }

  List<Widget>? buildActions() {
    const double size = 20;
    return !online ? [
      IconButton(onPressed: () {
        goOnline();
        setState(() {
          online = true;
        });
      },
          icon: Image(image: AssetImage('assets/link.png'), width: size, height: size,))
    ] : null;
  }

  void goOnline();

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
  String get stateLabel => online ? 'server' : 'offline';

  _ChatServerPageState(this.chatServer, Context ctx, Conversation conversation,
      List<Message>? messages) : super(ctx, conversation, messages) {
    online = true;
    chatServer?..onServerError = onServerError
    ..onServerDone = onServerDone
    ..onConnectionError = onConnectionError
    ..onConnectionDone = onConnectionDone;
  }


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
    chatServer = await ChatServer.from(AndroidNetworkProvider(), this.onNewMessage);

    chatServer!.start();
  }

  @override
  void goOnline() {
    chatServer?.close();
    startChatServer();
  }

  void onServerError(e) {
    setState(() {
      online = false;
    });
  }

  void onServerDone() {
    if (mounted) {
      setState(() {
        online = false;
      });
    }
  }

  void onConnectionError(e, UserData? user) {
    if (chatServer == null) {
      return;
    }
    String message = user != null ? 'An error occured with ${user.username}: ' + e.toString()
        : "An error occurred: " + e.toString();
    Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT);
  }

  void onConnectionDone(UserData? user) {
    if (chatServer == null) {
      return;
    }
    String message = user != null ? "${user.username} disconnected from chat" : "An user disconnected from chat";
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT
    );
  }
}