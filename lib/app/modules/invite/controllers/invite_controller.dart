import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes/app_routes.dart';
import '../../../data/providers/api_service.dart';
import '../../../widgets/custom_snackbar.dart';

class InviteController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _processInvite();
  }

  Future<void> _processInvite() async {
    final token = Get.parameters['token'];
    
    if (token == null || token.isEmpty) {
      CustomSnackbar.showError('Error', 'Invalid invitation link');
      Get.offAllNamed(Routes.LOGIN);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userToken = prefs.getString('accessToken');

    if (userToken != null && userToken.isNotEmpty) {
      // User is logged in, try to accept invite directly
      try {
        final response = await _apiService.acceptWorkspaceInvite(token);
        CustomSnackbar.show(title: 'Success', response['message'] ?? 'Successfully joined workspace');
        Get.offAllNamed(Routes.HOME);
      } catch (e) {
        CustomSnackbar.showError('Failed to join', e.toString());
        Get.offAllNamed(Routes.HOME);
      }
    } else {
      // User is not logged in, save the token and redirect to signup
      await prefs.setString('pending_invite_token', token);
      Get.offAllNamed(Routes.REGISTER);
    }
  }
}
