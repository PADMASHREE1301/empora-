import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

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
        _users     = res['users'] as List;
        _total     = res['total'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Failed to load users: $e', AppTheme.adminError);
    }
  }

  Future<void> _updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await ApiService.adminPatch('/users/$userId', data);
      _load();
      _showSnack('User updated successfully.', AppTheme.adminSuccess);
    } catch (e) {
      _showSnack('Update failed: $e', AppTheme.adminError);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.adminTheme,
      child: Scaffold(
        backgroundColor: AppTheme.adminBg,
        appBar: AppBar(
          title: Text('Users ($_total)'),
          backgroundColor: AppTheme.adminCard,
          foregroundColor: AppTheme.adminTextPrimary,
          elevation: 0,
        ),
        body: Column(
          children: [
            // ── Filter bar ────────────────────────────────────────────────
            Container(
              color: AppTheme.adminBg,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) { _search = v; _load(); },
                    style: TextStyle(color: AppTheme.adminTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search name or email...',
                      hintStyle: TextStyle(color: AppTheme.adminTextSecond),
                      prefixIcon: Icon(Icons.search, color: AppTheme.adminTextSecond),
                      filled: true,
                      fillColor: AppTheme.adminCardAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.adminBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.adminBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.adminAccent, width: 2),
                      ),
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
                            onSelected: (_) {
                              setState(() => _roleFilter = f == 'All' ? '' : f);
                              _load();
                            },
                            selectedColor: AppTheme.adminAccent.withValues(alpha: 0.25),
                            labelStyle: TextStyle(
                              color: active ? AppTheme.adminAccent : AppTheme.adminTextPrimary,
                              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                            ),
                            backgroundColor: AppTheme.adminCardAlt,
                            side: BorderSide(
                              color: active ? AppTheme.adminAccent : AppTheme.adminBorder,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── User list ──────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _users.isEmpty
                          ? Center(
                              child: Text(
                                'No users found.',
                                style: TextStyle(color: AppTheme.adminTextSecond),
                              ),
                            )
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
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final Function(String, Map<String, dynamic>) onUpdate;
  const _UserTile({required this.user, required this.onUpdate});

  Color _roleColor(String role) {
    switch (role) {
      case 'membership': return Colors.purple;
      case 'admin':      return Colors.red;
      default:           return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role   = user['role']     as String? ?? 'free';
    final active = user['isActive'] as bool?   ?? true;
    final id     = user['_id']      as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.adminCardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.adminBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _roleColor(role).withValues(alpha: 0.15),
          child: Text(
            (user['name'] as String? ?? '?').isNotEmpty
                ? (user['name'] as String)[0].toUpperCase()
                : '?',
            style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(children: [
          Expanded(
            child: Text(
              user['name'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.adminTextPrimary,
              ),
            ),
          ),
          _RoleBadge(role: role),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(user['email'] ?? '',
                style: TextStyle(color: AppTheme.adminTextSecond, fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(
                active ? Icons.check_circle : Icons.block,
                size: 12,
                color: active ? AppTheme.adminSuccess : AppTheme.adminError,
              ),
              const SizedBox(width: 4),
              Text(
                active ? 'Active' : 'Deactivated',
                style: TextStyle(
                  fontSize: 11,
                  color: active ? AppTheme.adminSuccess : AppTheme.adminError,
                ),
              ),
            ]),
          ],
        ),
        trailing: Theme(
          data: AppTheme.adminTheme,
          child: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppTheme.adminTextSecond),
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
                PopupMenuItem(
                  value: 'upgrade',
                  child: Row(children: [
                    Icon(Icons.workspace_premium, size: 18, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text('Upgrade to Member',
                        style: TextStyle(color: AppTheme.adminTextPrimary)),
                  ]),
                ),
              if (role == 'membership')
                PopupMenuItem(
                  value: 'downgrade',
                  child: Row(children: [
                    Icon(Icons.person_outline, size: 18, color: AppTheme.adminTextSecond),
                    const SizedBox(width: 8),
                    Text('Set as Free',
                        style: TextStyle(color: AppTheme.adminTextPrimary)),
                  ]),
                ),
              PopupMenuItem(
                value: active ? 'deactivate' : 'activate',
                child: Row(children: [
                  Icon(
                    active ? Icons.block : Icons.check_circle,
                    size: 18,
                    color: active ? AppTheme.adminError : AppTheme.adminSuccess,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    active ? 'Deactivate' : 'Activate',
                    style: TextStyle(
                      color: active ? AppTheme.adminError : AppTheme.adminSuccess,
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
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
      case 'membership':
        color = Colors.purple;
        icon  = Icons.workspace_premium;
        break;
      case 'admin':
        color = Colors.red;
        icon  = Icons.admin_panel_settings;
        break;
      default:
        color = Colors.orange;
        icon  = Icons.person;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          role[0].toUpperCase() + role.substring(1),
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ]),
    );
  }
}