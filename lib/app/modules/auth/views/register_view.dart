import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/widgets/custom_button.dart';
import 'package:postmanclone/app/widgets/custom_textfield.dart';
import '../controllers/auth_controller.dart';
import 'auth_widgets.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            return Row(
              children: [
                // ─── LEFT PANEL (hidden on small screens) ─────────────
                if (isWide)
                  const Expanded(
                    flex: 5,
                    child: AuthLeftPanel(),
                  ),

                // ─── RIGHT PANEL ──────────────────────────────────────
                Expanded(
                  flex: isWide ? 4 : 1,
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
                          'Create Account',
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
                          'Start testing APIs with your team',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Full Name
                        CustomTextField(
                          controller: controller.nameController,
                          hintText: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        const SizedBox(height: 14),

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
                        const SizedBox(height: 28),

                        // Sign Up Button
                        Obx(
                          () => CustomButton(
                            text: 'Create Account',
                            isLoading: controller.isLoading.value,
                            onPressed: () => controller.register(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Divider
                        _buildOrDivider(),
                        const SizedBox(height: 20),

                        // Login Link
                        Center(
                          child: TextButton(
                            onPressed: () => Get.back(),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF4FC3F7),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Already have an account? ',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'Sign in',
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
            );
          },
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
