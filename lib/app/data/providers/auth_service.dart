import 'package:shared_preferences/shared_preferences.dart';
import 'network_caller.dart';

class AuthService {
  final NetworkCaller _network = NetworkCaller();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _network.postRequest('/auth/login', data: {
      'email': email,
      'password': password,
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', response.data['accessToken']);
    await prefs.setString('refreshToken', response.data['refreshToken']);
    
    return response.data;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _network.postRequest('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<void> forgotPassword(String email) async {
    await _network.postRequest('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await _network.postRequest('/auth/reset-password', data: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _network.getRequest('/auth/me');
    return response.data;
  }

  Future<void> deleteAccount() async {
    await _network.deleteRequest('/auth/me');
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
