import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminSubmissionsScreen extends StatefulWidget {
  const AdminSubmissionsScreen({super.key});

  @override
  State<AdminSubmissionsScreen> createState() => _AdminSubmissionsScreenState();
}

class _AdminSubmissionsScreenState extends State<AdminSubmissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isLoading = true;
  List _submissions = [];
  int  _total = 0;

  final _tabs = ['All', 'pending', 'approved', 'rejected', 'completed'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() { if (!_tabCtrl.indexIsChanging) _load(); });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final status = _tabs[_tabCtrl.index];
    final q = status == 'All' ? '/submissions?limit=50' : '/submissions?status=$status&limit=50';
    try {
      final res = await ApiService.adminGet(q);
      setState(() {
        _submissions = res['submissions'] as List;
        _total       = res['total'] as int;
        _isLoading   = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showActionDialog(String id, String action) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(action == 'approve' ? 'Approve Submission' : 'Reject Submission'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(action == 'approve' ? 'Optional admin notes:' : 'Reason for rejection (required):'),
          const SizedBox(height: 12),
          TextField(controller: ctrl, maxLines: 3,
              decoration: InputDecoration(
                hintText: action == 'approve' ? 'Optional notes...' : 'Enter reason...',
                border: const OutlineInputBorder(),
              )),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: action == 'approve' ? Colors.green : Colors.red),
            child: Text(action == 'approve' ? 'Approve' : 'Reject',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (action == 'reject' && ctrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rejection reason is required.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      if (action == 'approve') {
        await ApiService.adminPatch('/submissions/$id/approve', {'adminNotes': ctrl.text});
      } else {
        await ApiService.adminPatch('/submissions/$id/reject', {'rejectionReason': ctrl.text});
      }
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission ${action}d.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: Text('Submissions ($_total)'),
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: const Color(0xFFE94560),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _tabs.map((t) => Tab(text: t[0].toUpperCase() + t.substring(1))).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _submissions.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.inbox_outlined, size: 60, color: Colors.white24),
                      const SizedBox(height: 12),
                      const Text('No submissions found.', style: TextStyle(color: Colors.white38)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _submissions.length,
                      itemBuilder: (_, i) => _SubmissionCard(
                        data: _submissions[i] as Map<String, dynamic>,
                        onApprove: (id) => _showActionDialog(id, 'approve'),
                        onReject:  (id) => _showActionDialog(id, 'reject'),
                      ),
                    ),
            ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String) onApprove;
  final Function(String) onReject;
  const _SubmissionCard({required this.data, required this.onApprove, required this.onReject});

  Color _statusColor(String s) {
    switch (s) {
      case 'approved':   return Colors.green;
      case 'rejected':   return Colors.red;
      case 'completed':  return Colors.blue;
      case 'processing': return Colors.orange;
      default:           return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status     = data['status']     as String? ?? 'pending';
    final user       = data['user']       as Map<String, dynamic>? ?? {};
    final moduleType = (data['moduleType'] as String? ?? '').replaceAll('_', ' ').toUpperCase();
    final id         = data['_id']        as String;
    final role       = user['role']       as String? ?? 'free';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _statusColor(status), width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(data['title'] ?? 'Untitled',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white))),
              _StatusBadge(status: status),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(moduleType,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.white38),
              const SizedBox(width: 4),
              Text(user['name'] ?? 'Unknown', style: const TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: role == 'membership'
                      ? Colors.purple.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(role == 'membership' ? 'Member' : 'Free',
                    style: TextStyle(
                        fontSize: 10,
                        color: role == 'membership' ? Colors.purple : Colors.orange,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.email_outlined, size: 14, color: Colors.white38),
              const SizedBox(width: 4),
              Text(user['email'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.white38)),
            ]),

            if (status == 'pending') ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Colors.white12),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => onReject(id),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => onApprove(id),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                )),
              ]),
            ],

            if (status == 'rejected' &&
                (data['rejectionReason'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Expanded(child: Text(data['rejectionReason'] as String,
                      style: const TextStyle(fontSize: 12, color: Colors.redAccent))),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'approved':   color = Colors.green;  break;
      case 'rejected':   color = Colors.red;    break;
      case 'completed':  color = Colors.blue;   break;
      case 'processing': color = Colors.orange; break;
      default:           color = Colors.amber;  break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(status[0].toUpperCase() + status.substring(1),
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}