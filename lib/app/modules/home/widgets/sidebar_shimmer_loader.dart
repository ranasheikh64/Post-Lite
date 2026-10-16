import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SidebarShimmerLoader extends StatelessWidget {
  const SidebarShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E2133),
      highlightColor: const Color(0xFF2C3149),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 6,
        itemBuilder: (context, index) {
          final isOdd = index.isOdd;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Icon(
                  isOdd ? Icons.description_outlined : Icons.folder_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    margin: EdgeInsets.only(right: isOdd ? 80 : 40),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
