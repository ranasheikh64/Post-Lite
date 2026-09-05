import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/widgets/custom_button.dart';
import 'package:postmanclone/app/widgets/custom_textfield.dart';
import '../controllers/auth_controller.dart';


class RegisterView extends GetView<AuthController> {
  RegisterView({Key? key}) : super(key: key);

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
                'Create Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: controller.nameController,
                hintText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 32),
              Obx(() => CustomButton(
                text: 'Sign Up',
                isLoading: controller.isLoading.value,
                onPressed: () => controller.register(),
              )),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
