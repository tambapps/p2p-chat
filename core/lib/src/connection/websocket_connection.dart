import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:p2p_chat_core/src/chat.dart';
import 'package:p2p_chat_core/src/chat_automation.dart';
import 'package:p2p_chat_core/src/connection/connection.dart';

class WebSocketConnection implements Connection {
  @override
  final InternetAddress address;
  @override
  final int port;
  final WebSocket _webSocket;
  @override
  late ChatAutomaton<Chat> automaton;

  static Future<WebSocketConnection> from(InternetAddress address, int port) async {
    return WebSocketConnection(address, port, await WebSocket.connect('ws://${address.address}:$port'));
  }

  WebSocketConnection(this.address, this.port, this._webSocket);

  @override
  void send(data) {
    _webSocket.add(data);
  }

  @override
  void sendText(String data) {
    _webSocket.add(data.codeUnits);
  }
  @override
  StreamSubscription<dynamic> listen(void Function(Uint8List event) onData, {Function? onError, void Function()? onDone}) {
    return _webSocket.listen((event) => onData(event), onError: onError, onDone: onDone);
  }

  @override
  void close() {
    _webSocket.close();
  }
}

class WebSocketServer implements ConnectionServer<WebSocketConnection> {
  final HttpServer _server;

  @override
  InternetAddress get address => _server.address;
  @override
  int get port => _server.port;

  WebSocketServer(this._server);

  static Future<WebSocketServer> from(address, int port) async {
    return WebSocketServer(await HttpServer.bind(address, 8000));
  }

  @override
  StreamSubscription<HttpRequest> listen(ConnectionCallback<WebSocketConnection> onNewConnection, {Function? onError, void Function()? onDone}) {
    return _server.listen((HttpRequest request) {
      WebSocketTransformer.upgrade(request).then((WebSocket ws) => onNewConnection(WebSocketConnection(address, port, ws)),
          onError: onError);

    }, onError: onError, onDone: onDone);
  }

  void close({bool force = false}) {
    _server.close(force: force);
  }
}