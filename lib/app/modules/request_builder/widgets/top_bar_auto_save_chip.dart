import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/request_builder_controller.dart';

class TopBarAutoSaveChip extends StatelessWidget {
  const TopBarAutoSaveChip({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();

    return Obx(() {
      final isAuto = controller.autoSaveEnabled.value;
      final isSaving = controller.isSaving.value;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6C37)),
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Saving...',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFF6C37),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Tooltip(
            message: 'Auto-save changes to cloud backend for your team',
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              height: 32,
              decoration: BoxDecoration(
                color: isAuto
                    ? const Color(0xFFFF6C37).withValues(alpha: 0.12)
                    : const Color(0xFF222533),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isAuto
                      ? const Color(0xFFFF6C37).withValues(alpha: 0.4)
                      : Colors.white12,
                ),
              ),
              child: InkWell(
                onTap: controller.toggleAutoSave,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAuto ? Icons.cloud_done_rounded : Icons.cloud_outlined,
                        size: 14,
                        color: isAuto ? const Color(0xFFFF6C37) : Colors.white38,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Auto Save',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isAuto ? FontWeight.w600 : FontWeight.normal,
                          color: isAuto ? const Color(0xFFFF6C37) : Colors.white70,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.65,
                        child: Switch(
                          value: isAuto,
                          activeThumbColor: const Color(0xFFFF6C37),
                          onChanged: (val) => controller.toggleAutoSave(val),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    });
  }
}
