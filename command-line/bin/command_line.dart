import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

const SERVER_ARG = 'server';
const ADDRESS_ARG = 'address';
const WITH_ARG = 'with';

late Chat chat;

void main(List<String> arguments) async {
  print('P2P Chat 0.0.1');
  var argResults = getArgs(arguments);
  var callback = (Message message) => print('${message.userData.username} at ${message.sentAt.hour}:${message.sentAt.second}:\n${message.text}');

  if (argResults[SERVER_ARG]) {
    chat = await serverChat(callback, argResults[ADDRESS_ARG] != null ? await toAddress(argResults[ADDRESS_ARG]) : await getDesktopIpAddress());
  } else if (argResults[WITH_ARG] != null) {
    chat = await clientChat(callback, await toAddress(argResults[WITH_ARG]));
  } else {
    chat = await smartChat(callback, argResults[ADDRESS_ARG] != null ? await toAddress(argResults[ADDRESS_ARG]) : await getDesktopIpAddress());
  }

  // dart is single threaded. If I would have processed the lines synchronously (e.g with stdin.readLineSync())
  // it would have block the synchronously thread and gave no room for the server to handle requests
  stdin.transform(utf8.decoder).listen((String text) {
    chat.sendText(text);
  });
}

Future<Chat> clientChat(MessageCallback messageCallback, InternetAddress address) async {
  print('Connecting to $address');
  var chat = await ChatClient.from(address, messageCallback);
  print('Connected successfully');
  print("Tap text and press 'Enter' to send a message");
  return chat;
}

Future<Chat> serverChat(MessageCallback messageCallback, InternetAddress address) async {
  var chatServer = await ChatServer.from(address, messageCallback,
      onNewSocket: (chat, user) {
        print('$user connected!');
        print("Tap text and press 'Enter' to send a message");
        return true;
      });
  chatServer.start();
  print('Server started on ${chatServer.address.address}.\nWaiting on a connection...');
  await multicast(ChatPeer.from(address, PeerType.SERVER, ChatServer.PORT));
  return chatServer;
}

Future<Chat> smartChat(MessageCallback messageCallback, InternetAddress address) async {
  print('Looking/waiting for another chat peer');
  var chat = await SmartChat.from(address, messageCallback, onNewSocket: (chat, user) {
    if (chat is ChatServer) {
      print('$user connected to your chat!');
    } else {
      print("Connected to $user's chat!");
    }
    print("Tap text and press 'Enter' to send a message");
    return true;
  });
  chat.start();
  return chat;
}

Future<ChatPeerMulticaster> multicast(ChatPeer chatPeer) async {
  var multicaster = await ChatPeerMulticaster.newInstance();
  multicaster.chatPeers = [
    chatPeer
  ];
  multicaster.start();
  return multicaster;
}

ArgResults getArgs(List<String> arguments) {
  final argParser = ArgParser()
  ..addFlag(SERVER_ARG, abbr: 's', negatable: false, help: 'Option to tell if you are the chat host (the server peer)')
  ..addOption(ADDRESS_ARG, abbr: 'a', help: 'Address to use (for server only)')
  ..addOption(WITH_ARG, abbr: 'w', help: 'Address of the chat host (if you are a client)');
  return argParser.parse(arguments);
}