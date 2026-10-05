import 'package:socket_io_client/socket_io_client.dart' as IO;
void main() {
  final options = IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjp7ImlkIjoiNmFjMzQ4NzFjYTQxZDVlZTgzYTIzYjQ0In0sImlhdCI6MTc5MTE4Mjk3OCwiZXhwIjoxNzkxNzg3Nzc4fQ.6Cx0BdjrjZvGJHx6ti5Z_iwKcZ24kCuWN_w1U35Kh5I'})
      .setExtraHeaders({'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjp7ImlkIjoiNmFjMzQ4NzFjYTQxZDVlZTgzYTIzYjQ0In0sImlhdCI6MTc5MTE4Mjk3OCwiZXhwIjoxNzkxNzg3Nzc4fQ.6Cx0BdjrjZvGJHx6ti5Z_iwKcZ24kCuWN_w1U35Kh5I'})
      .build();
  final socket = IO.io('http://localhost:5000', options);
  socket.onConnect((_) => print('Connected'));
  socket.onConnectError((err) => print('ConnectError: $err'));
  socket.onError((err) => print('Error: $err'));
}
