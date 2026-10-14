import 'package:flutter/material.dart';

class EventsTableHeader extends StatelessWidget {
  final int listeningCount;

  const EventsTableHeader({super.key, required this.listeningCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              const Text(
                'Events',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFFE0E4F0),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6C37).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$listeningCount listening',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6C37),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: const Color(0xFF181A25),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'EVENT NAME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Color(0xFF888EA8),
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Center(
                  child: Text(
                    'LISTEN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Color(0xFF888EA8),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Color(0xFF888EA8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 32),
            ],
          ),
        ),
      ],
    );
  }
}
