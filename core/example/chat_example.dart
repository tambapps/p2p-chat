import 'dart:convert';
import 'dart:io';

import 'package:p2p_chat_core/p2p_chat_core.dart';

void main() async {
  final socket = await Socket.connect('localhost', 4567);
  final messageHandler = TcpChat(socket, (message) => print('Client received message ' + jsonEncode(message)));
  messageHandler.sendText('World');
}
