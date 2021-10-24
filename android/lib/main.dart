import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p2p_chat_android/model/models.dart';
import 'package:p2p_chat_android/page/home_page.dart';
import 'package:p2p_chat_android/sql/database_helper.dart';
import 'package:p2p_chat_android/util/functions.dart';

import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = await DatabaseHelper.newInstance();
  final conversations = await dbHelper.findAllConversations();
  runApp(MyApp(Context(dbHelper, await dbHelper.getMe()), conversations));
}

class MyApp extends StatelessWidget {
  final Context context;
  final List<Conversation> conversations;

  MyApp(this.context, this.conversations);

  @override
  Widget build(BuildContext context) {
    final appBarTheme = AppBarTheme(centerTitle: false, elevation: 0, color: kPrimaryColor);
    return MaterialApp(
      title: APP_NAME,
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
      home: MyHomePage(title: APP_NAME, context: this.context, conversations: conversations),
    );
  }
}