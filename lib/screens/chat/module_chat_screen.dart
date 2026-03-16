// lib/screens/chat/module_chat_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:empora/models/chat_message_model.dart';
import 'package:empora/services/api_service.dart';
import 'package:empora/theme/app_theme.dart';

class ModuleChatScreen extends StatefulWidget {
  final String module;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String welcomeMessage;
  final List<String> suggestedQuestions;

  const ModuleChatScreen({
    super.key,
    required this.module,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.welcomeMessage,
    required this.suggestedQuestions,
  });

  @override
  State<ModuleChatScreen> createState() => _ModuleChatScreenState();
}

class _ModuleChatScreenState extends State<ModuleChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController     = ScrollController();
  final FocusNode _focusNode                   = FocusNode();

  List<ChatMessage> _messages   = [];
  List<String>      _keyFacts   = [];
  bool _isLoading               = false;
  bool _isLoadingHistory        = true;
  bool _isTyping                = false;

  late AnimationController _typingAnimController;

  @override
  void initState() {
    super.initState();
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _loadHistory();
  }

  @override
  void dispose() {
    _typingAnimController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final result = await ApiService.getChatHistory(module: widget.module);
      final rawMessages = result['messages'] as List<dynamic>? ?? [];
      final rawFacts    = result['keyFacts']  as List<dynamic>? ?? [];
      setState(() {
        _messages = rawMessages
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList();
        _keyFacts = rawFacts.map((f) => f.toString()).toList();
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = (overrideText ?? _inputController.text).trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(
        role: 'user', content: text, timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _isTyping  = true;
    });
    _scrollToBottom();

    try {
      final result = await ApiService.sendChatMessage(
        module:  widget.module,
        message: text,
      );
      final aiReply = result['message'] as String? ??
          'Sorry, I could not respond. Please try again.';
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant', content: aiReply, timestamp: DateTime.now(),
        ));
        _isLoading = false;
        _isTyping  = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content:
              '⚠️ Connection error. Please check your internet and try again.',
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
        _isTyping  = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Conversation',
            style: GoogleFonts.montserrat(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'This will delete all messages and the AI\'s memory of your situation. Are you sure?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear',
                style: GoogleFonts.inter(
                    color: AppTheme.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.clearChatHistory(module: widget.module);
      setState(() {
        _messages = [];
        _keyFacts = [];
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear chat.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_keyFacts.isNotEmpty) _buildMemoryBanner(),
          Expanded(child: _buildMessageList()),
          if (_isTyping) _buildTypingIndicator(),
          if (_messages.isEmpty && !_isLoadingHistory) _buildSuggestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              Text(widget.subtitle,
                  style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.75), fontSize: 11)),
            ],
          ),
        ],
      ),
      actions: [
        if (_messages.isNotEmpty)
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Colors.white.withOpacity(0.8), size: 22),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Memory Banner ────────────────────────────────────────────────────────
  Widget _buildMemoryBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.accentColor.withOpacity(0.07),
        border: Border(
          bottom: BorderSide(color: widget.accentColor.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.memory_rounded, color: widget.accentColor, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Remembers: ${_keyFacts.take(2).join(' • ')}'
              '${_keyFacts.length > 2 ? ' +${_keyFacts.length - 2} more' : ''}',
              style: GoogleFonts.inter(
                  color: widget.accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Message List ─────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    if (_isLoadingHistory) {
      return Center(
          child: CircularProgressIndicator(color: widget.accentColor));
    }
    if (_messages.isEmpty) return _buildWelcomeView();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) =>
          _buildMessageBubble(_messages[index]),
    );
  }

  // ─── Welcome View ─────────────────────────────────────────────────────────
  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: widget.accentColor, size: 52),
          ),
          const SizedBox(height: 20),
          Text(
            'Hi! I\'m your ${widget.title}',
            style: GoogleFonts.montserrat(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            widget.welcomeMessage,
            style: GoogleFonts.inter(
                color: AppTheme.textSecondary, fontSize: 14, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Message Bubble ───────────────────────────────────────────────────────
  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(widget.icon, color: widget.accentColor, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied',
                        style: GoogleFonts.inter(color: Colors.white)),
                    duration: const Duration(seconds: 1),
                    backgroundColor: AppTheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? widget.accentColor : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(16),
                    topRight:    const Radius.circular(16),
                    bottomLeft:  Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: isUser
                      ? null
                      : Border.all(color: AppTheme.divider),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  msg.content,
                  style: GoogleFonts.inter(
                    color: isUser ? Colors.white : AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ─── Typing Indicator ─────────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: widget.accentColor, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(3, (i) => _buildDot(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimController,
      builder: (_, __) {
        final offset  = (index * 0.3);
        final opacity =
            ((_typingAnimController.value - offset).clamp(0.0, 1.0));
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.accentColor.withOpacity(0.3 + opacity * 0.7),
          ),
        );
      },
    );
  }

  // ─── Suggested Questions ──────────────────────────────────────────────────
  Widget _buildSuggestions() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.suggestedQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final q = widget.suggestedQuestions[index];
          return GestureDetector(
            onTap: () => _sendMessage(q),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: widget.accentColor.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                q,
                style: GoogleFonts.inter(
                    color: widget.accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Input Bar ────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.divider)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode:  _focusNode,
              style: GoogleFonts.inter(
                  color: AppTheme.textPrimary, fontSize: 14),
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                    'Ask your ${widget.title.toLowerCase()}...',
                hintStyle: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 14),
                filled:    true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppTheme.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppTheme.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      BorderSide(color: widget.accentColor, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isLoading
                    ? widget.accentColor.withOpacity(0.4)
                    : widget.accentColor,
                boxShadow: [
                  if (!_isLoading)
                    BoxShadow(
                      color: widget.accentColor.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}