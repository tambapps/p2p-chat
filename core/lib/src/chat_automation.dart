import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'chat.dart';
import 'model.dart';

const NEW_CONNECTION = 0;
const CONNECTED = 1;

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
        // TODO verify key is for username
        onMessageReceived(message);
        break;
      default:
        doAct(chat, data);
    }
  }

  void doAct(T chat, Uint8List data) {

  }
}

class ChatServerAutomaton extends ChatAutomaton<ChatServer> {
  
  final ChatConnectionCallback onNewSocket;

  ChatServerAutomaton(MessageCallback onMessageReceived, this.onNewSocket) : super(onMessageReceived);

  @override
  void doAct(ChatServer chat, Uint8List data) {
    switch (state) {
      case NEW_CONNECTION:
        // we just connected to a chat, we need to
        final handshakeData = HandshakeData.fromJson(jsonDecode(String.fromCharCodes(data)));
        // TODO do handshake and stuff
        //   add optional key password
        // there should be security checks later, to control who can access a chat or not
        onNewSocket(chat, handshakeData.userData);
        state = CONNECTED;
        break;
    }
  }

}

class ChatClientAutomaton extends ChatAutomaton<ChatClient> {

  @override
  int state = CONNECTED;

  ChatClientAutomaton(MessageCallback onMessageReceived) : super(onMessageReceived);



}