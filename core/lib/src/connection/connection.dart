import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../chat_automation.dart';

abstract class Connection {

  InternetAddress get address;
  int get port;
  late ChatAutomaton automaton;

  void send(data);

  void sendText(String data);

  StreamSubscription<dynamic> listen(void Function(Uint8List event) onData, {Function? onError, void Function()? onDone});

  void close();

}

abstract class ConnectionServer<T extends Connection> {

  InternetAddress get address;
  int get port;

  StreamSubscription<dynamic> listen(ConnectionCallback<T> callback,
      {Function? onError, void Function()? onDone});

  void close();
}

typedef ConnectionCallback<T extends Connection> = void Function(T);

