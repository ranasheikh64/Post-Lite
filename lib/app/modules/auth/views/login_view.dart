import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/routes/app_routes.dart';
import 'package:postmanclone/app/widgets/custom_button.dart';
import 'package:postmanclone/app/widgets/custom_textfield.dart';
import '../controllers/auth_controller.dart';
import 'auth_widgets.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E1A),
              Color(0xFF0D1B2E),
              Color(0xFF0A1628),
            ],
          ),
        ),
        child: Row(
          children: [
            // ─── LEFT PANEL ───────────────────────────────────────────
            const Expanded(
              flex: 5,
              child: AuthLeftPanel(),
            ),

            // ─── RIGHT PANEL ──────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 32,
                  ),
                  child: AuthGlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Center(
                          child: Image.asset(
                            'assets/icons/main_logo.png',
                            width: 72,
                            height: 72,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to sync your workspace',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Email
                        CustomTextField(
                          controller: controller.emailController,
                          hintText: 'Email address',
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        const SizedBox(height: 14),

                        // Password
                        CustomTextField(
                          controller: controller.passwordController,
                          obscureText: true,
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),

                        // Error
                        Obx(
                          () => controller.loginError.value.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8, left: 2),
                                  child: Text(
                                    controller.loginError.value,
                                    style: const TextStyle(
                                      color: Color(0xFFFF6B6B),
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                Get.toNamed(Routes.FORGOT_PASSWORD),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF4FC3F7),
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Sign In Button
                        Obx(
                          () => CustomButton(
                            text: 'Sign In',
                            isLoading: controller.isLoading.value,
                            onPressed: () => controller.login(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Divider
                        _buildOrDivider(),
                        const SizedBox(height: 20),

                        // Register Link
                        Center(
                          child: TextButton(
                            onPressed: () => Get.toNamed(Routes.REGISTER),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF4FC3F7),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: "Don't have an account? ",
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'Sign up',
                                    style: TextStyle(
                                      color: Color(0xFF4FC3F7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}
