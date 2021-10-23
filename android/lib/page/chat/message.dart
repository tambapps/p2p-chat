import 'package:flutter/material.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';

import '../../../constants.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    Key? key,
    required this.message,
    required this.userData
  }) : super(key: key);

  // used to know if is sender or not
  final UserData userData;
  final Message message;

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: () {

      },
      onLongPress: () {

      },
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Opacity(
          // TODO handle if message is sent or not
          opacity: true ? 1.0 : 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.userData.username,
                style: TextStyle(fontSize: 16),),
              Text(message.text, textAlign: TextAlign.start,),
            ],
          ),
        ),
      ),
    );
  }
}

// TODO handle this
enum MessageStatus {
  sent, not_sent
}
class MessageStatusDot extends StatelessWidget {
  final MessageStatus? status;

  const MessageStatusDot({Key? key, this.status}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    Color dotColor(MessageStatus status) {
      switch (status) {
        case MessageStatus.not_sent:
          return kErrorColor;
      //  case MessageStatus.not_view:
        //  return Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.1);
        case MessageStatus.sent:
          return kPrimaryColor;
        default:
          return Colors.transparent;
      }
    }

    return Container(
      margin: EdgeInsets.only(left: kDefaultPadding / 2),
      height: 12,
      width: 12,
      decoration: BoxDecoration(
        color: dotColor(status!),
        shape: BoxShape.circle,
      ),
      child: Icon(
        status == MessageStatus.not_sent ? Icons.close : Icons.done,
        size: 8,
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}
