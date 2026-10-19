import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/widgets/custom_json_viewer.dart';
import '../controllers/request_builder_controller.dart';
import 'response_empty_view.dart';
import 'response_header_bar.dart';
import 'response_loading_view.dart';

class ResponsePanel extends StatelessWidget {
  const ResponsePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestBuilderController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ResponseHeaderBar(),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const ResponseLoadingView();
            }

            if (controller.responseStatus.value == 0 && controller.responseData.value.isEmpty) {
              return const ResponseEmptyView();
            }

            return Container(
              padding: const EdgeInsets.all(16),
              child: _buildResponseContent(controller.responseData.value),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildResponseContent(String data) {
    final trimmed = data.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(data);
        return CustomJsonViewer(jsonObj: decoded);
      } catch (_) {}
    }
    return SingleChildScrollView(
      child: SelectableText(
        data,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }
}
