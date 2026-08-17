import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
class SocketMessage {
  final String content;
  final bool isSent;
  final DateTime timestamp;
  final String? eventName; // For Socket.IO

  SocketMessage({
    required this.content,
    required this.isSent,
    required this.timestamp,
    this.eventName,
  });
}

class SocketController extends GetxController {
  // Connection State
  var isConnected = false.obs;
  var isConnecting = false.obs;
  var connectionError = ''.obs;

  // Messages History
  var messages = <SocketMessage>[].obs;

  // Active Connections
  WebSocketChannel? _wsChannel;
  IO.Socket? _ioSocket;

  // Connect WebSocket
  void connectWebSocket(String url, Map<String, String> headers) {
    if (url.isEmpty) return;
    
    disconnect();
    isConnecting.value = true;
    connectionError.value = '';
    
    try {
      var wsUrl = url;
      if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) {
        wsUrl = 'ws://$wsUrl';
      }
      
      final uri = Uri.parse(wsUrl);
      _wsChannel = WebSocketChannel.connect(uri);
      
      isConnected.value = true;
      isConnecting.value = false;
      
      _wsChannel!.stream.listen(
        (message) {
          messages.add(SocketMessage(
            content: message.toString(),
            isSent: false,
            timestamp: DateTime.now(),
          ));
        },
        onError: (error) {
          connectionError.value = error.toString();
          disconnect();
        },
        onDone: () {
          disconnect();
        },
      );
    } catch (e) {
      connectionError.value = e.toString();
      disconnect();
    }
  }

  // Connect Socket.IO
  void connectSocketIO(String url, Map<String, String> headers) {
    if (url.isEmpty) return;
    
    disconnect();
    isConnecting.value = true;
    connectionError.value = '';
    
    try {
      var ioUrl = url;
      if (!ioUrl.startsWith('http://') && !ioUrl.startsWith('https://')) {
        ioUrl = 'http://$ioUrl';
      }

      _ioSocket = IO.io(ioUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders(headers)
          .build()
      );
      
      _ioSocket!.onConnect((_) {
        isConnected.value = true;
        isConnecting.value = false;
      });
      
      _ioSocket!.onConnectError((err) {
        connectionError.value = err.toString();
        disconnect();
      });
      
      _ioSocket!.onDisconnect((_) {
        disconnect();
      });
      
      // Listen to generic messages or catch-all if possible
      _ioSocket!.onAny((event, data) {
        messages.add(SocketMessage(
          content: data != null ? (data is String ? data : jsonEncode(data)) : '',
          isSent: false,
          timestamp: DateTime.now(),
          eventName: event,
        ));
      });
      
      _ioSocket!.connect();
    } catch (e) {
      connectionError.value = e.toString();
      disconnect();
    }
  }

  // Disconnect
  void disconnect() {
    _wsChannel?.sink.close();
    _wsChannel = null;
    
    _ioSocket?.disconnect();
    _ioSocket?.dispose();
    _ioSocket = null;
    
    Future.microtask(() {
      if (!isClosed) {
        isConnected.value = false;
        isConnecting.value = false;
      }
    });
  }

  // Send Message
  void sendMessage(String message, {String? eventName}) {
    if (!isConnected.value) return;
    
    if (_wsChannel != null) {
      _wsChannel!.sink.add(message);
      messages.add(SocketMessage(
        content: message,
        isSent: true,
        timestamp: DateTime.now(),
      ));
    } else if (_ioSocket != null) {
      final event = eventName != null && eventName.isNotEmpty ? eventName : 'message';
      try {
        final parsedJson = jsonDecode(message);
        _ioSocket!.emit(event, parsedJson);
      } catch (_) {
        _ioSocket!.emit(event, message); // fallback to string
      }
      messages.add(SocketMessage(
        content: message,
        isSent: true,
        timestamp: DateTime.now(),
        eventName: event,
      ));
    }
  }

  void clearMessages() {
    messages.clear();
  }
  
  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
