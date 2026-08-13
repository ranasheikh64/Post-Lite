import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Use local machine IP instead of localhost so it works on emulators & physical devices
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:4000/auth'));

  AuthService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/login', data: {
      'email': email,
      'password': password,
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', response.data['accessToken']);
    await prefs.setString('refreshToken', response.data['refreshToken']);
    
    return response.data;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _dio.post('/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await _dio.post('/reset-password', data: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/me');
    return response.data;
  }

  Future<void> deleteAccount() async {
    await _dio.delete('/me');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }
}
