import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool   _isLoading  = true;
  List   _users      = [];
  int    _total      = 0;
  String _roleFilter = '';
  String _search     = '';
  final  _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      String q = '/users?limit=50';
      if (_roleFilter.isNotEmpty) q += '&role=$_roleFilter';
      if (_search.isNotEmpty)     q += '&search=$_search';

      final res = await ApiService.adminGet(q);
      setState(() {
        _users    = res['users'] as List;
        _total    = res['total'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Failed to load users: $e', Colors.red);
    }
  }

  Future<void> _updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await ApiService.adminPatch('/users/$userId', data);
      _load();
      _showSnack('User updated successfully.', Colors.green);
    } catch (e) {
      _showSnack('Update failed: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Users ($_total)'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: const Color(0xFF1A237E),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) { _search = v; _load(); },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search name or email...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'free', 'membership'].map((f) {
                      final active = f == 'All' ? _roleFilter.isEmpty : f == _roleFilter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f[0].toUpperCase() + f.substring(1)),
                          selected: active,
                          onSelected: (_) { _roleFilter = f == 'All' ? '' : f; _load(); },
                          selectedColor: Colors.white,
                          labelStyle: TextStyle(color: active ? const Color(0xFF1A237E) : Colors.white),
                          backgroundColor: Colors.transparent,
                          side: BorderSide(color: Colors.white.withOpacity(0.5)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _users.isEmpty
                        ? Center(child: Text('No users found.', style: TextStyle(color: Colors.grey.shade600)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _users.length,
                            itemBuilder: (_, i) => _UserTile(
                              user: _users[i] as Map<String, dynamic>,
                              onUpdate: _updateUser,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final Function(String, Map<String, dynamic>) onUpdate;
  const _UserTile({required this.user, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final role   = user['role']     as String? ?? 'free';
    final active = user['isActive'] as bool?   ?? true;
    final id     = user['_id']      as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _roleColor(role).withOpacity(0.15),
          child: Text(
            (user['name'] as String? ?? '?').isNotEmpty ? (user['name'] as String)[0].toUpperCase() : '?',
            style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(children: [
          Expanded(child: Text(user['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
          _RoleBadge(role: role),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(user['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(active ? Icons.check_circle : Icons.block,
                  size: 12, color: active ? Colors.green : Colors.red),
              const SizedBox(width: 4),
              Text(active ? 'Active' : 'Deactivated',
                  style: TextStyle(fontSize: 11, color: active ? Colors.green : Colors.red)),
            ]),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (action) {
            switch (action) {
              case 'upgrade':
                onUpdate(id, {'role': 'membership', 'membershipStatus': 'active'});
                break;
              case 'downgrade':
                onUpdate(id, {'role': 'free', 'membershipStatus': 'inactive'});
                break;
              case 'deactivate':
                onUpdate(id, {'isActive': false});
                break;
              case 'activate':
                onUpdate(id, {'isActive': true});
                break;
            }
          },
          itemBuilder: (_) => [
            if (role == 'free')
              const PopupMenuItem(value: 'upgrade',
                  child: Row(children: [Icon(Icons.workspace_premium, size: 18), SizedBox(width: 8), Text('Upgrade to Member')])),
            if (role == 'membership')
              const PopupMenuItem(value: 'downgrade',
                  child: Row(children: [Icon(Icons.person_outline, size: 18), SizedBox(width: 8), Text('Set as Free')])),
            PopupMenuItem(
              value: active ? 'deactivate' : 'activate',
              child: Row(children: [
                Icon(active ? Icons.block : Icons.check_circle,
                    size: 18, color: active ? Colors.red : Colors.green),
                const SizedBox(width: 8),
                Text(active ? 'Deactivate' : 'Activate',
                    style: TextStyle(color: active ? Colors.red : Colors.green)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'membership': return Colors.purple;
      case 'admin':      return Colors.red;
      default:           return Colors.orange;
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (role) {
      case 'membership': color = Colors.purple; icon = Icons.workspace_premium; break;
      case 'admin':      color = Colors.red;    icon = Icons.admin_panel_settings; break;
      default:           color = Colors.orange; icon = Icons.person; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(role[0].toUpperCase() + role.substring(1),
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}