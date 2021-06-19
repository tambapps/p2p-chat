import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:p2p_chat_android/page/chatpage.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';


class ChatSeekingPage extends StatefulWidget {
  ChatSeekingPage({Key? key}) : super(key: key);

  @override
  _ChatSeekingPageState createState() => _ChatSeekingPageState();
}

class _ChatSeekingPageState extends State<ChatSeekingPage> {

  Set<ChatPeer> peers = HashSet();

  late ChatPeerListener chatPeerListener;

  // will later be optional. Thats why it's nullable
  ChatPeerMulticaster? multicaster;

  @override
  void initState() {
    super.initState();
    ChatPeerListener.newInstance().then((chatPeerListener) {
      this.chatPeerListener = chatPeerListener;
      chatPeerListener.listen(this._listen);
    });
    // TODO also start server
    ChatPeerMulticaster.newInstance().then((multicaster) async {
      this.multicaster = multicaster;
      multicaster.chatPeers.add(ChatPeer.from(await getDesktopIpAddress(), PeerType.ANY, PEER_DISCOVERY_PORT));
      multicaster.start();
    });
  }

  void _listen(List<ChatPeer> chatPeers) {
    print(chatPeers);
    var peers = HashSet<ChatPeer>();
    peers.addAll(this.peers);
    peers.addAll(chatPeers);
    if (this.peers != peers) {
      setState(() {
        this.peers = peers;
      });
    }
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
    widgets.addAll(peers.map((p) =>
        ElevatedButton(
          child: Text('${p.address}:${p.port}', style: Theme.of(context).textTheme.headline4),
          onPressed: () {
            Navigator.push(context,
                // TODO
                MaterialPageRoute(builder: (context) => ChatPage()));
          },
        )
    ));
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

  @override
  void dispose() {
    chatPeerListener.close();
    this.multicaster?.close();
    super.dispose();
  }
}