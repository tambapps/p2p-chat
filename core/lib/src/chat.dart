// TODO: Put public facing types in this file.

import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'model.dart';

/// base class for a chat
abstract class Chat {

  /// Sends the [text] message to the other peer
  void sendText(String text) {
    sendMessage(Message(text, DateTime.now()));
  }

  /// Sends the [message] to the other peer
  void sendMessage(Message message);

}

typedef MessageCallback = void Function(Message message);

class TcpChat extends Chat {
  final Socket socket;
  final MessageCallback onMessageReceived;

  TcpChat(this.socket, this.onMessageReceived, {Function? onError}) {
    socket.listen(_listen, onError: onError);
  }

  @override
  void sendMessage(Message message) {
    socket.write(jsonEncode(message));
  }

  void _listen(Uint8List data) {
    final message = Message.fromJson(jsonDecode(String.fromCharCodes(data)));
    onMessageReceived.call(message);
  }

  void destroy() {
    socket.destroy();
  }

}




