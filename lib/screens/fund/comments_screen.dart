// lib/screens/fund/comments_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/fund_raising_model.dart';
import '../../services/api_service.dart';

class CommentsScreen extends StatefulWidget {
  final FundRaisingState sharedState;
  const CommentsScreen({super.key, required this.sharedState});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late TextEditingController _bgCtrl;
  late TextEditingController _expCtrl;
  late TextEditingController _competitorCtrl;
  late TextEditingController _riskCtrl;
  late TextEditingController _futureCtrl;
  late TextEditingController _useOfFundsCtrl;
  late TextEditingController _tractionCtrl;
  final _commentCtrl = TextEditingController();

  bool _isSaving = false;

  CommentsData get _data => widget.sharedState.comments;

  static const List<String> _stages = [
    'Pre-Seed', 'Seed', 'Series A', 'Series B', 'Series C+', 'Bridge'
  ];

  @override
  void initState() {
    super.initState();
    _tabController    = TabController(length: 3, vsync: this);
    _bgCtrl           = TextEditingController(text: _data.businessBackground);
    _expCtrl          = TextEditingController(text: _data.experience);
    _competitorCtrl   = TextEditingController(text: _data.competitorDetails);
    _riskCtrl         = TextEditingController(text: _data.riskFactors);
    _futureCtrl       = TextEditingController(text: _data.futurePlan);
    _useOfFundsCtrl   = TextEditingController(text: _data.useOfFunds);
    _tractionCtrl     = TextEditingController(text: _data.traction);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bgCtrl.dispose();
    _expCtrl.dispose();
    _competitorCtrl.dispose();
    _riskCtrl.dispose();
    _futureCtrl.dispose();
    _useOfFundsCtrl.dispose();
    _tractionCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _syncToModel() {
    _data.businessBackground = _bgCtrl.text.trim();
    _data.experience         = _expCtrl.text.trim();
    _data.competitorDetails  = _competitorCtrl.text.trim();
    _data.riskFactors        = _riskCtrl.text.trim();
    _data.futurePlan         = _futureCtrl.text.trim();
    _data.useOfFunds         = _useOfFundsCtrl.text.trim();
    _data.traction           = _tractionCtrl.text.trim();
  }

  Future<void> _saveInfo() async {
    if (_bgCtrl.text.trim().isEmpty) {
      _showSnack('Business background is required.', isError: true);
      return;
    }
    _syncToModel();

    final recordId = widget.sharedState.recordId;
    if (recordId == null) {
      _showSnack('Please save Pitch Deck info first.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ApiService.updateComments(
        recordId: recordId,
        businessBackground: _data.businessBackground,
        experience:         _data.experience,
        competitorDetails:  _data.competitorDetails,
        riskFactors:        _data.riskFactors,
        futurePlan:         _data.futurePlan,
        useOfFunds:         _data.useOfFunds,
        traction:           _data.traction,
        stage:              _data.fundingStage,
        investorComments: _data.investorComments
            .where((c) => c.isOwn)
            .map((c) => c.text)
            .toList(),
      );
      _data.isComplete = true;
      _showSnack('Business information saved to database!');
    } catch (e) {
      _showSnack('Save failed: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _data.investorComments.insert(
        0,
        InvestorComment(
          name: 'You',
          avatar: 'Y',
          time: 'Just now',
          text: text,
          isOwn: true,
        ),
      );
      _commentCtrl.clear();
    });
  }

  void _addFounder() =>
      setState(() => _data.founders.add(FounderModel(name: '', role: '', linkedin: '')));

