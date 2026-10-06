import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
class SocketMessage {
  final String content;
  final bool isSent;
  final DateTime timestamp;
  final String? eventName; // For Socket.IO
  final bool isSystem;

  SocketMessage({
    required this.content,
    required this.isSent,
    required this.timestamp,
    this.eventName,
    this.isSystem = false,
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
      if (wsUrl.startsWith('http://')) {
        wsUrl = wsUrl.replaceFirst('http://', 'ws://');
      } else if (wsUrl.startsWith('https://')) {
        wsUrl = wsUrl.replaceFirst('https://', 'wss://');
      } else if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) {
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
  void connectSocketIO(String url, Map<String, String> headers, [Map<String, String>? queryParams]) {
    if (url.isEmpty) return;
    
    disconnect();
    isConnecting.value = true;
    connectionError.value = '';
    
    try {
      var ioUrl = url.split('?').first;
      if (!ioUrl.startsWith('http://') && !ioUrl.startsWith('https://')) {
        ioUrl = 'http://$ioUrl';
      }

      // Sanitize and trim headers and query params
      final safeHeaders = <String, String>{};
      headers.forEach((key, value) {
        safeHeaders[key.trim()] = value.trim();
      });
      
      final safeQueryParams = <String, String>{};
      if (queryParams != null) {
        queryParams.forEach((key, value) {
          safeQueryParams[key.trim()] = value.trim();
        });
      }

      print('🚀 [SocketIO] Attempting connection to: $ioUrl');
      print('🚀 [SocketIO] Original Headers: $safeHeaders');
      print('🚀 [SocketIO] Original Query: $safeQueryParams');

      // To make this a perfect Postman clone, we should pass the auth headers
      // in multiple ways because different Socket.io backends parse it differently!
      final authPayload = <String, dynamic>{
        ...safeHeaders,
        'headers': safeHeaders,
      };
      
      // Find the token case-insensitively (Authorization, authorization, Token, token)
      String? authToken;
      for (var key in safeHeaders.keys) {
        if (key.toLowerCase() == 'authorization' || key.toLowerCase() == 'token') {
          authToken = safeHeaders[key];
          break;
        }
      }

      // Inject the token into all common properties that Socket.IO middlewares look for
      if (authToken != null) {
        authPayload['Authorization'] = authToken;
        authPayload['authorization'] = authToken;
        authPayload['token'] = authToken;
        // Also ensure it's in the nested headers case-insensitively
        final nestedHeaders = authPayload['headers'] as Map<String, String>;
        nestedHeaders['Authorization'] = authToken;
        nestedHeaders['authorization'] = authToken;
      }

      print('🚀 [SocketIO] Final Auth Payload built: $authPayload');

      final options = IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .setAuth(authPayload)
          .setExtraHeaders(safeHeaders);
          
      if (safeQueryParams.isNotEmpty) {
        options.setQuery(safeQueryParams);
      }

      _ioSocket = IO.io(ioUrl, options.build());
      
      _ioSocket!.onConnect((_) {
        isConnected.value = true;
        isConnecting.value = false;
        messages.add(SocketMessage(
          content: '✅ Successfully connected to $ioUrl',
          isSent: false,
          timestamp: DateTime.now(),
          isSystem: true,
        ));
      });
      
      _ioSocket!.onConnectError((err) {
        String errMsg = err.toString();
        // Try to parse standard Socket.io error object
        if (err is Map && err.containsKey('message')) {
          errMsg = err['message'].toString();
        } else if (err is String && err.contains('message:')) {
          // Fallback parsing if it's a stringified map
          final match = RegExp(r'message:\s*([^}]+)').firstMatch(err);
          if (match != null) {
            errMsg = match.group(1)?.trim() ?? errMsg;
          }
        }
        
        connectionError.value = errMsg;
        messages.add(SocketMessage(
          content: '❌ Connection Failed: $errMsg\n(Check if server is running, URL is correct, and Auth tokens are valid)',
          isSent: false,
          timestamp: DateTime.now(),
          isSystem: true,
        ));
        disconnect();
      });
      
      _ioSocket!.on('connect_timeout', (err) {
        connectionError.value = 'timeout';
        messages.add(SocketMessage(
          content: '⏱️ Connection Timeout: Server took too long to respond.',
          isSent: false,
          timestamp: DateTime.now(),
          isSystem: true,
        ));
        disconnect();
      });
      
      _ioSocket!.onError((err) {
        String errMsg = err.toString();
        if (err is Map && err.containsKey('message')) errMsg = err['message'].toString();
        
        connectionError.value = errMsg;
        messages.add(SocketMessage(
          content: '⚠️ Socket Error: $errMsg',
          isSent: false,
          timestamp: DateTime.now(),
          isSystem: true,
        ));
        // We don't forcefully disconnect on all general errors, just log them.
      });
      
      _ioSocket!.onDisconnect((reason) {
        String reasonStr = reason.toString();
        messages.add(SocketMessage(
          content: '🔌 Disconnected from $ioUrl (Reason: $reasonStr)',
          isSent: false,
          timestamp: DateTime.now(),
          isSystem: true,
        ));
        disconnect();
      });
      
      // Listen to generic messages or catch-all if possible
      _ioSocket!.onAny((event, data) {
        messages.add(SocketMessage(
          content: data != null ? (data is String ? data : jsonEncode(data)) : 'No data',
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
  void sendMessage(String message, {String? eventName, bool withAck = false}) {
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
      dynamic data;
      try {
        data = jsonDecode(message);
      } catch (_) {
        data = message; // fallback to string
      }
      
      if (withAck) {
        _ioSocket!.emitWithAck(event, data, ack: (responseData) {
          messages.add(SocketMessage(
            content: responseData != null ? (responseData is String ? responseData : jsonEncode(responseData)) : 'Ack received',
            isSent: false,
            timestamp: DateTime.now(),
            eventName: event,
          ));
        });
      } else {
        _ioSocket!.emit(event, data);
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
