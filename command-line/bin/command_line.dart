import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

// TODO add colors (?)
void main(List<String> arguments) async {
  print('P2P Chat 0.0.1');

  var argResults = getArgs(arguments);
  var callback = (Message message) => print('[TODO user] at ${message.sentAt}\n${message.text}');

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

  // dart is single threaded. If I would have processed the lines synchronously (e.g with stdin.readLineSync())
  // it would have block the synchronouslyonly thread and gave no room for the server to handle requests
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

Future<Chat> serverChat(MessageCallback messageCallback) async {
  // TODO find local network IP
  var chatServer = await ChatServer.from(InternetAddress.loopbackIPv4, messageCallback,
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