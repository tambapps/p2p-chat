import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:p2p_chat_android/model/models.dart';
import 'package:p2p_chat_android/page/chat/chatpage.dart';
import 'package:p2p_chat_android/util/functions.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';


const String FAKE_USER_ID = 'some_fake_id';
class ChatSeekingPage extends StatefulWidget {
  final Context ctx;
  final Conversation conversation;

  ChatSeekingPage(this.ctx, {Key? key, this.conversation = const Conversation(0, 'Looking for a peer', 'some_fake_id')}) : super(key: key);

  @override
  _ChatSeekingPageState createState() => _ChatSeekingPageState(ctx, conversation);
}

class _ChatSeekingPageState extends AbstractChatPageState<ChatSeekingPage> {

  Set<ChatPeer> peers = HashSet();
  @override
  String get stateLabel => 'Waiting for a connection...';
  @override
  SmartChat? chat;

  // will later be optional. Thats why it's nullable
  ChatPeerMulticaster? multicaster;

  _ChatSeekingPageState(Context ctx, Conversation conversation) : super(ctx, conversation);

  @override
  void initState() {
    super.initState();
    startSmartChat();
  }

  void startSmartChat() async {
    this.chat = await SmartChat.from(await getDesktopIpAddress(), (message) {
    }, userData: await getUserData(), onNewSocket: (chat, user) {
      if (conversation.mainUserId != FAKE_USER_ID && user.id != conversation.mainUserId) {
        // if user id was provided, we only want to connect to a specific peer
        return false;
      }
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
    // to avoid super class from closing socket
    this.chat = null;
    super.dispose();
  }
}