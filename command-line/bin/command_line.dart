import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

void main(List<String> arguments) async {
  print('P2P Chat 0.0.1');
  var argResults = getArgs(arguments);
  var callback = (Message message) => print('${message.userData.username} at ${message.sentAt.hour}:${message.sentAt.second}:\n${message.text}');
  String? address = argResults['address'];

  Chat chat;
  if (argResults['server']) {
    chat = await serverChat(callback, address ?? await getDesktopIpAddress());
  } else {
    if (address == null) {
      print('You should provide the address of the chat server. Exiting.');
      exit(1);
    }
    chat = await clientChat(callback, address);
  }

  // dart is single threaded. If I would have processed the lines synchronously (e.g with stdin.readLineSync())
  // it would have block the synchronously thread and gave no room for the server to handle requests
  stdin.transform(utf8.decoder).listen((String text) {
    chat.sendText(text);
  });
}

Future<Chat> clientChat(MessageCallback messageCallback, String address) async {
  print('Connecting to $address');
  var chat = await ChatClient.from(address, messageCallback);
  print('Connected successfully');
  print("Tap text and press 'Enter' to send a message");
  return chat;
}

Future<Chat> serverChat(MessageCallback messageCallback, address) async {
  var chatServer = await ChatServer.from(address, messageCallback,
      onNewSocket: (user) {
        print('$user connected!');
        print("Tap text and press 'Enter' to send a message");
        return true;
      });
  chatServer.start();
  print('Server started on ${chatServer.address.address}.\nWaiting on a connection...');
  return chatServer;
}

ArgResults getArgs(List<String> arguments) {
  final argParser = ArgParser()
  ..addFlag('server', abbr: 's', negatable: false, help: 'Option to tell if you are the chat host (the server peer)')
  ..addOption('address', abbr: 'a', help: 'The address of the chat peer');
  return argParser.parse(arguments);
}