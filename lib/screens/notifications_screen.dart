// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:empora/services/api_service.dart';
import 'package:empora/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool   _loading = true;
  List   _notifications = [];
  int    _unreadCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getNotifications();
      setState(() {
        _notifications = res['notifications'] as List? ?? [];
        _unreadCount   = res['unreadCount']   as int?  ?? 0;
        _loading       = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      setState(() {
        _unreadCount = 0;
        for (var n in _notifications) {
          (n as Map<String, dynamic>)['isRead'] = true;
        }
      });
    } catch (_) {}
  }

  Future<void> _markRead(String id, int index) async {
    try {
      await ApiService.markNotificationRead(id);
      setState(() {
        (_notifications[index] as Map<String, dynamic>)['isRead'] = true;
        if (_unreadCount > 0) _unreadCount--;
      });
    } catch (_) {}
  }

  Future<void> _delete(String id) async {
    try {
      await ApiService.deleteNotification(id);
      setState(() {
        _notifications.removeWhere((n) => (n as Map<String, dynamic>)['_id'] == id);
      });
    } catch (_) {}
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Clear All', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: Text('Delete all notifications?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.clearAllNotifications();
      setState(() { _notifications = []; _unreadCount = 0; });
    } catch (_) {}
  }

  Color _getColor(String? color) {
    if (color == null) return AppTheme.primary;
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'welcome':            return Icons.celebration_rounded;
      case 'membership_expiry':  return Icons.warning_amber_rounded;
      case 'membership_expired': return Icons.error_rounded;
      case 'payment':            return Icons.workspace_premium_rounded;
      case 'profile_complete':   return Icons.person_rounded;
      case 'ai_tip':             return Icons.auto_awesome_rounded;
      default:                   return Icons.notifications_rounded;
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final dt   = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A6B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Text('Notifications', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: Text('$_unreadCount', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        actions: [
          if (_notifications.isNotEmpty) ...[
            if (_unreadCount > 0)
              TextButton(
                onPressed: _markAllRead,
                child: Text('Read all', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70),
              onPressed: _clearAll,
              tooltip: 'Clear all',
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(_error!, style: GoogleFonts.inter(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : _notifications.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.notifications_none_rounded, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No notifications yet', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('You\'ll see updates and alerts here', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final n      = _notifications[index] as Map<String, dynamic>;
                          final id     = n['_id']     as String? ?? '';
                          final isRead = n['isRead']  as bool?   ?? false;
                          final type   = n['type']    as String?;
                          final color  = _getColor(n['color'] as String?);

                          return Dismissible(
                            key: Key(id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_rounded, color: Colors.red),
                            ),
                            onDismissed: (_) => _delete(id),
                            child: GestureDetector(
                              onTap: () => !isRead ? _markRead(id, index) : null,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isRead ? Colors.white : color.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isRead ? const Color(0xFFE8EAF0) : color.withOpacity(0.25),
                                    width: isRead ? 1 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  // Icon
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                                    child: Icon(_getIcon(type), color: color, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  // Content
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(
                                        child: Text(
                                          n['title'] as String? ?? '',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                            color: const Color(0xFF1A1A2E),
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8, height: 8,
                                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                        ),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(
                                      n['message'] as String? ?? '',
                                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _timeAgo(n['createdAt'] as String?),
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400),
                                    ),
                                  ])),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}