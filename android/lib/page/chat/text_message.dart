import 'package:flutter/material.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

import '../../../constants.dart';

class TextMessage extends StatelessWidget {
  const TextMessage({
    Key? key,
    required this.message,
    required this.userData
  }) : super(key: key);

  final Message message;
  final UserData userData;

  @override
  Widget build(BuildContext context) {
    print(userData.username);
    print(message.userData.username);
    print(message.userData == userData);
    return Container(
      /*
      color: MediaQuery.of(context).platformBrightness == Brightness.dark
          ? Colors.white
          : Colors.black,*/
      padding: EdgeInsets.symmetric(
        horizontal: kDefaultPadding * 0.75,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(message.userData == userData ? 1 : 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: message.userData == userData
              ? Colors.white
              : Theme.of(context).textTheme.bodyText1!.color,
        ),
      ),
    );
  }
}
