import 'package:flutter/material.dart';
import 'package:p2p_chat_android/model/models.dart';

import '../constants.dart';

class SettingsPage extends StatefulWidget {
  final Context ctx;

  SettingsPage({Key? key, required this.ctx})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SettingsPageState(ctx);
  }
}

class _SettingsPageState extends State<SettingsPage> {
  final Context ctx;

  _SettingsPageState(this.ctx);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Expanded(child: Text(
              "Settings",
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            )
            )
          ],
        ),
      ),
      body: Container(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}