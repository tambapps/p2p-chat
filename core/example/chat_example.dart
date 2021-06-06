import 'dart:convert';
import 'dart:io';

import 'package:p2p_chat_core/p2p_chat_core.dart';

void main() async {
  final socket = await WebSocket.connect('ws://localhost:8000');
  final messageHandler = Chat(socket, (message) => print('Client received message ' + jsonEncode(message)));
  messageHandler.sendText('World');
}
