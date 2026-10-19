import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/request_builder_controller.dart';
import 'response_header_actions.dart';

class ResponseHeaderBar extends StatelessWidget {
  const ResponseHeaderBar({super.key});

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();

    return Obx(() {
      final isLoading = controller.isLoading.value;
      final status = controller.responseStatus.value;
      final hasResponse = status > 0 || controller.responseData.value.isNotEmpty;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1C27),
          border: Border(bottom: BorderSide(color: Color(0xFF2A2D3E))),
        ),
        child: Row(
          children: [
            const Text(
              'Response',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9E9E9E),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 20),
            const Text(
              'History',
              style: TextStyle(fontSize: 12, color: Color(0xFF555870)),
            ),
            const Spacer(),
            if (isLoading) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6C37).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFF6C37).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6C37)),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Sending...',
                      style: TextStyle(
                        color: Color(0xFFFF6C37),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${controller.responseTime.value} ms',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFFF6C37),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '--',
                style: TextStyle(fontSize: 11, color: Color(0xFF666980)),
              ),
            ] else if (hasResponse) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: controller.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: controller.statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  controller.statusMessage.isNotEmpty
                      ? '$status ${controller.statusMessage}'
                      : (status > 0 ? '$status' : 'Error'),
                  style: TextStyle(
                    color: controller.statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${controller.responseTime.value} ms',
                style: const TextStyle(fontSize: 11, color: Color(0xFF666980), fontFamily: 'monospace'),
              ),
              const SizedBox(width: 12),
              Text(
                formatSize(controller.responseSize.value),
                style: const TextStyle(fontSize: 11, color: Color(0xFF666980)),
              ),
              const SizedBox(width: 16),
              const ResponseHeaderActions(),
            ],
          ],
        ),
      );
    });
  }
}
