import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/app_theme.dart';
import '../controllers/request_builder_controller.dart';
import 'response_loading_spinner.dart';

class ResponseLoadingView extends StatelessWidget {
  const ResponseLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();
    final method = controller.method.value.toUpperCase();
    final methodColor = AppTheme.getMethodColor(method);
    final urlText = controller.url.value.isEmpty ? 'Waiting...' : controller.url.value;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF282C3F)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 8)),
            BoxShadow(color: AppTheme.primary.withValues(alpha: 0.06), blurRadius: 24, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ResponseLoadingSpinner(),
            const SizedBox(height: 16),
            const Text(
              'Sending Request',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
            ),
            const SizedBox(height: 8),
            _buildUrlPill(method, methodColor, urlText),
            const SizedBox(height: 12),
            _buildLiveTimer(controller),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: controller.cancelRequest,
              icon: const Icon(Icons.close_rounded, size: 13),
              label: const Text('Cancel request', style: TextStyle(fontSize: 11.5)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white60,
                side: const BorderSide(color: Colors.white12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlPill(String method, Color methodColor, String urlText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            method,
            style: TextStyle(
              color: methodColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              urlText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTimer(RequestBuilderController controller) {
    return Obx(() {
      final ms = controller.responseTime.value;
      final formattedTime = ms >= 1000
          ? '${(ms / 1000).toStringAsFixed(2)} s'
          : '$ms ms';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6C37),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              formattedTime,
              style: const TextStyle(
                color: Color(0xFFFF6C37),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    });
  }
}