  void _removeFounder(int i) {
    if (_data.founders.length > 1) setState(() => _data.founders.removeAt(i));
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
      ]),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: Duration(seconds: isError ? 3 : 2),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0D6E8A),
            leading: GestureDetector(
              onTap: () { _syncToModel(); Navigator.pop(context); },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(background: _buildHero()),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accentGold,
              indicatorWeight: 3,
              labelStyle:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Business Info'),
                Tab(text: 'Team'),
                Tab(text: 'Investor Chat'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBusinessInfoTab(),
            _buildTeamTab(),
            _buildInvestorChatTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF063D50), Color(0xFF0D6E8A), Color(0xFF129EC0)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.forum_outlined,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Investor Comments',
                      style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text('Qualitative context for AI analysis',
                      style:
                          GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                ]),
                const Spacer(),
                _StageBadge(
                  currentStage: _data.fundingStage,
                  stages: _stages,
                  onChanged: (v) => setState(() => _data.fundingStage = v),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Business Info ──────────────────────────────────────────────────
  Widget _buildBusinessInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _infoCard(
          title: 'Business Background',
          icon: Icons.history_edu_outlined,
          hint: "Tell us about your company's history, what inspired you to start it, and how long you've been operating...",
          controller: _bgCtrl,
          required: true,
        ),
        const SizedBox(height: 12),
        _infoCard(
          title: 'Founder Experience',
          icon: Icons.workspace_premium_outlined,
          hint: "Describe your team's relevant industry experience, prior startups, domain expertise...",
          controller: _expCtrl,
        ),
        const SizedBox(height: 12),
        _infoCard(
          title: 'Competitor Details',
          icon: Icons.compare_arrows,
          hint: 'Who are your main competitors? What is your competitive advantage or differentiation?',
          controller: _competitorCtrl,
        ),
        const SizedBox(height: 12),
        _infoCard(
          title: 'Risk Factors',
          icon: Icons.warning_amber_outlined,
          hint: 'What are the key risks to your business? Regulatory, market, operational, technical...',
          controller: _riskCtrl,
        ),
        const SizedBox(height: 12),
        _infoCard(
          title: 'Future Plan',
          icon: Icons.rocket_launch_outlined,
          hint: '12-month milestones, product roadmap, expansion plans, exit strategy...',
          controller: _futureCtrl,
        ),
        const SizedBox(height: 12),
        _infoCard(
          title: 'Use of Funds',
          icon: Icons.account_balance_wallet_outlined,
          hint: 'How will the raised capital be deployed? e.g. 40% product, 30% marketing, 20% team, 10% ops',
          controller: _useOfFundsCtrl,
          required: true,
        ),
        const SizedBox(height: 12),
        _infoCard(
          title: 'Current Traction',
          icon: Icons.trending_up,
          hint: 'Revenue, customers, MoM growth, partnerships, key metrics that show momentum...',
          controller: _tractionCtrl,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveInfo,
            icon: _isSaving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, color: Colors.white),
            label: Text(
                _isSaving
                    ? 'Saving to MongoDB...'
                    : 'Save Business Information',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6E8A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  // ── Tab 2: Team ──────────────────────────────────────────────────────────
  Widget _buildTeamTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...List.generate(_data.founders.length, (i) {
          final f = _data.founders[i];
          return _FounderCard(
            index: i,
            founder: f,
            canRemove: _data.founders.length > 1,
            onRemove: () => _removeFounder(i),
            onChanged: () => setState(() {}),
          );
        }),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _addFounder,
          icon: const Icon(Icons.person_add_outlined, color: Color(0xFF0D6E8A)),
          label: Text('Add Founder / Key Team Member',
              style: GoogleFonts.inter(
                  color: const Color(0xFF0D6E8A),
                  fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF0D6E8A), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Tab 3: Investor Chat ──────────────────────────────────────────────────
  Widget _buildInvestorChatTab() {
    return Column(children: [
      Container(
        color: const Color(0xFF0D6E8A),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: Row(children: [
          _Stat(
              value: '${_data.investorComments.length}',
              label: 'Comments'),
          const SizedBox(width: 20),
          _Stat(
              value: '${_data.investorComments.where((c) => !c.isOwn).length}',
              label: 'Investors'),
          const SizedBox(width: 20),
          const _Stat(value: '4.2★', label: 'Avg Rating'),
        ]),
      ),
      Expanded(
        child: _data.investorComments.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.forum_outlined,
                        size: 48,
                        color: AppTheme.textSecondary.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('No comments yet',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppTheme.textSecondary)),
                    Text('Add your notes or investor feedback below',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary.withOpacity(0.7))),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _data.investorComments.length,
                itemBuilder: (context, i) =>
                    _CommentCard(comment: _data.investorComments[i]),
              ),
      ),
      // Input bar
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                decoration: InputDecoration(
                  hintText: 'Add a comment or investor feedback...',
                  hintStyle: GoogleFonts.inter(
                      color: AppTheme.textSecondary, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF0D6E8A), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _addComment,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6E8A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 19),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool required = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D6E8A).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: const Color(0xFF0D6E8A), size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          if (required) ...[
            const SizedBox(width: 4),
            const Text('*',
                style: TextStyle(color: AppTheme.error, fontSize: 14)),
          ],
        ]),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                color: AppTheme.textSecondary.withOpacity(0.65),
                fontSize: 12, height: 1.5),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF0D6E8A), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ]),
    );
  }
}

