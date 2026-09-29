import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/routes/app_routes.dart';
import 'package:postmanclone/app/widgets/custom_button.dart';
import 'package:postmanclone/app/widgets/custom_textfield.dart';
import '../controllers/auth_controller.dart';

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
            Expanded(
              flex: 5,
              child: _LeftPanel(),
            ),

            // ─── RIGHT PANEL ──────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  child: _GlassCard(
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
                        Obx(() => controller.loginError.value.isNotEmpty
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
                            : const SizedBox.shrink()),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Get.toNamed(Routes.FORGOT_PASSWORD),
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
                        Obx(() => CustomButton(
                              text: 'Sign In',
                              isLoading: controller.isLoading.value,
                              onPressed: () => controller.login(),
                            )),
                        const SizedBox(height: 20),

                        // Divider
                        Row(
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
                        ),
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
                                      color: Colors.white.withValues(alpha: 0.5),
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
}

// ── Shared Left Panel ──────────────────────────────────────────────────────────
class _LeftPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D2137), Color(0xFF061120)],
        ),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Glow blobs
          Positioned(
            top: -80,
            left: -80,
            child: _GlowBlob(color: const Color(0xFF1565C0), size: 300),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: _GlowBlob(color: const Color(0xFF0288D1), size: 250),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand logo + name
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/main_logo.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Jronix',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Headline
                const Text(
                  'Test APIs\nFaster Than\nEver Before.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The modern API client built for\ndevelopers who move fast.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),

                // Feature pills
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _FeaturePill(icon: Icons.bolt, label: 'REST & GraphQL'),
                    _FeaturePill(icon: Icons.wifi, label: 'WebSocket'),
                    _FeaturePill(icon: Icons.sync_alt, label: 'Socket.IO'),
                    _FeaturePill(icon: Icons.people_outline, label: 'Team Workspaces'),
                  ],
                ),

                // Illustration
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32, bottom: 16),
                      child: Image.asset(
                        'assets/icons/login_screen_image.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.25), Colors.transparent],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4FC3F7)),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Glass Card ──────────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: -8,
          ),
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.15),
            blurRadius: 80,
            spreadRadius: -16,
          ),
        ],
      ),
      child: child,
    );
  }
}
