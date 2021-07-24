import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:p2p_chat_android/model/models.dart';
import 'package:p2p_chat_android/page/chat/chatpage.dart';
import 'package:p2p_chat_android/util/functions.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';


class ChatSeekingPage extends StatefulWidget {
  final Context ctx;

  ChatSeekingPage(this.ctx, {Key? key}) : super(key: key);

  @override
  _ChatSeekingPageState createState() => _ChatSeekingPageState(ctx);
}

class _ChatSeekingPageState extends AbstractChatPageState<ChatSeekingPage> {

  Set<ChatPeer> peers = HashSet();
  @override
  String get stateLabel => 'Waiting for a peer to connect...';
  @override
  SmartChat? chat;


  // will later be optional. Thats why it's nullable
  ChatPeerMulticaster? multicaster;

  _ChatSeekingPageState(Context ctx) : super(ctx, Conversation(0, 'Fake conversation', 'no user'));

  @override
  void initState() {
    super.initState();
    startSmartChat();
  }

  void startSmartChat() async {
    this.chat = await SmartChat.from(await getDesktopIpAddress(), (message) {
    }, userData: await getUserData(), onNewSocket: (chat, user) {
      ctx.dbHelper.insertNewConversation(user.username, user.id).then((conversation) {
        if (chat is ChatServer) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => ChatServerPage(ctx, conversation, chatServer: chat)));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => ChatPage(ctx, conversation, chat as ChatClient,)));
        }
      });
      return true;
    });
    chat!.start();
  }

  @override
  void onNewMessage(Message message) {
    // this screen isn't supposed to receive message since the chat isn't conected
    // to anyone yet
  }

  @override
  void dispose() {
    this.multicaster?.close();
    super.dispose();
  }
}