// ── Stage Badge ──────────────────────────────────────────────────────────────
class _StageBadge extends StatelessWidget {
  final String currentStage;
  final List<String> stages;
  final Function(String) onChanged;
  const _StageBadge(
      {required this.currentStage,
      required this.stages,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) =>
              _StageSheet(stages: stages, current: currentStage),
        );
        if (selected != null) onChanged(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(currentStage,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 14),
        ]),
      ),
    );
  }
}

class _StageSheet extends StatelessWidget {
  final List<String> stages;
  final String current;
  const _StageSheet({required this.stages, required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Funding Stage',
            style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        ...stages.map((s) => ListTile(
              title: Text(s, style: GoogleFonts.inter(fontSize: 14)),
              trailing: s == current
                  ? const Icon(Icons.check, color: AppTheme.success)
                  : null,
              onTap: () => Navigator.pop(context, s),
            )),
      ]),
    );
  }
}

// ── Founder Card ─────────────────────────────────────────────────────────────
class _FounderCard extends StatelessWidget {
  final int index;
  final FounderModel founder;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _FounderCard({
    required this.index,
    required this.founder,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D6E8A).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF0D6E8A).withOpacity(0.1),
            child: Text(
              founder.name.isNotEmpty ? founder.name[0].toUpperCase() : '?',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0D6E8A),
                  fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Text('Founder ${index + 1}',
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const Spacer(),
          if (canRemove)
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.remove, color: AppTheme.error, size: 16),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        _field(
          label: 'Full Name *',
          hint: 'e.g. John Smith',
          initial: founder.name,
          onChanged: (v) { founder.name = v; onChanged(); },
        ),
        const SizedBox(height: 10),
        _field(
          label: 'Role / Title',
          hint: 'e.g. CEO, CTO, CFO',
          initial: founder.role,
          onChanged: (v) => founder.role = v,
        ),
        const SizedBox(height: 10),
        _field(
          label: 'LinkedIn Profile URL',
          hint: 'https://linkedin.com/in/...',
          initial: founder.linkedin,
          onChanged: (v) => founder.linkedin = v,
          keyboardType: TextInputType.url,
        ),
      ]),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required String initial,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary)),
      const SizedBox(height: 4),
      TextFormField(
        initialValue: initial,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary.withOpacity(0.7)),
          filled: true,
          fillColor: AppTheme.surface,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppTheme.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppTheme.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide:
                const BorderSide(color: Color(0xFF0D6E8A), width: 1.5),
          ),
        ),
      ),
    ]);
  }
}

// ── Comment Card ─────────────────────────────────────────────────────────────
class _CommentCard extends StatelessWidget {
  final InvestorComment comment;
  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final isOwn = comment.isOwn;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOwn
            ? const Color(0xFF0D6E8A).withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOwn
              ? const Color(0xFF0D6E8A).withOpacity(0.2)
              : AppTheme.divider,
        ),
        boxShadow: isOwn
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF0D6E8A).withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isOwn
              ? const Color(0xFF0D6E8A).withOpacity(0.15)
              : const Color(0xFF0D6E8A),
          child: Text(comment.avatar,
              style: GoogleFonts.montserrat(
                  color: isOwn ? const Color(0xFF0D6E8A) : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(comment.name,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 13)),
              Text(comment.time,
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppTheme.textSecondary)),
            ]),
            const SizedBox(height: 4),
            Text(comment.text,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5)),
          ],
        )),
      ]),
    );
  }
}

// ── Stat widget ──────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white)),
      Text(label,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
    ]);
  }
}