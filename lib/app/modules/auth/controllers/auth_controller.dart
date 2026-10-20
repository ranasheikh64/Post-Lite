import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/data/providers/auth_service.dart';
import 'package:postmanclone/app/routes/app_routes.dart';
import 'package:postmanclone/app/widgets/custom_snackbar.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postmanclone/app/data/providers/api_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final otpController = TextEditingController();

  final isLoading = false.obs;
  final isForgotLoading = false.obs;
  final isResetLoading = false.obs;
  final loginError = ''.obs;
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
    loginError.value = '';
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      loginError.value = 'Please fill all fields';
      return;
    }

    try {
      isLoading.value = true;
      await _authService.login(emailController.text, passwordController.text);
      await fetchProfile();
      await _checkAndAcceptInvite();
      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['message'] != null) {
          loginError.value = e.response!.data['message'].toString();
        } else {
          loginError.value = 'Invalid credentials';
        }
      } else {
        loginError.value = 'An error occurred. Please try again.';
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      CustomSnackbar.show(
        title: 'Error',
        message: 'Please fill all fields',
        isError: true,
      );
      return;
    }

    try {
      isLoading.value = true;
      await _authService.register(
        nameController.text,
        emailController.text,
        passwordController.text,
      );
      // Auto-login after registration to accept invite if exists
      await _authService.login(emailController.text, passwordController.text);
      await fetchProfile();
      await _checkAndAcceptInvite();
      CustomSnackbar.show(
        title: 'Success',
        message: 'Registration successful.',
      );
      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      CustomSnackbar.show(
        title: 'Registration Failed',
        message: e.toString(),
        isError: true,
      );
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      CustomSnackbar.show(title: 'Error', message: 'Please enter your email', isError: true);
      return;
    }
    if (!GetUtils.isEmail(email)) {
      CustomSnackbar.show(title: 'Error', message: 'Please enter a valid email', isError: true);
      return;
    }
    try {
      isForgotLoading.value = true;
      await _authService.forgotPassword(email);
      CustomSnackbar.show(title: 'OTP Sent', message: 'Check your inbox for the 6-digit code');
      Get.toNamed(Routes.RESET_PASSWORD);
    } catch (e) {
      CustomSnackbar.show(title: 'Failed', message: e.toString(), isError: true);
    } finally {
      if (!isClosed) isForgotLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    final otp = otpController.text.trim();
    final pass = passwordController.text.trim();
    if (otp.isEmpty || pass.isEmpty) {
      CustomSnackbar.show(title: 'Error', message: 'Please fill all fields', isError: true);
      return;
    }
    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      CustomSnackbar.show(title: 'Error', message: 'OTP must be exactly 6 digits', isError: true);
      return;
    }
    if (pass.length < 6) {
      CustomSnackbar.show(title: 'Error', message: 'Password must be at least 6 characters', isError: true);
      return;
    }
    try {
      isResetLoading.value = true;
      await _authService.resetPassword(emailController.text.trim(), otp, pass);
      CustomSnackbar.show(title: 'Success', message: 'Password reset successfully');
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      CustomSnackbar.show(title: 'Failed', message: e.toString(), isError: true);
    } finally {
      if (!isClosed) isResetLoading.value = false;
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
      CustomSnackbar.show(
        title: 'Success',
        message: 'Account deleted successfully',
      );
    } catch (e) {
      CustomSnackbar.show(
        title: 'Failed',
        message: e.toString(),
        isError: true,
      );
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> _checkAndAcceptInvite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('pending_invite_token');
      if (token != null && token.isNotEmpty) {
        final api = ApiService();
        final res = await api.acceptWorkspaceInvite(token);
        CustomSnackbar.show(
          title: 'Team Joined',
          message: res['message'] ?? 'Successfully joined workspace',
          isError: false,
        );
        await prefs.remove('pending_invite_token');
      }
    } catch (e) {
      // It's okay if it fails, the token might be expired or already used
      debugPrint('Invite accept error: $e');
    }
  }
}
