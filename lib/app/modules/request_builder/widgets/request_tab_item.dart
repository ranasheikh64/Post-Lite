import 'package:flutter/material.dart';
import '../../../../app/core/theme/app_theme.dart';

class RequestTabItem extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isActive;
  final bool isUnsaved;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final Function(TapDownDetails details) onSecondaryTap;

  const RequestTabItem({
    Key? key,
    required this.request,
    required this.isActive,
    required this.isUnsaved,
    required this.onTap,
    required this.onClose,
    required this.onSecondaryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final kind = (request['requestKind'] ?? '').toString().toLowerCase();
    final isSocket = kind == 'socketio';
    final isWs = kind == 'websocket';
    final label = isSocket ? 'IO' : (isWs ? 'WS' : (request['method'] ?? 'GET'));
    final labelColor = isSocket
        ? Colors.orange
        : (isWs ? Colors.purple : AppTheme.getMethodColor(label));
    final name = request['name'] ?? 'Unnamed';

    return GestureDetector(
      onSecondaryTapDown: onSecondaryTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2A2D3E) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isUnsaved) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF9800),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(Icons.close, size: 14, color: Colors.white38),
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
