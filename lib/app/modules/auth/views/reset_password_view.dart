import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/widgets/custom_button.dart';
import 'package:postmanclone/app/widgets/custom_textfield.dart';
import '../controllers/auth_controller.dart';


class ResetPasswordView extends GetView<AuthController> {
  ResetPasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter OTP',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please enter the OTP sent to your email and your new password.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: controller.otpController,
                hintText: '6-digit OTP',
                prefixIcon: const Icon(Icons.security),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: controller.passwordController,
                obscureText: true,
                hintText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              const SizedBox(height: 32),
              Obx(() => CustomButton(
                text: 'Update Password',
                isLoading: controller.isLoading.value,
                onPressed: () => controller.resetPassword(),
              )),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
