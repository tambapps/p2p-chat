import 'dart:io';

typedef WebSocketCallback = void Function(WebSocket socket);

class WebsocketServer {
  HttpServer server;

  WebsocketServer(this.server);

  static Future<WebsocketServer> from(address, int port) async {
    return WebsocketServer(await HttpServer.bind(address, 8000));
  }

  void listen(WebSocketCallback onNewSocket) async {
    server.listen((HttpRequest request) {
      WebSocketTransformer.upgrade(request).then((WebSocket ws) => onNewSocket(ws),
          onError: (err) => print('[!]Error -- ${err.toString()}'));

    }, onError: (err) => print('[!]Error -- ${err.toString()}'));
  }

  void close({bool force = false}) {
    server.close(force: force);
  }
}