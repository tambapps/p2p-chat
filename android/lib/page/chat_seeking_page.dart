import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:p2p_chat_android/model/models.dart';
import 'package:p2p_chat_android/page/chat_page.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

const FAKE_CONVERSATION = const Conversation(0, 'Looking for a peer', 'some_fake_id');

// TODO remove behaviour that finds an existing conversation when possible
class ChatSeekingPage extends StatefulWidget {
  final Context ctx;
  final Conversation conversation;

  ChatSeekingPage(this.ctx, {Key? key, this.conversation = FAKE_CONVERSATION}) : super(key: key);

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

  _ChatSeekingPageState(Context ctx, Conversation conversation) : super(ctx, conversation, null);

  @override
  void initState() {
    super.initState();
    startSmartChat();
  }

  void startSmartChat() async {
    this.chat = await SmartChat.from(await getDesktopIpAddress(), (message) {
    }, userData: ctx.userData, onNewSocket: (chat, user) {
      if (conversation != FAKE_CONVERSATION && user.id != conversation.mainUserId) {
        // if conversation id was provided, we only want to connect to a specific peer
        return false;
      }
      getConversation(user).then((conversation) {
        if (chat is ChatServer) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => ChatServerPage(ctx, conversation, chatServer: chat, messages: this.messages,)));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => ChatPage(ctx, conversation, chat as ChatClient, messages: this.messages)));
        }
      });
      return true;
    });
    chat!.start();
  }

  /// return the provided conversation or create a new one
  Future<Conversation> getConversation(UserData user) async {
    if (conversation != FAKE_CONVERSATION) {
      return conversation;
    } else {
      return await ctx.dbHelper.insertNewConversation(user.username, user.id);
    }
  }

  @override
  void onNewMessage(Message message) {
    // this screen isn't supposed to receive message since the chat isn't conected
    // to anyone yet
  }

  @override
  bool canSendMessages() {
    return false;
  }

  @override
  void dispose() {
    this.multicaster?.close();
    // to avoid super class from closing socket
    this.chat = null;
    super.dispose();
  }
}