import 'package:get/get.dart';
import 'app_routes.dart';

// Placeholders for views
import '../modules/auth/login_view.dart';
import '../modules/auth/register_view.dart';
import '../modules/auth/forgot_password_view.dart';
import '../modules/auth/reset_password_view.dart';
import '../modules/home/home_view.dart';
import '../modules/settings/settings_view.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: Routes.LOGIN, 
      page: () => LoginView(), 
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => RegisterView(),
    ),
    GetPage(
      name: Routes.FORGOT_PASSWORD,
      page: () => ForgotPasswordView(),
    ),
    GetPage(
      name: Routes.RESET_PASSWORD,
      page: () => ResetPasswordView(),
    ),
    GetPage(
      name: Routes.HOME, 
      page: () =>  HomeView(), 
    ),
    GetPage(
      name: Routes.SETTINGS,
      page: () => SettingsView(),
    ),
  ];
}
