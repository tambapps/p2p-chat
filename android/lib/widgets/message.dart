import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:p2p_chat_core/p2p_chat_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';

class MessageWidget extends StatefulWidget {

  final UserData userData;
  final Message message;
  final Message? previousMessage;
  final Function(Message) deleteCallback;

  MessageWidget({
    Key? key,
    required this.message,
    required this.userData,
    required this.deleteCallback,
    this.previousMessage
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MessageWidgetState(userData: userData, message: message, previousMessage: previousMessage, deleteCallback: deleteCallback);
  }
}
class _MessageWidgetState extends State<MessageWidget> {

  _MessageWidgetState({
    required this.message,
    required this.userData,
    required this.deleteCallback,
    this.previousMessage
  });

  // used to know if is sender or not
  final UserData userData;
  final Message message;
  final Message? previousMessage;
  final Function(Message) deleteCallback;
  bool forceShowDate = false;
  Future? cancelFuture;

  @override
  Widget build(BuildContext context) {
    final bool shouldDisplayHeadline = _shouldDisplayHeadline();
    final bool shouldDisplayTime = _shouldDisplayTime();
    return Padding(
      padding: EdgeInsets.only(top: shouldDisplayHeadline ? kDefaultPadding * 2.0 / 6.0 : 0),
      child: InkWell(
        onTap: _forceShowDate,
        onLongPress: () => showOptions(context),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               AnimatedContainer(duration: Duration(milliseconds: shouldDisplayTime || forceShowDate ? 400 : 600),
                constraints: const BoxConstraints(minWidth: double.infinity),
              height: shouldDisplayTime || forceShowDate ? (previousMessage != null ? kDefaultPadding * 1.5 : kDefaultPadding) : 0,
              curve: shouldDisplayTime || forceShowDate ? Curves.fastOutSlowIn : Curves.easeIn,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(formatDate(message.sentAt), style: TextStyle(color: Colors.white30), textAlign: TextAlign.center,),
              ),),
              if (shouldDisplayHeadline) Text(message.userData.username,
                style: TextStyle(fontSize: 16, color: message.userData.id == userData.id ? kPrimaryColor : null, fontWeight: FontWeight.bold),),
              Linkify(
                onOpen: (link) async {
                  if (await canLaunch(link.url)) {
                    await launch(link.url);
                  } else {
                    Fluttertoast.showToast(
                        msg: "Couldn't open link",
                        toastLength: Toast.LENGTH_SHORT
                    );
                  }
                },
                text: message.text,
                textAlign: TextAlign.start,
              ),
            ],
          ),),
      ),
    );
  }

  void showOptions(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    const padding = EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2);
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          direction: Axis.horizontal,
          children: [
            Container(
              decoration: BoxDecoration(color: kContentColorLightTheme),
              width: width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      copyToClipBoard();
                      Navigator.pop(context);
                    },
                    child: Padding(padding: padding,
                      child: Text("Copy Text"),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      deleteDialog(context);
                    },
                    child: Padding(padding: padding,
                      child: Text("Delete Message", style: TextStyle(color: Colors.red),),
                    ),
                  )
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.only(top: kDefaultPadding))
          ],
        );
      },
    );
  }

  void deleteDialog(BuildContext context) {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text('Delete message?'),
        content: Text('You will no longer be able to retrieve it if you do so'),
        actions: [
          TextButton(
            onPressed: () {
              deleteCallback(message);
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

  void copyToClipBoard() {
    Clipboard.setData(ClipboardData(text: message.text));
    Fluttertoast.showToast(
        msg: "Message copied to clipboard",
        toastLength: Toast.LENGTH_SHORT
    );
  }

  bool _shouldDisplayTime() {
    return previousMessage == null || message.sentAt.difference(previousMessage!.sentAt).abs().inMinutes > 10;
  }

  bool _shouldDisplayHeadline() {
    return previousMessage == null || previousMessage!.userData.id != message.userData.id || message.sentAt.difference(previousMessage!.sentAt).abs().inMinutes > 10;
  }
  void _forceShowDate() {
    if (this.cancelFuture != null) {
      return;
    }
    setState(() {
      forceShowDate = true;
    });
    this.cancelFuture = Future.delayed(const Duration(seconds: 3), () => setState(() {
      forceShowDate = false;
      this.cancelFuture = null;
    }));
  }
}

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
