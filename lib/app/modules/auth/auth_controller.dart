import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/providers/auth_service.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final otpController = TextEditingController();

  final isLoading = false.obs;
  final currentUser = Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    otpController.dispose();
    super.onClose();
  }

  Future<void> fetchProfile() async {
    try {
      final token = await _authService.getAccessToken();
      if (token != null) {
        final user = await _authService.getMe();
        currentUser.value = user;
      }
    } catch (e) {
      // Token might be expired, user needs to login again
      currentUser.value = null;
    }
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    try {
      isLoading.value = true;
      await _authService.login(emailController.text, passwordController.text);
      await fetchProfile();
      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      Get.snackbar('Login Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    try {
      isLoading.value = true;
      await _authService.register(nameController.text, emailController.text, passwordController.text);
      Get.snackbar('Success', 'Registration successful. Please login.');
      Get.offNamed(Routes.LOGIN);
    } catch (e) {
      Get.snackbar('Registration Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword() async {
    if (emailController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter your email');
      return;
    }

    try {
      isLoading.value = true;
      await _authService.forgotPassword(emailController.text);
      Get.snackbar('Success', 'OTP sent to your email');
      Get.toNamed(Routes.RESET_PASSWORD);
    } catch (e) {
      Get.snackbar('Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (emailController.text.isEmpty || otpController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    try {
      isLoading.value = true;
      await _authService.resetPassword(emailController.text, otpController.text, passwordController.text);
      Get.snackbar('Success', 'Password reset successfully');
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      Get.snackbar('Failed', e.toString());
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
