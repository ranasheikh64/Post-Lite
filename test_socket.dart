import 'package:socket_io_client/socket_io_client.dart' as IO;
void main() {
  final options = IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'})
      .setExtraHeaders({'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'})
      .build();
  final socket = IO.io('http://localhost:5000', options);
  socket.onConnect((_) => print('Connected'));
  socket.onConnectError((err) => print('ConnectError: $err'));
  socket.onError((err) => print('Error: $err'));
}
