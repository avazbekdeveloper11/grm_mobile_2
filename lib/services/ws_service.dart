import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef WsCallback = void Function(Map<String, dynamic> msg);

class WsService {
  static const _baseWs =
      'ws://xnc9fjs58xbbiimup042ie3w.178.104.171.171.sslip.io';

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _token;
  bool _disposed = false;

  final List<WsCallback> _listeners = [];

  void addListener(WsCallback cb) => _listeners.add(cb);
  void removeListener(WsCallback cb) => _listeners.remove(cb);

  Future<void> connect(String token) async {
    _token = token;
    _disposed = false;
    await _connect();
  }

  Future<void> _connect() async {
    if (_disposed || _token == null) return;
    try {
      final uri = Uri.parse('$_baseWs?token=$_token');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready.timeout(const Duration(seconds: 5));

      _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            for (final cb in List.of(_listeners)) {
              cb(msg);
            }
          } catch (_) {}
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );

      // Ping har 25 sekund
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _channel?.sink.add('ping');
      });

      _reconnectTimer?.cancel();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _connect);
  }

  void disconnect() {
    _disposed = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _listeners.clear();
  }
}
