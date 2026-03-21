// lib/screens/chat/chat_advisor_screen.dart
// Improved AI Chat Advisor — used by Taxation, Land & Legal, Licence, Loans,
// Risk, Project, Cyber, Restructure modules
// Features:
//   • Profile context bar (business type + stage)
//   • Smart personalised suggestions grid
//   • Quick chip buttons
//   • Better header with online indicator
//   • Cleaner message bubbles
//   • Crown logo branding

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:empora/services/auth_provider.dart';
import 'package:empora/services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool   isUser;
  final DateTime time;
  _ChatMessage({required this.text, required this.isUser})
      : time = DateTime.now();
}

class _SuggestionItem {
  final String emoji;
  final String title;
  final String subtitle;
  final String prompt;
  const _SuggestionItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.prompt,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ADVISOR CONFIG — one per module
// ─────────────────────────────────────────────────────────────────────────────
class AdvisorConfig {
  final String  moduleKey;
  final String  title;
  final String  subtitle;
  final IconData icon;
  final Color   color;
  final String  greeting;
  final List<_SuggestionItem> suggestions;
  final List<String> quickChips;

  const AdvisorConfig({
    required this.moduleKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.greeting,
    required this.suggestions,
    required this.quickChips,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PREDEFINED ADVISOR CONFIGS
// ─────────────────────────────────────────────────────────────────────────────
class AdvisorConfigs {
  static AdvisorConfig taxation = const AdvisorConfig(
    moduleKey: 'taxation',
    title: 'Tax Advisor',
    subtitle: 'Personal CA & Tax Planning',
    icon: Icons.receipt_long_outlined,
    color: Color(0xFF27AE60),
    greeting: 'I\'m your personal CA and Tax Advisor. I can help you with income tax planning, GST compliance, TDS, startup exemptions, and tax-saving strategies.\n\nTell me about your business and I\'ll guide you step by step.',
    suggestions: [
      _SuggestionItem(emoji: '📊', title: 'Tax saving strategies', subtitle: 'For your business', prompt: 'What are the best tax saving strategies for my business?'),
      _SuggestionItem(emoji: '🧾', title: 'GST registration', subtitle: 'Step by step guide', prompt: 'How do I register for GST? Walk me through the process.'),
      _SuggestionItem(emoji: '💡', title: 'Section 80 benefits', subtitle: 'Startup exemptions', prompt: 'What are Section 80 tax benefits available for startups?'),
      _SuggestionItem(emoji: '📅', title: 'TDS deadlines', subtitle: 'Compliance calendar', prompt: 'What are the upcoming TDS filing deadlines I need to know?'),
    ],
    quickChips: ['How much tax will I pay?', 'GST registration', '80-IAC exemption', 'TDS rates', 'Income tax slab'],
  );

  static AdvisorConfig landLegal = const AdvisorConfig(
    moduleKey: 'land_legal',
    title: 'Legal Advisor',
    subtitle: 'Property Law & Legal Advisory',
    icon: Icons.gavel_outlined,
    color: Color(0xFF8E44AD),
    greeting: 'I\'m your Legal Advisor specialising in property law and business legal matters. I can help you with property agreements, legal compliance, contracts, and dispute resolution.\n\nWhat legal matter can I assist you with today?',
    suggestions: [
      _SuggestionItem(emoji: '📜', title: 'Property agreement', subtitle: 'Draft & review', prompt: 'How do I draft a proper property lease agreement for my business?'),
      _SuggestionItem(emoji: '⚖️', title: 'Legal compliance', subtitle: 'Business laws', prompt: 'What are the key legal compliances my business must follow?'),
      _SuggestionItem(emoji: '🤝', title: 'Contract review', subtitle: 'Key clauses', prompt: 'What are the important clauses I should check in a business contract?'),
      _SuggestionItem(emoji: '🏠', title: 'Property title', subtitle: 'Verification guide', prompt: 'How do I verify property title before purchasing commercial property?'),
    ],
    quickChips: ['Lease agreement', 'Legal compliance', 'Contract review', 'Property title', 'Dispute resolution'],
  );

  static AdvisorConfig licence = const AdvisorConfig(
    moduleKey: 'licence',
    title: 'Licence Advisor',
    subtitle: 'Business Licensing & Permits',
    icon: Icons.verified_outlined,
    color: Color(0xFFE67E22),
    greeting: 'I\'m your Licence Advisor. I help founders navigate the complex world of business licences, permits, and regulatory approvals.\n\nTell me your business type and I\'ll tell you exactly what licences you need.',
    suggestions: [
      _SuggestionItem(emoji: '📋', title: 'Required licences', subtitle: 'For your industry', prompt: 'What licences and permits does my business need to operate legally?'),
      _SuggestionItem(emoji: '🏢', title: 'Shop Act licence', subtitle: 'Registration process', prompt: 'How do I get a Shop and Establishment Act licence for my business?'),
      _SuggestionItem(emoji: '🍽️', title: 'FSSAI licence', subtitle: 'Food business', prompt: 'How do I apply for an FSSAI food business licence?'),
      _SuggestionItem(emoji: '⚡', title: 'Trade licence', subtitle: 'Municipal permit', prompt: 'What is a trade licence and how do I obtain it from the municipality?'),
    ],
    quickChips: ['What licences do I need?', 'Shop Act', 'FSSAI', 'Import Export code', 'Trade licence'],
  );

  static AdvisorConfig loans = const AdvisorConfig(
    moduleKey: 'loans',
    title: 'Loan Advisor',
    subtitle: 'Funding & Financial Planning',
    icon: Icons.account_balance_outlined,
    color: Color(0xFF2980B9),
    greeting: 'I\'m your Loan & Financial Advisor. I help founders find the right funding options — from bank loans to government schemes and investor funding.\n\nLet\'s find the best financing option for your business.',
    suggestions: [
      _SuggestionItem(emoji: '🏦', title: 'Bank loan options', subtitle: 'Best rates for you', prompt: 'What are the best bank loan options available for my stage of business?'),
      _SuggestionItem(emoji: '🏛️', title: 'Govt. schemes', subtitle: 'MUDRA, SIDBI etc.', prompt: 'What government loan schemes like MUDRA am I eligible for?'),
      _SuggestionItem(emoji: '📈', title: 'Improve credit score', subtitle: 'Get better rates', prompt: 'How can I improve my business credit score to get better loan rates?'),
      _SuggestionItem(emoji: '💰', title: 'Working capital', subtitle: 'Cash flow loan', prompt: 'How do I get a working capital loan to manage my business cash flow?'),
    ],
    quickChips: ['MUDRA loan', 'Bank loan eligibility', 'Govt. schemes', 'Credit score', 'Working capital'],
  );

  static AdvisorConfig risk = const AdvisorConfig(
    moduleKey: 'risk',
    title: 'Risk Advisor',
    subtitle: 'Business Risk Management',
    icon: Icons.shield_outlined,
    color: Color(0xFFE74C3C),
    greeting: 'I\'m your Risk Management Advisor. I help founders identify, assess, and mitigate business risks before they become problems.\n\nLet\'s analyse the risks in your business today.',
    suggestions: [
      _SuggestionItem(emoji: '🔍', title: 'Risk assessment', subtitle: 'Identify key risks', prompt: 'What are the major risks I should be aware of in my business?'),
      _SuggestionItem(emoji: '🛡️', title: 'Insurance coverage', subtitle: 'What you need', prompt: 'What business insurance policies should I have to protect my company?'),
      _SuggestionItem(emoji: '📉', title: 'Financial risk', subtitle: 'Cash flow safety', prompt: 'How do I protect my business from financial risks and cash flow problems?'),
      _SuggestionItem(emoji: '🔐', title: 'Cyber security risk', subtitle: 'Data protection', prompt: 'What cybersecurity risks does my business face and how to mitigate them?'),
    ],
    quickChips: ['Risk assessment', 'Business insurance', 'Financial risk', 'Cyber risk', 'Compliance risk'],
  );

  static AdvisorConfig project = const AdvisorConfig(
    moduleKey: 'project',
    title: 'Project Advisor',
    subtitle: 'Plan, Track & Deliver Projects',
    icon: Icons.task_alt_outlined,
    color: Color(0xFF16A085),
    greeting: 'I\'m your Project Management Advisor. I help founders plan, execute, and deliver projects on time and within budget.\n\nWhat project challenge can I help you with?',
    suggestions: [
      _SuggestionItem(emoji: '📅', title: 'Project planning', subtitle: 'Create a roadmap', prompt: 'How do I create an effective project plan and roadmap for my team?'),
      _SuggestionItem(emoji: '👥', title: 'Team management', subtitle: 'Productivity tips', prompt: 'How do I manage a remote team effectively and track productivity?'),
      _SuggestionItem(emoji: '⏱️', title: 'Deadline tracking', subtitle: 'Stay on schedule', prompt: 'What methods help me ensure my team meets project deadlines consistently?'),
      _SuggestionItem(emoji: '💸', title: 'Budget control', subtitle: 'Avoid overspending', prompt: 'How do I control project costs and avoid budget overruns?'),
    ],
    quickChips: ['Project planning', 'Team management', 'Agile methods', 'Budget control', 'Risk in projects'],
  );

  static AdvisorConfig cyber = const AdvisorConfig(
    moduleKey: 'cyber',
    title: 'Cyber Advisor',
    subtitle: 'Protect Your Digital Assets',
    icon: Icons.security_outlined,
    color: Color(0xFF1A3A7C),
    greeting: 'I\'m your Cybersecurity Advisor. I help founders protect their digital assets, customer data, and business systems from cyber threats.\n\nLet\'s secure your digital business today.',
    suggestions: [
      _SuggestionItem(emoji: '🔐', title: 'Password security', subtitle: 'Best practices', prompt: 'What are the best password and access security practices for my business?'),
      _SuggestionItem(emoji: '🦠', title: 'Malware protection', subtitle: 'Stay protected', prompt: 'How do I protect my business systems from malware and ransomware attacks?'),
      _SuggestionItem(emoji: '📱', title: 'Data privacy', subtitle: 'Compliance guide', prompt: 'What data privacy laws apply to my business and how do I comply?'),
      _SuggestionItem(emoji: '☁️', title: 'Cloud security', subtitle: 'Safe cloud usage', prompt: 'How do I securely use cloud services for my business data?'),
    ],
    quickChips: ['Password security', 'Data privacy', 'Cyber threats', 'Cloud safety', 'GDPR compliance'],
  );

  static AdvisorConfig restructure = const AdvisorConfig(
    moduleKey: 'restructure',
    title: 'Restructure Advisor',
    subtitle: 'Business Restructuring Advisory',
    icon: Icons.account_tree_outlined,
    color: Color(0xFF7F8C8D),
    greeting: 'I\'m your Business Restructuring Advisor. I help founders reshape their business model, operations, and finances during challenging or growth phases.\n\nLet\'s discuss how to transform your business.',
    suggestions: [
      _SuggestionItem(emoji: '🔄', title: 'Business model', subtitle: 'Pivot strategy', prompt: 'How do I restructure my business model to improve profitability?'),
      _SuggestionItem(emoji: '💼', title: 'Debt restructuring', subtitle: 'Manage obligations', prompt: 'How can I restructure my business debts to improve cash flow?'),
      _SuggestionItem(emoji: '👔', title: 'Team restructure', subtitle: 'Right-size your team', prompt: 'How do I restructure my team for better efficiency and cost savings?'),
      _SuggestionItem(emoji: '📊', title: 'Cost reduction', subtitle: 'Lean operations', prompt: 'What are the best strategies to reduce operational costs in my business?'),
    ],
    quickChips: ['Business pivot', 'Debt management', 'Cost reduction', 'Team structure', 'Merger advice'],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN CHAT ADVISOR SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ChatAdvisorScreen extends StatefulWidget {
  final AdvisorConfig config;
  const ChatAdvisorScreen({super.key, required this.config});

  @override
  State<ChatAdvisorScreen> createState() => _ChatAdvisorScreenState();
}

class _ChatAdvisorScreenState extends State<ChatAdvisorScreen> {
  final List<_ChatMessage>    _messages   = [];
  final TextEditingController _ctrl       = TextEditingController();
  final ScrollController      _scroll     = ScrollController();
  bool   _isTyping        = false;
  bool   _showSuggestions = true;
  String _industry        = '';
  String _lastFailedMessage = '';
  String _stage           = '';
  String _bizName         = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await ApiService.getFounderProfile();
      final raw = res['data'] ?? res['founderProfile'] ?? res;
      final fp  = raw is Map<String, dynamic> ? raw : null;
      if (fp != null && mounted) {
        setState(() {
          _industry = fp['industry']      as String? ?? '';
          _stage    = fp['businessStage'] as String? ?? '';
          _bizName  = fp['businessName']  as String? ?? '';
        });
      }
    } catch (_) {}
    // Add greeting after profile loads
    if (mounted && _messages.isEmpty) {
      setState(() {
        _messages.add(_ChatMessage(
          text: _buildPersonalisedGreeting(),
          isUser: false,
        ));
      });
    }
  }

  String _buildPersonalisedGreeting() {
    final industry = _industry;
    final stage    = _stage;
    String base = widget.config.greeting;
    if (industry.isNotEmpty || stage.isNotEmpty) {
      base += '\n\n💼 I can see you\'re in ${industry.isNotEmpty ? industry : 'your industry'}${stage.isNotEmpty ? ' at $stage stage' : ''}. I\'ll personalise my advice accordingly.';
    }
    return base;
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
      _showSuggestions = false;
    });
    _scrollToBottom();

    try {
      final auth    = context.read<AuthProvider>();
      final profile = 'Industry: ${_industry.isNotEmpty ? _industry : 'Not set'}, Stage: ${_stage.isNotEmpty ? _stage : 'Not set'}, Business: ${_bizName.isNotEmpty ? _bizName : (auth.user?.name ?? 'Not set')}';
      final result  = await ApiService.sendChatMessage(
        module: widget.config.moduleKey,
        message: '$text\n\n[User profile: $profile]',
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Request timed out after 30 seconds'),
      );
      final reply = result['message'] as String? ?? result['reply'] as String? ?? 'I\'m here to help! Could you please provide more details about your question?';
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: 'I\'m having trouble connecting right now. Please check your internet connection and try again.',
          isUser: false,
        ));
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg      = widget.config;
    final industry = _industry;
    final stage    = _stage;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F7),
      body: Column(children: [

        // ── HEADER ──────────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1B4B), Color(0xFF1A3A7C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 12),

                // Advisor icon
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Icon(cfg.icon, color: cfg.color, size: 22),
                ),
                const SizedBox(width: 12),

                // Title + online status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cfg.title,
                        style: GoogleFonts.montserrat(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      Row(children: [
                        Container(
                          width: 7, height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF27AE60), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text('AI powered · Always available',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.65), fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),

        // ── CHAT AREA ────────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            itemCount: _messages.length + (_isTyping ? 1 : 0) + (_showSuggestions ? 1 : 0),
            itemBuilder: (context, index) {

              // Profile context bar (first item)
              if (index == 0 && _showSuggestions && (industry.isNotEmpty || stage.isNotEmpty)) {
                return _buildContextBar(industry, stage);
              }

              // Suggestions grid (second item if showing)
              final msgOffset = (_showSuggestions && (industry.isNotEmpty || stage.isNotEmpty)) ? 1 : 0;
              if (_showSuggestions && index == msgOffset + _messages.length) {
                return _buildSuggestions(cfg);
              }

              // Typing indicator
              if (_isTyping && index == msgOffset + _messages.length) {
                return _buildTypingIndicator();
              }

              final msg = _messages[index - msgOffset];
              return _buildMessage(msg);
            },
          ),
        ),

        // ── QUICK CHIPS ──────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: cfg.quickChips.map((chip) => GestureDetector(
                onTap: () => _send(chip),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(chip,
                    style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF1A3A7C),
                      fontWeight: FontWeight.w500)),
                ),
              )).toList(),
            ),
          ),
        ),

        // ── INPUT BAR ────────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A1F36)),
                    decoration: InputDecoration(
                      hintText: 'Ask your ${cfg.title.toLowerCase()}...',
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    ),
                    onSubmitted: _send,
                    textInputAction: TextInputAction.send,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _send(_ctrl.text),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: cfg.color,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(color: cfg.color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildContextBar(String industry, String stage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A7C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.person_outline, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Profile connected${industry.isNotEmpty ? ' — $industry' : ''}${stage.isNotEmpty ? ' · $stage' : ''}',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF3730A3), fontWeight: FontWeight.w600)),
          Text('Advice personalised to your business',
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF6366F1))),
        ])),
        const Icon(Icons.verified, color: Color(0xFF6366F1), size: 16),
      ]),
    );
  }

  Widget _buildSuggestions(AdvisorConfig cfg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text('Suggested for you',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF6B7280), fontWeight: FontWeight.w600)),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.7,
          children: cfg.suggestions.map((s) => GestureDetector(
            onTap: () => _send(s.prompt),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(s.title,
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1F36))),
                Text(s.subtitle,
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF6B7280))),
              ]),
            ),
          )).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMessage(_ChatMessage msg) {
    final isUser = msg.isUser;
    final isError = !isUser && (msg.text.contains('❌') || msg.text.contains('📶') || msg.text.contains('⏱️') || msg.text.contains('🔐') || msg.text.contains('🛠️') || msg.text.contains('🔧'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: widget.config.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.config.icon, color: widget.config.color, size: 14),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isError
                        ? const Color(0xFFFFF3F3)
                        : isUser ? const Color(0xFF1A3A7C) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isError ? Border.all(color: const Color(0xFFFFCDD2)) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isUser ? 0.12 : 0.06),
                        blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isError
                          ? const Color(0xFFB71C1C)
                          : isUser ? Colors.white : const Color(0xFF1A1F36),
                      height: 1.5,
                    ),
                  ),
                ),
                // Retry button for failed messages
                if (isError && _lastFailedMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: GestureDetector(
                      onTap: () {
                        final msg = _lastFailedMessage;
                        setState(() => _lastFailedMessage = '');
                        _send(msg);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.config.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.refresh, color: Colors.white, size: 13),
                          const SizedBox(width: 5),
                          Text('Retry', style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: widget.config.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.config.icon, color: widget.config.color, size: 14),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _TypingDot(delay: 0),
            const SizedBox(width: 4),
            _TypingDot(delay: 200),
            const SizedBox(width: 4),
            _TypingDot(delay: 400),
          ]),
        ),
      ]),
    );
  }
}

// ── Animated typing dot ───────────────────────────────────────────────────────
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});
  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFFD1D5DB), const Color(0xFF1A3A7C), _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}