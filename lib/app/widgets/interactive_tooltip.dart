import 'package:flutter/material.dart';
import 'dart:async';

class InteractiveTooltip extends StatefulWidget {
  final Widget child;
  final Widget popup;
  final Duration hoverDelay;

  const InteractiveTooltip({
    Key? key,
    required this.child,
    required this.popup,
    this.hoverDelay = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  _InteractiveTooltipState createState() => _InteractiveTooltipState();
}

class _InteractiveTooltipState extends State<InteractiveTooltip> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  bool _isHovering = false;
  bool _isHoveringPopup = false;
  Timer? _hideTimer;

  void _show() {
    _hideTimer?.cancel();
    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
  }

  void _hide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.hoverDelay, () {
      if (!_isHovering && !_isHoveringPopup && _overlayController.isShowing) {
        _overlayController.hide();
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) {
          return CompositedTransformFollower(
            link: _layerLink,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 8),
            child: Align(
              alignment: Alignment.topLeft,
              child: MouseRegion(
                onEnter: (_) {
                  _isHoveringPopup = true;
                  _show();
                },
                onExit: (_) {
                  _isHoveringPopup = false;
                  _hide();
                },
                child: Material(
                  color: Colors.transparent,
                  child: widget.popup,
                ),
              ),
            ),
          );
        },
        child: MouseRegion(
          onEnter: (_) {
            _isHovering = true;
            _show();
          },
          onExit: (_) {
            _isHovering = false;
            _hide();
          },
          child: widget.child,
        ),
      ),
    );
  }
}
