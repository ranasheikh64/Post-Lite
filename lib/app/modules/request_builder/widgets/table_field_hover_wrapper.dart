import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/modules/home/controllers/workspace_controller.dart';
import 'package:postmanclone/app/modules/request_builder/controllers/request_builder_controller.dart';
import 'package:postmanclone/app/widgets/interactive_tooltip.dart';
import 'package:postmanclone/app/widgets/variable_hover_card.dart';

class TableFieldHoverWrapper extends StatelessWidget {
  final TextEditingController controller;
  final Widget child;

  const TableFieldHoverWrapper({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final text = controller.text;
        final matches = RegExp(r'\{\{([^}]+)\}\}').allMatches(text);
        if (matches.isEmpty) return child;

        return InteractiveTooltip(
          enabled: true,
          popup: Obx(() {
            final ws = Get.find<WorkspaceController>();
            final reqCtrl = Get.find<RequestBuilderController>();
            final reqId = reqCtrl.currentRequestId.value ?? '';
            ws.collections.isEmpty;
            final vars = ws.getVariableDetailsForRequest(reqId);
            final uniqueNames = matches.map((m) => m.group(1)!).toSet();

            final cards = uniqueNames.map((name) =>
              VariableHoverCard(varName: name, detail: vars[name], requestId: reqId)
            ).toList();

            if (cards.isEmpty) return const SizedBox.shrink();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cards,
            );
          }),
          child: child,
        );
      },
    );
  }
}
