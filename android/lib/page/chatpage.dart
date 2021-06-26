import 'dart:io';

import 'package:flutter/material.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';


class ChatPage extends StatefulWidget {
  final ChatClient chat;
  ChatPage(this.chat, {Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState(chat);
}


class _ChatPageState extends State<ChatPage> {

  final ChatClient chat;

  _ChatPageState(this.chat);

  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    chat.setMessageCallback(this.onNewMessage);
  }

  void onNewMessage(Message message) {
    setState(() {
      this.messages.add(message);
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