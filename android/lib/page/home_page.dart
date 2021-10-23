

import 'package:flutter/material.dart';
import 'package:p2p_chat_android/model/models.dart';

import '../constants.dart';
import 'chat_seeking_page.dart';
import 'settings_page.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title, required this.context}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final Context context;

  @override
  _MyHomePageState createState() => _MyHomePageState(context);
}

class _MyHomePageState extends State<MyHomePage> {

  final Context ctx;
  List<Conversation> conversations = [];

  _MyHomePageState(this.ctx);

  @override
  void initState() {
    ctx.dbHelper.findAllConversations().then((value) => setState(() {
      this.conversations = value;
    }));
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
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
            children: <Widget>[
              ElevatedButton(
                child: Text('Search chat', style: Theme
                    .of(context)
                    .textTheme
                    .headline4),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (context) => ChatSeekingPage(ctx)));
                },
              ),
            ],
          ),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                width: kDefaultPadding / 2,
              ),
              SizedBox(width: kDefaultPadding * 0.75),
              Expanded(child: Text(
                "Pchat",
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              )
              )
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: this.goToSettingsPage,
            ),
            SizedBox(width: kDefaultPadding / 2),
          ],
        ),
        body: Stack(
          children: [
            ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(
                            builder: (context) => ChatSeekingPage(ctx, conversation: conversation)));
                  },
                  onLongPress: () => deleteDialog(context, conversation),
                  child: ListTile(
                    title: Text(conversation.name ?? ""),
                  ),
                );
              },
            ),
            Align(child: Padding(
              child: FloatingActionButton(onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (context) => ChatSeekingPage(ctx)));
              },
                child: const Icon(Icons.add),),
              padding: EdgeInsets.only(right: 16, bottom: 16),
            ),
              alignment: Alignment.bottomRight,
            )
          ],
        ), // This trailing comma makes auto-formatting nicer for build methods.
      );
    }
  }

  void deleteDialog(BuildContext context, Conversation conversation) {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text('Delete this conversation?'),
        content: Text('You will no longer be able to retrieve it if you do so'),
        actions: [
          TextButton(
            onPressed: () {
              ctx.dbHelper.deleteConversation(conversation.id).then((value) => setState(() {
                conversations.remove(conversation);
              }));
              Navigator.pop(context);
            },
            child: Text('YES', style: TextStyle(color: Colors.red),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    });
  }

  void goToSettingsPage() {
    Navigator.push(context,
        MaterialPageRoute(
            builder: (context) => SettingsPage(ctx: ctx)));
  }
}