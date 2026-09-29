import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress the Flutter keyboard state assertion bug that occurs
  // during page transitions on desktop (Escape key duplicate event).
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    if (msg.contains('_pressedKeys.containsKey') ||
        msg.contains('KeyDownEvent is dispatched')) {
      // Known Flutter desktop keyboard sync bug — safe to ignore
      return;
    }
    FlutterError.presentError(details);
  };

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Check auth state for initial routing
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');
  final refreshToken = prefs.getString('refreshToken');

  String initialRoute = Routes.REGISTER;

  if (token != null && token.isNotEmpty) {
    bool isExpired = JwtDecoder.isExpired(token);
    if (!isExpired) {
      initialRoute = Routes.HOME;
    } else {
      // Access token is expired, check refresh token
      if (refreshToken != null && refreshToken.isNotEmpty) {
        bool isRefreshExpired = JwtDecoder.isExpired(refreshToken);
        if (!isRefreshExpired) {
          try {
            final dio = Dio(
              BaseOptions(baseUrl: 'https://post-lite-backend.vercel.app'),
            );
            final refreshResponse = await dio.post(
              '/auth/refresh',
              data: {'refreshToken': refreshToken},
            );

            if (refreshResponse.statusCode == 200) {
              final newAccessToken = refreshResponse.data['accessToken'];
              await prefs.setString('accessToken', newAccessToken);
              initialRoute = Routes.HOME;
            } else {
              initialRoute = Routes.LOGIN;
            }
          } catch (e) {
            await prefs.remove('accessToken');
            await prefs.remove('refreshToken');
            initialRoute = Routes.LOGIN;
          }
        } else {
          await prefs.remove('accessToken');
          await prefs.remove('refreshToken');
          initialRoute = Routes.LOGIN;
        }
      } else {
        await prefs.remove('accessToken');
        initialRoute = Routes.LOGIN;
      }
    }
  }

  runApp(
    GetMaterialApp(
      title: 'Jronix API Client',
      theme: AppTheme.darkTheme,
      initialRoute: initialRoute,
      getPages: AppPages.pages,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );
}
