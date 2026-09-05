import 'package:get/get.dart';
import 'package:postmanclone/app/data/providers/auth_service.dart';
import 'package:postmanclone/app/routes/app_routes.dart';
import 'package:postmanclone/app/widgets/custom_snackbar.dart';


class SettingsController extends GetxController {
  final AuthService _authService = AuthService();
  
  final isLoading = false.obs;
  final currentUser = Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      final token = await _authService.getAccessToken();
      if (token != null) {
        final user = await _authService.getMe();
        currentUser.value = user;
      }
    } catch (e) {
      currentUser.value = null;
      CustomSnackbar.show(title: 'Error', message: 'Failed to load profile', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser.value = null;
    Get.offAllNamed(Routes.LOGIN);
  }

  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;
      await _authService.deleteAccount();
      await _authService.logout();
      currentUser.value = null;
      Get.offAllNamed(Routes.LOGIN);
      CustomSnackbar.show(title: 'Success', message: 'Account deleted successfully');
    } catch (e) {
      CustomSnackbar.show(title: 'Failed', message: e.toString(), isError: true);
    } finally {
      isLoading.value = false;
    }
  }
}
