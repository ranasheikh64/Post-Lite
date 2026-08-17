import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:get/get.dart';
import '../modules/home/workspace_controller.dart';

class VariableHoverCard extends StatefulWidget {
  final String varName;
  final VariableDetail? detail;

  const VariableHoverCard({
    Key? key,
    required this.varName,
    this.detail,
  }) : super(key: key);

  @override
  _VariableHoverCardState createState() => _VariableHoverCardState();
}

class _VariableHoverCardState extends State<VariableHoverCard> {
  late TextEditingController _controller;
  Timer? _debounce;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.detail?.value ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (widget.detail != null) {
        Get.find<WorkspaceController>().updateSingleVariable(widget.detail!, value);
      }
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _controller.text));
    setState(() {
      _isCopied = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isResolved = widget.detail != null;
    final sourceName = isResolved ? (widget.detail!.sourceName.isNotEmpty ? widget.detail!.sourceName : 'Collection') : 'Unresolved';

    return Container(
      width: 400,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.varName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onChanged,
                    maxLines: null,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: isResolved ? 'Enter value' : 'Unresolved variable',
                      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      isDense: true,
                    ),
                  ),
                ),
                if (isResolved)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 2),
                    child: IconButton(
                      icon: Icon(
                        _isCopied ? Icons.check : Icons.copy,
                        size: 14,
                        color: _isCopied ? Colors.green : Colors.grey[400],
                      ),
                      onPressed: _copyToClipboard,
                      splashRadius: 16,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isResolved ? Colors.orange[800] : Colors.red[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(isResolved ? 'C' : '!', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Text(sourceName, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }
}
