import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'settings_controller.dart';

class SettingsView extends StatelessWidget {
  SettingsView({Key? key}) : super(key: key);

  final SettingsController settingsController = Get.put(SettingsController());

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to permanently delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              settingsController.deleteAccount();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Obx(() {
            final user = settingsController.currentUser.value;
            
            if (settingsController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (user == null) {
              return const Center(child: Text('Failed to load profile.'));
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  user['name'] ?? 'No Name',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  user['email'] ?? 'No Email',
                  style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => settingsController.logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
