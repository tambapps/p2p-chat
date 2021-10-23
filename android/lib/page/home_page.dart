

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:p2p_chat_android/model/models.dart';
import 'package:p2p_chat_android/util/functions.dart';
import 'package:p2p_chat_android/widgets/text_input_field.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

import '../constants.dart';
import 'chat_seeking_page.dart';
import 'settings_page.dart';

class MyHomePage extends StatefulWidget {
  final List<Conversation> conversations;
  MyHomePage({Key? key, required this.title, required this.context, required this.conversations}) : super(key: key);

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
  _MyHomePageState createState() => _MyHomePageState(context, conversations);
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {

  final Context ctx;
  List<Conversation> conversations;

  _MyHomePageState(this.ctx, this.conversations);

  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme
        .of(context)
        .textTheme;
    final conversationNameTextTheme = textTheme.bodyText1!.copyWith(fontSize: 19);
    if (conversations.isEmpty) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("Welcome to $APP_NAME\na Peer to Peer chat app", style: textTheme.headline4!.copyWith(color: Colors.white), textAlign: TextAlign.center,),
                Padding(padding: EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: 32),

                  child: UsernameTextInputField(onSubmit: this.updateUsername, username: ctx.userData.username,),),
                ElevatedButton(
                  child: Text('Search chat', style: Theme
                      .of(context)
                      .textTheme
                      .headline6),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(
                            builder: (context) => ChatSeekingPage(ctx)));
                  },
                )
              ],
            ),
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
                APP_NAME,
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
                    title: Text(conversation.name ?? "", style: conversationNameTextTheme,),
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

  void updateUsername(String username) async {
    UserData updatedUser = ctx.userData.copyWithUsername(username);
    await ctx.dbHelper.updateUser(updatedUser);
    setState(() {
      ctx.userData = updatedUser;
    });
    Fluttertoast.showToast(
        msg: "Username updated successfully",
        toastLength: Toast.LENGTH_SHORT
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }

  void onResume() async {
    // update state
    final conversations = await ctx.dbHelper.findAllConversations();
    final userData = await ctx.dbHelper.getMe();
    setState(() {
      this.conversations = conversations;
      this.ctx.userData = userData;
    });
  }
}