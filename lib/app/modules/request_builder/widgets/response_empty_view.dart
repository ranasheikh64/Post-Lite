import 'package:flutter/material.dart';

class ResponseEmptyView extends StatelessWidget {
  const ResponseEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.send_rounded,
            color: Color(0xFF2A2D3E),
            size: 40,
          ),
          SizedBox(height: 12),
          Text(
            'Hit Send to get a response',
            style: TextStyle(
              color: Color(0xFF555870),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
