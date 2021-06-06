import 'dart:io';

import 'package:args/args.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

// TODO add colors (?)
void main(List<String> arguments) async {
  print('P2P Chat 0.0.1');
  print("Tap text and press 'Enter' to send a message");

  var argResults = getArgs(arguments);
  MessageCallback callback = (message) => print('[TODO user] at ${message.sentAt}\n${message.text}');

  Chat chat;
  if (argResults['server']) {
    chat = await serverChat(callback);
  } else {
    var address = argResults['address'];
    if (address == null) {
      print('You should provide the address of the chat server. Exiting.');
      exit(1);
    }
    chat = await clientChat(callback, address);
  }
  var chatting = true;
  while (chatting) {
    var line = stdin.readLineSync();
    if (line != null) {
      chat.sendText(line);
    } else {
      chatting = false;
    }
  }
  print('Chat ended');
}

Future<Chat> clientChat(MessageCallback messageCallback, String address) async {
  return ChatClient.from(address, messageCallback);
}

Future<Chat> serverChat(MessageCallback messageCallback) async {
  // TODO find local network IP
  var chatServer = await ChatServer.from(InternetAddress.loopbackIPv4, messageCallback,
      onNewSocket: (user) {
        print('$user connected!');
        return true;
      });
  chatServer.start();
  print('Server started on ${chatServer.address.address}. Waiting on a connection...');
  return chatServer;
}

ArgResults getArgs(List<String> arguments) {
  final argParser = ArgParser()
  ..addFlag('server', abbr: 's', negatable: false, help: 'Option to tell if you are the chat host (the server peer)')
  ..addOption('address', abbr: 'a', help: 'The address of the chat peer');
  return argParser.parse(arguments);
}