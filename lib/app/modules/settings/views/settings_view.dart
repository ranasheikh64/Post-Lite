import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  SettingsView({Key? key}) : super(key: key);

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red.withOpacity(0.3))),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              controller.deleteAccount();
            },
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner': return 'Owner';
      case 'admin': return 'Admin';
      case 'editor': return 'Editor';
      case 'viewer': return 'Viewer';
      default: return role.capitalizeFirst ?? role;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'owner': return const Color(0xFFFF9800);
      case 'admin': return const Color(0xFFFF6D3B);
      case 'editor': return const Color(0xFF6C63FF);
      case 'viewer': return const Color(0xFF3ECFCF);
      default: return Colors.white54;
    }
  }

  String _avatarInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13), // Deep dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Profile & Settings',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D3B)));
        }

        final user = controller.currentUser.value;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.white.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text('Failed to load profile.', style: TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          );
        }

        final workspaces = controller.workspaceController.workspaces;
        final name = user['name'] as String? ?? 'Unknown User';
        final email = user['email'] as String? ?? '';
        final initials = _avatarInitials(name);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // ── App Brand Header with Glow ─────────────────────────────
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle glow behind logo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E88E5).withOpacity(0.2),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Image.asset(
                              'assets/icons/main_logo.png',
                              width: 80,
                              height: 80,
                              errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.api_rounded, size: 64, color: Color(0xFF1E88E5)),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Post-Lite',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88E5).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'API Client',
                                style: TextStyle(color: Color(0xFF64B5F6), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Profile Card (Glassmorphism) ─────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2A2D3E).withOpacity(0.8),
                          const Color(0xFF1F212E).withOpacity(0.8),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar with Gradient
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6D3B), Color(0xFFFF4081)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6D3B).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.email_outlined, color: Colors.white54, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    email,
                                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Teams Section ────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.workspaces_outline, color: Colors.white70, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'My Teams',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.3)),
                        ),
                        child: Text(
                          '${workspaces.length} Total',
                          style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  workspaces.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1C29),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05), style: BorderStyle.solid),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.group_off_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
                                const SizedBox(height: 12),
                                const Text(
                                  'You are not in any team yet.',
                                  style: TextStyle(color: Colors.white54, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: workspaces.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final ws = workspaces[index] as Map;
                            final wsName = ws['name'] as String? ?? 'Unnamed Workspace';
                            final members = ws['members'] as List? ?? [];
                            final memberCount = members.length;
                            final role = controller.userRoleIn(ws);
                            final wsInitials = wsName.isNotEmpty ? wsName[0].toUpperCase() : 'W';
                            final rColor = _roleColor(role);

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1C29),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Workspace initial icon
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: rColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: rColor.withOpacity(0.2)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        wsInitials,
                                        style: TextStyle(
                                          color: rColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Name & member count
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          wsName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.people_alt_outlined, color: Colors.white.withOpacity(0.4), size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$memberCount Member${memberCount == 1 ? '' : 's'}',
                                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Role badge
                                  if (role.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: rColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: rColor.withOpacity(0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            role == 'owner' ? Icons.stars_rounded 
                                            : role == 'admin' ? Icons.admin_panel_settings 
                                            : Icons.verified_user, 
                                            color: rColor, size: 14
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _roleLabel(role),
                                            style: TextStyle(
                                              color: rColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),

                  const SizedBox(height: 48),

                  // ── Actions ──────────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6D3B), Color(0xFFFF4081)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6D3B).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => controller.logout(),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Logout securely',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        backgroundColor: Colors.redAccent.withOpacity(0.05),
                      ),
                      onPressed: () => _showDeleteConfirmation(context),
                      icon: const Icon(Icons.delete_forever_rounded, size: 20),
                      label: const Text(
                        'Delete Account',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

