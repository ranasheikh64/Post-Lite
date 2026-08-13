import 'package:get/get.dart';
import '../../data/providers/auth_service.dart';
import '../../routes/app_routes.dart';

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
      Get.snackbar('Error', 'Failed to load profile');
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
      Get.snackbar('Success', 'Account deleted successfully');
    } catch (e) {
      Get.snackbar('Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
