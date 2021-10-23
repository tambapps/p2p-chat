import 'package:flutter/material.dart';

import '../constants.dart';

class ConversationTextInputField extends StatelessWidget {

  final controller = TextEditingController();
  final Function(String) onSendClick;

  ConversationTextInputField({
    Key? key,
    required this.onSendClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double maxHeight = MediaQuery.of(context).size.height / 4;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 32,
            color: Color(0xFF087949).withOpacity(0.08),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: kDefaultPadding * 0.75,
                ),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        constraints: BoxConstraints(maxHeight: maxHeight),
                        child: SingleChildScrollView(
                          child: TextField(
                            controller: controller,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: "Type message",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: kDefaultPadding / 4),
                    IconButton(onPressed: this.sendMessage,
                        icon: Icon(
                          Icons.send,
                          color: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .color!
                              .withOpacity(0.64),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void sendMessage() {
    final text = controller.text;
    if (text.isNotEmpty) {
      onSendClick(text);
      controller.text = "";
    }
  }
}

class UsernameTextInputField extends StatelessWidget {

  final controller = TextEditingController();
  final Function(String) onSubmit;

  UsernameTextInputField({required this.onSubmit, String? username}) {
    if (username != null) {
      controller.text = username;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Username"),
        Row(
          children: [
            Expanded(child: TextField(
              controller: controller,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: "Type username",
              ),
              onSubmitted: (_) => onSubmit(controller.text),
            )
            ),
            IconButton(onPressed: () => onSubmit(controller.text),
                icon: Icon(
                  Icons.check_circle,
                  color: kPrimaryColor,
                ))
          ],
        )
      ],
    );
  }
}
