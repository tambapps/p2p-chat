import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

import 'desktop_network_provider.dart';

const SERVER_ARG = 'server';
const ADDRESS_ARG = 'address';
const WITH_ARG = 'with';
const USERNAME_ARG = 'username';

void main(List<String> arguments) async {
  print('P2P Chat 0.0.1');
  var argResults = getArgs(arguments);
  var callback = (Message message) => print('${message.userData.username} at ${formatDate(message.sentAt)}:\n${message.text}');
  final username = argResults[USERNAME_ARG] ?? Platform.localHostname;

  DesktopNetworkProvider networkProvider = DesktopNetworkProvider(argResults[ADDRESS_ARG] != null ? await toAddress(argResults[ADDRESS_ARG]) : null);
  Chat chat;
  if (argResults[SERVER_ARG]) {
    chat = await serverChat(callback, networkProvider, username);
  } else if (argResults[WITH_ARG] != null) {
    chat = await clientChat(callback, await toAddress(argResults[WITH_ARG]), username);
  } else {
    chat = await smartChat(callback, networkProvider, username);
  }

  // dart is single threaded. If I would have processed the lines synchronously (e.g with stdin.readLineSync())
  // it would have block the synchronously thread and gave no room for the server to handle requests
  stdin.transform(utf8.decoder).listen((String text) {
    chat.sendText(text.trim());
  });
}

Future<Chat> clientChat(MessageCallback messageCallback, InternetAddress address, String username) async {
  print('Connecting to ${address.address}');
  var chat = await ChatClient.from(address, messageCallback, userData: userData(username));
  print('Connected successfully');
  print("Tap text and press 'Enter' to send a message");
  return chat;
}

Future<Chat> serverChat(MessageCallback messageCallback, DesktopNetworkProvider networkProvider, String username) async {
  var chatServer = await ChatServer.from(networkProvider, messageCallback, userData: userData(username),
      onNewSocket: (chat, user) {
        print('${user.username} connected!');
        print("Tap text and press 'Enter' to send a message");
        return true;
      }, onConnectionDone: (user) {
    if (user != null) {
      print('${user.username} disconnected');
    }
      }, onConnectionError: (error, user) {
        if (user != null) {
          print('An error occurred with ${user.username}: ${e.toString()}');
        }
      });
  chatServer.start();
  print('Server started on ${chatServer.address.address}.\nWaiting on a connection...');
  var multicaster = await ChatPeerMulticaster.newInstance(await networkProvider.listMulticastNetworkInterfaces());
  multicaster.chatPeers = [ chatServer.chatPeer ];
  multicaster.start();
  return chatServer;
}

Future<Chat> smartChat(MessageCallback messageCallback, DesktopNetworkProvider networkProvider, String username) async {
  print('Looking/waiting for another chat peer');
  var chat = await SmartChat.from(networkProvider, messageCallback, userData: userData(username), onNewSocket: (chat, user) {
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