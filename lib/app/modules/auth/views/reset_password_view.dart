import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/widgets/custom_button.dart';
import 'package:postmanclone/app/widgets/custom_textfield.dart';
import '../controllers/auth_controller.dart';
import 'auth_widgets.dart';

class ResetPasswordView extends GetView<AuthController> {
  ResetPasswordView({Key? key}) : super(key: key);

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
                                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.1),
                                    border: Border.all(color: const Color(0xFF4FC3F7).withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF4FC3F7), size: 26),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Enter OTP & New Password',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Enter the 6-digit code sent to your email and set a new password.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              _OtpField(controller: controller.otpController),
                              const SizedBox(height: 14),
                              CustomTextField(
                                controller: controller.passwordController,
                                obscureText: true,
                                hintText: 'New Password (min. 6 characters)',
                                prefixIcon: const Icon(Icons.lock_outline),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Password is required';
                                  if (v.trim().length < 6) return 'Minimum 6 characters required';
                                  return null;
                                },
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                              ),
                              const SizedBox(height: 24),
                              Obx(() => CustomButton(
                                text: 'Update Password',
                                isLoading: controller.isResetLoading.value,
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    controller.resetPassword();
                                  }
                                },
                              )),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => Get.back(),
                                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                  label: const Text('Back'),
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

class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  const _OtpField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 10,
        fontFamily: 'monospace',
      ),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: '● ● ● ● ● ●',
        counterText: '',
        prefixIcon: const Icon(Icons.security_rounded),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), letterSpacing: 6, fontSize: 16),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'OTP is required';
        if (v.length != 6) return 'OTP must be exactly 6 digits';
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
