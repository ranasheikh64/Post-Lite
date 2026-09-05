import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/routes/app_routes.dart';
import 'package:postmanclone/app/widgets/custom_button.dart';
import 'package:postmanclone/app/widgets/custom_textfield.dart';
import '../controllers/auth_controller.dart';


class LoginView extends GetView<AuthController> {
  LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                'Jronix API Client',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to sync your workspace',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: controller.emailController,
                hintText: 'Email address',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: controller.passwordController,
                obscureText: true,
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.toNamed(Routes.FORGOT_PASSWORD),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => CustomButton(
                text: 'Sign In',
                isLoading: controller.isLoading.value,
                onPressed: () => controller.login(),
              )),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Get.toNamed(Routes.REGISTER),
                child: const Text('Don\'t have an account? Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
