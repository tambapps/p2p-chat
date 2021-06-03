// TODO: Put public facing types in this file.

import 'dart:io';

import 'dart:typed_data';

/// Checks if you are awesome. Spoiler: you are.
class MessageHandler {
  final Socket socket;
  MessageHandler(this.socket) {
    socket.listen(_listen);
  }

  void send(Message message) {
    // TODO
  }

  void sendText(String text) {
    socket.write(text);
  }

  void _listen(Uint8List data) {
    final serverResponse = String.fromCharCodes(data);
    print('Server: $serverResponse');
  }
  void destroy() {
    socket.destroy();
  }

}

class Message {

}
abstract class MessageEventListener {

}



