import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class RegisterView extends StatelessWidget {
  RegisterView({Key? key}) : super(key: key);

  final AuthController controller = Get.put(AuthController());

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
              TextField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  hintText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.emailController,
                decoration: const InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 32),
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : () => controller.register(),
                child: controller.isLoading.value 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sign Up'),
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
