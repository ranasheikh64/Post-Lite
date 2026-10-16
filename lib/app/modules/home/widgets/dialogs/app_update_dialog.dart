import 'dart:io' show Platform, Process;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../widgets/custom_button.dart';

class AppUpdateDialog extends StatelessWidget {
  final String version;
  final List<dynamic> highlights;
  final String downloadUrl;

  const AppUpdateDialog({
    Key? key,
    required this.version,
    required this.highlights,
    required this.downloadUrl,
  }) : super(key: key);

  static void show({
    required String version,
    required List<dynamic> highlights,
    required String downloadUrl,
  }) {
    Get.dialog(
      AppUpdateDialog(version: version, highlights: highlights, downloadUrl: downloadUrl),
      barrierDismissible: true,
    );
  }

  void _openDownloadUrl() {
    try {
      if (!kIsWeb) {
        if (Platform.isMacOS) Process.run('open', [downloadUrl]);
        if (Platform.isWindows) Process.run('cmd', ['/c', 'start', downloadUrl]);
        if (Platform.isLinux) Process.run('xdg-open', [downloadUrl]);
      }
    } catch (_) {}
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1B1E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2A2E44)),
      ),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6C37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.system_update_alt, color: Color(0xFFFF6C37), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('New Update Available', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('Version $version is ready to download', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.white54), onPressed: () => Get.back()),
              ],
            ),
            const SizedBox(height: 14),
            const Text("What's New:", style: TextStyle(color: Color(0xFFFF6C37), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF131522), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: highlights.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text('• ${highlights[i]}', style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => Get.back(), child: const Text('Later', style: TextStyle(color: Colors.white54)))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: CustomButton(text: 'Download Update', height: 38, onPressed: _openDownloadUrl)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
