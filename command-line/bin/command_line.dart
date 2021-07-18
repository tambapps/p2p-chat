import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

const SERVER_ARG = 'server';
const ADDRESS_ARG = 'address';
const WITH_ARG = 'with';
const USERNAME_ARG = 'username';

void main(List<String> arguments) async {
  print('P2P Chat 0.0.1');
  var argResults = getArgs(arguments);
  var callback = (Message message) => print('${message.userData.username} at ${message.sentAt.hour}:${message.sentAt.second}:\n${message.text}');
  final username = argResults[USERNAME_ARG] ?? Platform.localHostname;

  Chat chat;
  if (argResults[SERVER_ARG]) {
    chat = await serverChat(callback, argResults[ADDRESS_ARG] != null ? await toAddress(argResults[ADDRESS_ARG]) : await getDesktopIpAddress(), username);
  } else if (argResults[WITH_ARG] != null) {
    chat = await clientChat(callback, await toAddress(argResults[WITH_ARG]), username);
  } else {
    chat = await smartChat(callback, argResults[ADDRESS_ARG] != null ? await toAddress(argResults[ADDRESS_ARG]) : await getDesktopIpAddress(), username);
  }

  // dart is single threaded. If I would have processed the lines synchronously (e.g with stdin.readLineSync())
  // it would have block the synchronously thread and gave no room for the server to handle requests
  stdin.transform(utf8.decoder).listen((String text) {
    chat.sendText(text);
  });
}

Future<Chat> clientChat(MessageCallback messageCallback, InternetAddress address, String username) async {
  print('Connecting to ${address.address}');
  var chat = await ChatClient.from(address, messageCallback, userData: userData(username));
  print('Connected successfully');
  print("Tap text and press 'Enter' to send a message");
  return chat;
}

Future<Chat> serverChat(MessageCallback messageCallback, InternetAddress address, String username) async {
  var chatServer = await ChatServer.from(address, messageCallback, userData: userData(username),
      onNewSocket: (chat, user) {
        print('${user.username} connected!');
        print("Tap text and press 'Enter' to send a message");
        return true;
      });
  chatServer.start();
  print('Server started on ${chatServer.address.address}.\nWaiting on a connection...');
  var multicaster = await ChatPeerMulticaster.newInstance();
  multicaster.chatPeers = [ chatServer.chatPeer ];
  multicaster.start();
  return chatServer;
}

Future<Chat> smartChat(MessageCallback messageCallback, InternetAddress address, String username) async {
  print('Looking/waiting for another chat peer');
  var chat = await SmartChat.from(address, messageCallback, userData: userData(username), onNewSocket: (chat, user) {
    if (chat is ChatServer) {
      print('${user.username} connected to your chat!');
    } else {
      print("Connected to ${user.username}'s chat!");
    }
    print("Tap text and press 'Enter' to send a message");
    return true;
  });
  chat.start();
  return chat;
}

UserData userData(String username) {
  return UserData('desktop_' + Platform.localHostname, username);
}

ArgResults getArgs(List<String> arguments) {
  final argParser = ArgParser()
  ..addFlag(SERVER_ARG, abbr: 's', negatable: false, help: 'Option to tell if you are the chat host (the server peer)')
  ..addOption(ADDRESS_ARG, abbr: 'a', help: 'Address to use (for server only)')
  ..addOption(WITH_ARG, abbr: 'w', help: 'Address of the chat host (if you are a client)')
  ..addOption(USERNAME_ARG, abbr: 'u', help: 'Username for the chat');
  return argParser.parse(arguments);
}