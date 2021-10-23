import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p2p_chat_android/model/models.dart';
import 'package:p2p_chat_android/page/chatseekingpage.dart';
import 'package:p2p_chat_android/page/settings_page.dart';
import 'package:p2p_chat_android/sql/database_helper.dart';

import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = await DatabaseHelper.newInstance();
  runApp(MyApp(Context(dbHelper)));
}

class MyApp extends StatelessWidget {
  final Context context;

  MyApp(this.context);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final appBarTheme = AppBarTheme(centerTitle: false, elevation: 0);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark().copyWith(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kContentColorLightTheme,
        appBarTheme: appBarTheme,
        iconTheme: IconThemeData(color: kContentColorDarkTheme),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: kContentColorDarkTheme),
        colorScheme: ColorScheme.dark().copyWith(
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
          error: kErrorColor,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: kContentColorLightTheme,
          selectedItemColor: Colors.white70,
          unselectedItemColor: kContentColorDarkTheme.withOpacity(0.32),
          selectedIconTheme: IconThemeData(color: kPrimaryColor),
          showUnselectedLabels: true,
        ),
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', context: this.context),
    );
  }
}

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

  void goToSettingsPage() {
    Navigator.push(context,
        MaterialPageRoute(
            builder: (context) => SettingsPage(ctx: ctx)));
  }
}
