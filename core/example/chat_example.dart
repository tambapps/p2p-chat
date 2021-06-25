import 'dart:convert';
import 'dart:io';

import 'package:p2p_chat_core/p2p_chat_core.dart';

void main() async {
  final messageHandler = await ChatClient.from('localhost', (message) => print('Client received message ' + jsonEncode(message)));
  messageHandler.sendText('World');
}
