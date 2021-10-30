import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'chat.dart';
import 'model.dart';

const NEW_CONNECTION = 0;
const CONNECTED = 1;
const DISCONNECTED = -1;

abstract class ChatAutomaton<T extends Chat> {
  MessageCallback onMessageReceived;
  @protected
  int state;

  ChatAutomaton(this.onMessageReceived, {
    this.state = NEW_CONNECTION
  });

  void act(T chat, Uint8List data) {
    switch (state) {
      case CONNECTED:
        final message = VerifiedMessage.fromJson(jsonDecode(String.fromCharCodes(data)));
        handleReceivedMessage(message);
        break;
      default:
        doAct(chat, data);
    }
  }

  @protected
  void handleReceivedMessage(VerifiedMessage message) {
    onMessageReceived(message);
  }

  void doAct(T chat, Uint8List data) {

  }
}

typedef ChatAutomatonConnectionCallback = bool Function(Chat chat, HandshakeData handshakeData);

class ChatServerAutomaton extends ChatAutomaton<ChatServer> {
  
  final ChatAutomatonConnectionCallback onNewSocket;
  final UserKeyStore _userKeyStore;
  UserData? user;

  ChatServerAutomaton(MessageCallback onMessageReceived, this.onNewSocket, this._userKeyStore)
      : super(onMessageReceived);

  @override
  void doAct(ChatServer chat, Uint8List data) {
    switch (state) {
      case NEW_CONNECTION:
        // we just connected to a chat, we need to
        final handshakeData = HandshakeData.fromJson(jsonDecode(String.fromCharCodes(data)));
        //   add optional key password
        // there should be security checks later, to control who can access a chat or not
        state = onNewSocket(chat, handshakeData) ? CONNECTED : DISCONNECTED;
        if (state == CONNECTED) {
          user = handshakeData.userData;
        }
        break;
    }
  }

  @override
  void handleReceivedMessage(VerifiedMessage message) {
    if (_userKeyStore.verify(message.userData, message.key)) {
      super.handleReceivedMessage(message);
    }
  }

}

class ChatClientAutomaton extends ChatAutomaton<ChatClient> {

  @override
  int state = CONNECTED;

  ChatClientAutomaton(MessageCallback onMessageReceived)
      : super(onMessageReceived);

}