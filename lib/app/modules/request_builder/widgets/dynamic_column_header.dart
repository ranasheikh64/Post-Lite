import 'package:flutter/material.dart';

class DynamicColumnHeader extends StatelessWidget {
  const DynamicColumnHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      color: const Color(0xFF191B26),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 36),
          Container(width: 1, height: 16, color: const Color(0xFF25293D)),
          const Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Text(
                'KEY',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF888EA8),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 16, color: const Color(0xFF25293D)),
          const Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Text(
                'VALUE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF888EA8),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 16, color: const Color(0xFF25293D)),
          const Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Text(
                'DESCRIPTION',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF888EA8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}
