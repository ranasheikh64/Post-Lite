import 'package:flutter/material.dart';

class DynamicTableHeader extends StatelessWidget {
  final String title;
  final int activeCount;

  const DynamicTableHeader({
    super.key,
    required this.title,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFFE2E8F0),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6C37).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF6C37).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6C37),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$activeCount active',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6C37),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            _getSubtitle(),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubtitle() {
    if (title.toLowerCase().contains('param')) {
      return 'Query parameters appended to request URL';
    }
    if (title.toLowerCase().contains('header')) {
      return 'HTTP headers sent with request';
    }
    return 'Key-value pairs';
  }
}
