import 'package:get/get.dart';
import 'package:postmanclone/app/data/providers/auth_service.dart';
import 'package:postmanclone/app/modules/home/controllers/workspace_controller.dart';
import 'package:postmanclone/app/routes/app_routes.dart';
import 'package:postmanclone/app/widgets/custom_snackbar.dart';


class SettingsController extends GetxController {
  final AuthService _authService = AuthService();

  // Access the already-registered WorkspaceController
  WorkspaceController get workspaceController => Get.find<WorkspaceController>();

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

  /// Returns the current user's role in a given workspace map.
  String userRoleIn(Map ws) {
    final userId = currentUser.value?['_id'] as String?;
    if (userId == null) return '';
    // Check if owner
    if (ws['owner'] is Map && ws['owner']['_id'] == userId) return 'owner';
    final members = ws['members'] as List? ?? [];
    for (final m in members) {
      if (m is Map && m['user'] is Map && m['user']['_id'] == userId) {
        return m['role'] as String? ?? 'member';
      }
    }
    return 'member';
  }
}
