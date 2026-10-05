import 'package:socket_io_client/socket_io_client.dart' as IO;
void main() {
  final options1 = IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': 'invalid'})
      .build();
  final socket1 = IO.io('http://localhost:5000', options1);
  socket1.connect();
  
  Future.delayed(Duration(seconds: 1), () {
    final options2 = IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjp7ImlkIjoiNmFjMzQ4NzFjYTQxZDVlZTgzYTIzYjQ0In0sImlhdCI6MTc5MTE4Mjk3OCwiZXhwIjoxNzkxNzg3Nzc4fQ.6Cx0BdjrjZvGJHx6ti5Z_iwKcZ24kCuWN_w1U35Kh5I'})
        .build();
    final socket2 = IO.io('http://localhost:5000', options2);
    socket2.onConnect((_) => print('Socket 2 Connected'));
    socket2.onConnectError((err) => print('Socket 2 ConnectError: $err'));
    socket2.connect();
  });
}
