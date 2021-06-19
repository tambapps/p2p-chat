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
    chat = await serverChat(callback, argResults[ADDRESS_ARG] ?? await getDesktopIpAddress());
  } else if (argResults[WITH_ARG] != null) {
    chat = await clientChat(callback, argResults[WITH_ARG]);
  } else {
    chat = await smartChat(callback, argResults[ADDRESS_ARG] ?? await getDesktopIpAddress());;
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
Future<Chat> smartChat(MessageCallback messageCallback, address) async {
  // this part is a little tricky
  // I want this method to be blocking until a chat is found, whether it is from
  // the server or from a discovered chat peer
  // I first wanted to use a Stream<Chat> and then wait for the first element but
  // we can't yield a value from callbacks. So instead I used a periodic stream
  // that will check each seconds if a chat has been started, from the chatRef
  // server
  final chatRef = <Chat?>[null];
  var chatServer = await ChatServer.from(address, messageCallback,
      onNewSocket: (chat, user) {
        print('$user connected!');
        print("Tap text and press 'Enter' to send a message");
        chatRef[0] = chat;
        return true;
  });

  chatServer.start();
  var multicaster = await multicast(ChatPeer.from(address, PeerType.SERVER, ChatServer.PORT));
  // client listening for other servers

  var chatPeerListener = await ChatPeerListener.newInstance();
  chatPeerListener.listen((chatPeers) async {
    var chat = await ChatClient.from(address, messageCallback);
    chatRef[0] = chat;
    print('Connected successfully');
    print("Tap text and press 'Enter' to send a message");
  });

  return Stream.periodic(Duration(seconds: 1), (computationCount) => chatRef[0])
      .where((nullableChat) => nullableChat != null)
      .map((chat) {
        if (chat != chatServer) {
          chatServer.close();
        }
        multicaster.close();
        chatPeerListener.close();
        return chat as Chat;
      })
      .first;
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