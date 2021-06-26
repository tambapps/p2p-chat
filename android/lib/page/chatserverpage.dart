import 'dart:io';

import 'package:flutter/material.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';


class ChatServerPage extends StatefulWidget {

  final ChatServer? chatServer;

  // optional chatServer. If not provided, one will be created in this page
  ChatServerPage({Key? key, this.chatServer}) : super(key: key);

  @override
  _ChatServerPageState createState() => _ChatServerPageState(chatServer);
}

class _ChatServerPageState extends State<ChatServerPage> {

  ChatServer? chatServer;
  InternetAddress? address;
  List<Message> messages = [];

  _ChatServerPageState(this.chatServer);

  @override
  void initState() {
    super.initState();
    if (chatServer == null) {
      startChatServer();
    }
  }

  Future<void> startChatServer() async {
    var address = await getDesktopIpAddress();
    chatServer = await ChatServer.from(address, (message) {
      setState(() {
        this.messages.add(message);
      });
    });

    chatServer!.start();

    setState(() {
      this.address = chatServer!.address;
    });

  }
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    List<Widget> widgets = [];
    if (address != null) {
      widgets.add(Text('Chat started on ${address!.address}', style: Theme.of(context).textTheme.headline4));
    }
    widgets.addAll(messages.map((m) => Text('${m.userData.username}: ${m.text}')));
    return Scaffold(
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: widgets,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}