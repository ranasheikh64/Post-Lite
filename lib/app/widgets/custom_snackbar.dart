import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackbar {
  static void show({
    required String title,
    required String message,
    bool isError = false,
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    final displayText = (title.isNotEmpty && title != 'Error' && title != 'Success')
        ? '$title: $message'
        : message;

    Get.rawSnackbar(
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 20, right: 20),
      padding: EdgeInsets.zero,
      duration: const Duration(milliseconds: 2800),
      animationDuration: const Duration(milliseconds: 250),
      isDismissible: true,
      messageText: Align(
        alignment: Alignment.bottomRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1E2B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isError
                    ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                    : const Color(0xFFFF6C37).withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isError ? const Color(0xFFEF4444) : const Color(0xFFFF6C37),
                  ),
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: isError ? const Color(0xFFFFB4B4) : Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
