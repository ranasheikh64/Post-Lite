import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:postmanclone/app/data/providers/api_service.dart';
import '../../controllers/workspace_controller.dart';

void showTeamSettingsDialog(BuildContext context, WorkspaceController workspaceController) {
  final wsId = workspaceController.selectedWorkspaceId.value;
  if (wsId == null) return;
  final ws = workspaceController.workspaces.firstWhere((w) => w['_id'] == wsId, orElse: () => null);
  if (ws == null) return;

  showDialog(
    context: context,
    builder: (context) => _TeamSettingsDialogContent(
      wsId: wsId,
      workspaceController: workspaceController,
    ),
  );
}

class _TeamSettingsDialogContent extends StatefulWidget {
  final String wsId;
  final WorkspaceController workspaceController;

  const _TeamSettingsDialogContent({
    required this.wsId,
    required this.workspaceController,
  });

  @override
  State<_TeamSettingsDialogContent> createState() => _TeamSettingsDialogContentState();
}

class _TeamSettingsDialogContentState extends State<_TeamSettingsDialogContent> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _selectedRole = 'viewer';
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isSearching = true);
    try {
      final results = await _apiService.searchUsers('');
      if (mounted) setState(() { _searchResults = results; _isSearching = false; });
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await _apiService.searchUsers(query.trim());
        if (mounted) setState(() { _searchResults = results; _isSearching = false; });
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _inviteUser(Map<String, dynamic> user) async {
    await widget.workspaceController.addWorkspaceMember(
      widget.wsId, user['email'], _selectedRole,
    );
    _searchController.clear();
    setState(() { _searchResults = []; });
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setDialogState) {
      final currentWs = widget.workspaceController.workspaces
          .firstWhere((w) => w['_id'] == widget.wsId, orElse: () => {});
      final members = (currentWs['members'] as List? ?? []).toList();
      final existingEmails = members.map((m) => m['user']['email'] as String? ?? '').toSet();

      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 700),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 20)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.group_rounded, color: Color(0xFFE65100), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentWs['name'] ?? 'Team',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            '${members.length} member${members.length != 1 ? 's' : ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Invite section
                      const Text(
                        'INVITE MEMBER',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE65100), letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                              onChanged: (v) {
                                _onSearchChanged(v);
                                setDialogState(() {});
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by name or email...',
                                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                                filled: true,
                                fillColor: const Color(0xFF252525),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 18),
                                suffixIcon: _isSearching
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFE65100))),
                                      )
                                    : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: const Color(0xFFE65100).withOpacity(0.5), width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(10)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRole,
                                dropdownColor: const Color(0xFF252525),
                                icon: const Icon(Icons.expand_more, size: 16, color: Colors.grey),
                                style: const TextStyle(fontSize: 13, color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                  DropdownMenuItem(value: 'editor', child: Text('Editor')),
                                  DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => _selectedRole = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Search results list
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFE65100))),
                        )
                      else if (_searchResults.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF202020),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: Scrollbar(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, i) {
                                final user = _searchResults[i];
                                final email = user['email'] as String? ?? '';
                                final name = user['name'] as String? ?? '';
                                final isAlreadyMember = existingEmails.contains(email);
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFFE65100).withOpacity(0.15),
                                    child: Text(
                                      (name.isNotEmpty ? name[0] : email[0]).toUpperCase(),
                                      style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                                  subtitle: Text(email, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  trailing: isAlreadyMember
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(20)),
                                          child: Text('Member', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                                        )
                                      : TextButton.icon(
                                          onPressed: () async {
                                            await _inviteUser(user);
                                            setDialogState(() {});
                                            _loadAllUsers();
                                          },
                                          icon: const Icon(Icons.add, size: 14, color: Color(0xFFE65100)),
                                          label: const Text('Invite', style: TextStyle(color: Color(0xFFE65100), fontSize: 12, fontWeight: FontWeight.w600)),
                                          style: TextButton.styleFrom(
                                            backgroundColor: const Color(0xFFE65100).withOpacity(0.1),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ),
                      ] else
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Text('No users found', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ),

                      const SizedBox(height: 28),

                      // Members section
                      Row(
                        children: [
                          const Text(
                            'TEAM MEMBERS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE65100), letterSpacing: 1.2),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${members.length}', style: const TextStyle(color: Color(0xFFE65100), fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (members.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.group_add_outlined, color: Colors.grey[700], size: 40),
                              const SizedBox(height: 8),
                              Text('No members yet', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                              Text('Search above to invite users', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                            ],
                          ),
                        )
                      else
                        ...members.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final member = entry.value;
                          final name = member['user']['name'] ?? '';
                          final email = member['user']['email'] ?? '';
                          final initial = (name.isNotEmpty ? name[0] : (email.isNotEmpty ? email[0] : '?')).toUpperCase();
                          return Container(
                            margin: EdgeInsets.only(bottom: idx < members.length - 1 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF252525),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFFE65100).withOpacity(0.15),
                                  child: Text(initial, style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name.isNotEmpty ? name : email, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                                      if (name.isNotEmpty) Text(email, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: member['role'] ?? 'viewer',
                                      dropdownColor: const Color(0xFF252525),
                                      icon: const Icon(Icons.expand_more, size: 14, color: Colors.grey),
                                      style: const TextStyle(fontSize: 13, color: Colors.white),
                                      items: const [
                                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                        DropdownMenuItem(value: 'editor', child: Text('Editor')),
                                        DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                                      ],
                                      onChanged: (val) async {
                                        if (val != null) {
                                          await widget.workspaceController.updateWorkspaceMemberRole(widget.wsId, member['user']['_id'], val);
                                          setDialogState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                                  tooltip: 'Remove',
                                  splashRadius: 18,
                                  onPressed: () async {
                                    await widget.workspaceController.removeWorkspaceMember(widget.wsId, member['user']['_id']);
                                    setDialogState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
                ),
                child: Row(
                  children: [
                    if (widget.workspaceController.userRoleInWorkspace.value == 'owner')
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1E1E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              title: const Text('Delete Team', style: TextStyle(color: Colors.white)),
                              content: const Text('This action cannot be undone.', style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
                                TextButton(
                                  onPressed: () {
                                    widget.workspaceController.deleteWorkspace(widget.wsId);
                                    Get.back();
                                    Get.back();
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_forever, size: 16, color: Colors.redAccent),
                        label: const Text('Delete Team', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.06),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Close', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
