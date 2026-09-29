import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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
  
  String initialRoute = Routes.LOGIN;
  
  if (token != null && token.isNotEmpty) {
    bool isExpired = JwtDecoder.isExpired(token);
    if (!isExpired) {
      initialRoute = Routes.HOME;
    } else {
      // Clear expired tokens
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
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
