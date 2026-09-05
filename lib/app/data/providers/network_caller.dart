import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

class NetworkCaller {
  static final NetworkCaller _instance = NetworkCaller._internal();
  factory NetworkCaller() => _instance;

  late Dio _dio;

  NetworkCaller._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://10.0.60.243:4000',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        log('┌------------------------------------------------------------------', name: 'API Request');
        log('| URL: ${options.method} ${options.baseUrl}${options.path}', name: 'API Request');
        log('| Headers: ${options.headers}', name: 'API Request');
        if (options.queryParameters.isNotEmpty) log('| Query Params: ${options.queryParameters}', name: 'API Request');
        if (options.data != null) log('| Body: ${options.data}', name: 'API Request');
        log('└------------------------------------------------------------------', name: 'API Request');

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        log('┌------------------------------------------------------------------', name: 'API Response');
        log('| URL: ${response.requestOptions.method} ${response.requestOptions.baseUrl}${response.requestOptions.path}', name: 'API Response');
        log('| Status: ${response.statusCode}', name: 'API Response');
        log('| Data: ${response.data}', name: 'API Response');
        log('└------------------------------------------------------------------', name: 'API Response');
        return handler.next(response);
      },
      onError: (error, handler) async {
        log('┌------------------------------------------------------------------', name: 'API Error');
        log('| URL: ${error.requestOptions.method} ${error.requestOptions.baseUrl}${error.requestOptions.path}', name: 'API Error');
        log('| Status: ${error.response?.statusCode}', name: 'API Error');
        log('| Message: ${error.message}', name: 'API Error');
        if (error.response?.data != null) log('| Response: ${error.response?.data}', name: 'API Error');
        log('└------------------------------------------------------------------', name: 'API Error');

        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refreshToken');
          
          if (refreshToken != null) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: 'http://10.0.60.243:4000/auth'));
              final refreshResponse = await refreshDio.post('/refresh', data: {
                'refreshToken': refreshToken,
              });
              
              if (refreshResponse.statusCode == 200) {
                final newAccessToken = refreshResponse.data['accessToken'];
                await prefs.setString('accessToken', newAccessToken);
                
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccessToken';
                final cloneReq = await Dio().fetch(opts);
                return handler.resolve(cloneReq);
              }
            } catch (e) {
              await prefs.remove('accessToken');
              await prefs.remove('refreshToken');
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response> getRequest(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> postRequest(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> putRequest(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patchRequest(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> deleteRequest(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      rethrow;
    }
  }
}
