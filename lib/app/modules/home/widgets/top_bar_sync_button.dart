import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/workspace_controller.dart';

class TopBarSyncButton extends StatefulWidget {
  const TopBarSyncButton({super.key});

  @override
  State<TopBarSyncButton> createState() => _TopBarSyncButtonState();
}

class _TopBarSyncButtonState extends State<TopBarSyncButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wsCtrl = Get.find<WorkspaceController>();

    return Tooltip(
      message: 'Sync',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _animController.repeat();
            wsCtrl.syncWorkspace().whenComplete(() {
              if (mounted) _animController.stop();
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Obx(() {
              final isSyncing = wsCtrl.isSyncing.value;
              if (isSyncing && !_animController.isAnimating) {
                _animController.repeat();
              }
              return RotationTransition(
                turns: _animController,
                child: Icon(
                  Icons.sync_rounded,
                  size: 18,
                  color: isSyncing
                      ? const Color(0xFFFF6C37)
                      : const Color(0xFF9E9E9E),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
