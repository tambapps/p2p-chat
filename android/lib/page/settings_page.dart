import 'package:flutter/material.dart';
import 'package:p2p_chat_android/model/models.dart';
import 'package:p2p_chat_android/widgets/text_input_field.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

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
      body: Container(
        child: UsernameTextInputField(onSubmit: this.updateUsername, username: ctx.userData.username,),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void updateUsername(String username) async {
    UserData updatedUser = ctx.userData.copyWithUsername(username);
    await ctx.dbHelper.updateUser(updatedUser);
    setState(() {
      ctx.userData = updatedUser;
    });
  }
}