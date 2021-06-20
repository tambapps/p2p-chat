import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'chat.dart';
import 'model.dart';

const NEW_CONNECTION = 0;
const CONNECTED = 1;

abstract class _ChatAutomaton<T extends Chat> {
  final MessageCallback _onMessageReceived;
  @protected
  int state = NEW_CONNECTION;

  _ChatAutomaton(this._onMessageReceived);

  void act(T chat, Uint8List data) {
    switch (state) {
      case CONNECTED:
        _onMessageReceived(Message.fromJson(jsonDecode(String.fromCharCodes(data))));
        break;
      default:
        doAct(chat, data);
    }
  }

  void doAct(T chat, Uint8List data) {

  }
}

class ChatServerAutomaton extends _ChatAutomaton<ChatServer> {
  
  final ConnectionCallback onNewSocket;

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
        onNewSocket(chat, handshakeData);
        state = CONNECTED;
        break;
    }
  }

}

class ChatClientAutomaton extends _ChatAutomaton<ChatClient> {

  @override
  int state = CONNECTED;

  ChatClientAutomaton(MessageCallback onMessageReceived) : super(onMessageReceived);



}