import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:p2p_chat_android/android_network_provider.dart';
import 'package:p2p_chat_android/model/models.dart';
import 'package:p2p_chat_android/page/chat_page.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

import '../constants.dart';

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
  final MulticastLock _lock = Platform.isAndroid ? AndroidMulticastLock() : NoOpMulticastLock();
  final AndroidNetworkProvider networkProvider = AndroidNetworkProvider();

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
    await _lock.acquire();
    SmartChat chat = await SmartChat.from(networkProvider, (message) {
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
    _lock.release();
    super.dispose();
  }
}

abstract class MulticastLock {

  Future<void> acquire();

  Future<void> release();
}

class NoOpMulticastLock extends MulticastLock {
  @override
  Future<void> acquire() async {
  }

  @override
  Future<void> release() async {
  }

}

class AndroidMulticastLock extends MulticastLock {

  @override
  Future<void> acquire() async {
    await androidMethodChannel.invokeMethod("acquireMulticastLock");
  }

  @override
  Future<void> release() async {
    await androidMethodChannel.invokeMethod("releaseMulticastLock");
  }
}

