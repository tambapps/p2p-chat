import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:p2p_chat_android/model/models.dart';
import 'package:p2p_chat_android/page/chat_page.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

const FAKE_CONVERSATION = const Conversation(0, 'Looking for a peer', 'some_fake_id');

class ChatSeekingPage extends StatefulWidget {
  final Context ctx;
  final Conversation conversation;
  final bool? seeking;

  ChatSeekingPage(this.ctx, {Key? key, this.conversation = FAKE_CONVERSATION, this.seeking}) : super(key: key);

  @override
  _ChatSeekingPageState createState() => _ChatSeekingPageState(ctx, conversation, seeking);
}

class _ChatSeekingPageState extends AbstractChatPageState<ChatSeekingPage> {

  Set<ChatPeer> peers = HashSet();
  @override
  String get stateLabel => online ? 'Waiting for a connection...' : 'offline';
  @override
  SmartChat? chat;
  // variable to know if we must dispose chat or not
  // we want to keep it when we pass it to another ChatPage, and dispose it otherwise
  bool keepChat = false;

  // will later be optional. Thats why it's nullable
  ChatPeerMulticaster? multicaster;

  _ChatSeekingPageState(Context ctx, Conversation conversation, bool? online) : super(ctx, conversation, null) {
    this.online = online ?? false;
  }

  @override
  void initState() {
    super.initState();
    if (online) {
      startSmartChat();
    }
  }
  void startSmartChat() async {
    SmartChat chat = await SmartChat.from(await getDesktopIpAddress(), (message) {
    }, userData: ctx.userData, onNewSocket: (chat, user) {
      if (conversation != FAKE_CONVERSATION && user.id != conversation.mainUserId) {
        // if conversation id was provided, we only want to connect to a specific peer
        return false;
      }
      getConversation(user).then((conversation) {
        if (!mounted) return;
        this.keepChat = true;
        if (chat is ChatServer) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => ChatServerPage(ctx, conversation, chatServer: chat, messages: this.messages,)));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => ChatPage(ctx, conversation, chat as ChatClient, messages: this.messages)));
        }
      });
      return true;
    }, onServerError: onServerError, onServerDone: onServerDone);
    chat.start();
    setState(() {
      this.chat = chat;
      online = true;
    });
  }

  void onServerError(e) {
    if (!mounted) return;
    Fluttertoast.showToast(
        msg: "An error occurred ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT
    );
    onServerDone();
  }

  void onServerDone() {
    if (!mounted) return;
    setState(() {
      online = false;
    });
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
  void goOnline() {
    startSmartChat();
  }

  @override
  void dispose() {
    this.multicaster?.close();
    if (keepChat) {
      // to avoid super class from closing socket
      this.chat = null;
    }
    super.dispose();
  }
}