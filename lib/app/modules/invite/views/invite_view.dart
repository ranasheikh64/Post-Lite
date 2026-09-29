import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/invite_controller.dart';
import '../../../widgets/custom_loader.dart';

class InviteView extends GetView<InviteController> {
  const InviteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Obx(
              () => controller.isLoading.value
                  ? const Text(
                      'Processing your invitation...',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
