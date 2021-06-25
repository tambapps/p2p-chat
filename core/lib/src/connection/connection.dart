import 'dart:async';
import 'dart:io';
import 'dart:typed_data';


abstract class Connection {

  InternetAddress get address;
  int get port;

  void send(data);

  void sendText(String data);

  StreamSubscription<dynamic> listen(void Function(Uint8List event) onData, {Function? onError});

  void close();

}

abstract class ConnectionServer<T extends Connection> {

  InternetAddress get address;
  int get port;

  StreamSubscription<dynamic> listen(ConnectionCallback<T> callback);

  void close();
}

typedef ConnectionCallback<T extends Connection> = void Function(T);

