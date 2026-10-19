import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/request_builder_controller.dart';

class ResponseHeaderActions extends StatelessWidget {
  const ResponseHeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: () => _showSaveDialog(context, controller),
          icon: const Icon(Icons.save, size: 14),
          label: const Text('Save Response', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: controller.responseData.value)),
          icon: const Icon(Icons.copy, size: 14),
          tooltip: 'Copy Response',
          color: Colors.grey,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 16,
        ),
      ],
    );
  }

  void _showSaveDialog(BuildContext context, RequestBuilderController controller) {
    final nameCtrl = TextEditingController();
    Get.defaultDialog(
      title: 'Save Response',
      content: TextField(
        controller: nameCtrl,
        decoration: const InputDecoration(
          labelText: 'Response Name (e.g. 200 OK)',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (nameCtrl.text.isNotEmpty) {
          controller.saveResponse(nameCtrl.text);
          Get.back();
        }
      },
    );
  }
}
