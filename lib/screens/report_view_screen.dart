import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:empora/services/auth_provider.dart';
import 'package:empora/services/api_service.dart';
import 'package:empora/screens/membership_screen.dart';

class ReportViewScreen extends StatefulWidget {
  final String submissionId;
  final String title;
  final String moduleType;

  const ReportViewScreen({
    super.key,
    required this.submissionId,
    required this.title,
    required this.moduleType,
  });

  @override
  State<ReportViewScreen> createState() => _ReportViewScreenState();
}

class _ReportViewScreenState extends State<ReportViewScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await ApiService.getModuleData(
        module: 'reports',
        recordId: widget.submissionId,
      );
      setState(() { _data = res; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _download() async {
    try {
      final url = await ApiService.getModulePdfUrl(
        module: 'reports',
        recordId: widget.submissionId,
      );
      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (auth.isMember && _data?['reportReady'] == true)
            IconButton(icon: const Icon(Icons.download), onPressed: _download),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : _buildBody(auth),
    );
  }

  Widget _buildBody(AuthProvider auth) {
    if (_data == null) return const SizedBox();

    if (_data!['reportReady'] == false) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Your report is being generated...', style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Text('This may take a few minutes.'),
      ]));
    }

    final report   = _data!['report'] as Map<String, dynamic>;
    final isMember = _data!['isMember'] as bool? ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.moduleType.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Summary — visible to ALL
          _Section(
            icon: Icons.article_outlined,
            title: 'Report Summary',
            content: report['summary'] as String? ?? 'No summary available.',
          ),
          const SizedBox(height: 24),

          // Full report — membership only
          if (isMember) ...[
            _Section(
              icon: Icons.description,
              title: 'Full Report',
              content: report['fullContent'] as String? ?? '',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _download,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download Full PDF Report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A237E),
                  side: const BorderSide(color: Color(0xFF1A237E)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else
            _LockedSection(),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  const _Section({required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: const Color(0xFF1A237E), size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        Text(content, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
      ]),
    );
  }
}

class _LockedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: [
        // Blurred preview lines
        Stack(children: [
          Column(children: List.generate(6, (_) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 12, width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
          ))),
          Container(height: 110, decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.white.withOpacity(0.0), Colors.white],
            ),
          )),
        ]),
        const SizedBox(height: 16),
        const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
        const SizedBox(height: 12),
        const Text('Full Report Locked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Upgrade to membership to view the full report and download the PDF.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const MembershipScreen())),
            icon: const Icon(Icons.workspace_premium),
            label: const Text('Upgrade to Membership'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
  }
}