import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/widgets/custom_button.dart';
import 'package:postmanclone/app/widgets/custom_textfield.dart';
import '../controllers/auth_controller.dart';
import 'auth_widgets.dart';

class ForgotPasswordView extends GetView<AuthController> {
  ForgotPasswordView({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E1A), Color(0xFF0D1B2E), Color(0xFF0A1628)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            return Row(
              children: [
                if (isWide) const Expanded(flex: 5, child: AuthLeftPanel()),
                Expanded(
                  flex: isWide ? 4 : 1,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                      child: AuthGlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFF6C37).withValues(alpha: 0.12),
                                    border: Border.all(color: const Color(0xFFFF6C37).withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFFF6C37), size: 26),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Forgot Password?',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Enter your email and we\'ll send you a 6-digit OTP to reset your password.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              CustomTextField(
                                controller: controller.emailController,
                                hintText: 'Email address',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(Icons.email_outlined),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email is required';
                                  if (!GetUtils.isEmail(v.trim())) return 'Enter a valid email';
                                  return null;
                                },
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                              ),
                              const SizedBox(height: 24),
                              Obx(() => CustomButton(
                                text: 'Send OTP',
                                isLoading: controller.isForgotLoading.value,
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    controller.forgotPassword();
                                  }
                                },
                              )),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => Get.back(),
                                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                  label: const Text('Back to Sign In'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF4FC3F7),
                                    textStyle: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}
