import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/services/ai_assistant_service.dart';
import '../../../data/services/budget_service.dart';

/// Shows the AI chat assistant bottom sheet
Future<void> showAiAssistantSheet(
  BuildContext context, {
  required List<ExpenseModel> expenses,
  required double totalBalance,
  required BudgetProgress? budgetProgress,
  VoidCallback? onViewStatistics,
  VoidCallback? onSetBudget,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (ctx) => _AiChatSheet(
      expenses: expenses,
      totalBalance: totalBalance,
      budgetProgress: budgetProgress,
    ),
  );
}

class _AiChatSheet extends StatefulWidget {
  final List<ExpenseModel> expenses;
  final double totalBalance;
  final BudgetProgress? budgetProgress;

  const _AiChatSheet({
    required this.expenses,
    required this.totalBalance,
    required this.budgetProgress,
  });

  @override
  State<_AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<_AiChatSheet>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isAiTyping = false;
  late AnimationController _glowController;
  AiAssistantService? _service;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _initChat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      _service = await AiAssistantService.getInstance();

      // Show typing indicator while AI generates proactive welcome
      if (mounted) setState(() => _isAiTyping = true);

      final welcomeMessage = await _service!.startNewSession(
        expenses: widget.expenses,
        totalBalance: widget.totalBalance,
        monthlyBudget: widget.budgetProgress?.budget.totalBudget ?? 0,
        categoryBudgets: widget.budgetProgress?.budget.categoryBudgets,
      );

      if (mounted) {
        setState(() {
          _isAiTyping = false;
          _messages.add(ChatMessage(
            text: welcomeMessage,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAiTyping = false;
          _messages.add(ChatMessage(
            text: '⚠️ Không thể kết nối AI. Vui lòng kiểm tra kết nối mạng hoặc API key.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isAiTyping) return;

    final userMsg = text.trim();
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMsg,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isAiTyping = true;
    });

    _scrollToBottom();

    // Get AI response
    final response = _service != null
        ? await _service!.sendMessage(userMsg)
        : 'Chưa kết nối được AI. Vui lòng kiểm tra API key.';

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isAiTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      height: context.screenHeight * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121218) : const Color(0xFFF8F9FE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.aiGlow.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildChatArea(context)),
          _buildInputArea(context),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.colorScheme.onSurface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              // AI Avatar
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) {
                  final glow = 0.15 + (_glowController.value * 0.15);
                  return Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.aiGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.aiGlow.withOpacity(glow),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  );
                },
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fin — Trợ lý AI',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Gap(5),
                        Text(
                          'Đang hoạt động',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colorScheme.onSurface.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: context.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Chat Area ──────────────────────────────────────────────────────────

  Widget _buildChatArea(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length +
          (_isAiTyping ? 1 : 0) +
          (_messages.length <= 1 && !_isAiTyping ? 1 : 0), // +1 for suggestions
      itemBuilder: (context, index) {
        // Messages
        if (index < _messages.length) {
          return _buildMessageBubble(context, _messages[index], index);
        }

        // Typing indicator
        if (_isAiTyping && index == _messages.length) {
          return _buildTypingIndicator(context);
        }

        // Suggested questions (shown after welcome message)
        return _buildSuggestedQuestions(context);
      },
    );
  }

  Widget _buildMessageBubble(
      BuildContext context, ChatMessage message, int index) {
    final isDark = context.isDarkMode;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI avatar
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.aiGradient,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const Gap(8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF1E1E2C) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.5,
                  color: isUser
                      ? Colors.white
                      : context.colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
            ),
          ),
          if (isUser) const Gap(8),
        ],
      ),
    )
        .animate()
        .fade(duration: 300.ms)
        .slideX(
          begin: isUser ? 0.1 : -0.1,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.aiGradient,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(
                      onPlay: (c) => c.repeat(reverse: true),
                      delay: (i * 200).ms,
                    )
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                    );
              }),
            ),
          ),
        ],
      )
          .animate()
          .fade(duration: 300.ms),
    );
  }

  Widget _buildSuggestedQuestions(BuildContext context) {
    final isDark = context.isDarkMode;
    final suggestions = _service?.suggestedQuestions ?? AiAssistantService.defaultQuestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(8),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Gợi ý cho bạn',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        const Gap(10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _sendMessage(entry.value);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.12),
                  ),
                ),
                child: Text(
                  entry.value,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
                .animate()
                .fade(duration: 300.ms, delay: (100 + entry.key * 80).ms)
                .slideY(
                  begin: 0.15,
                  end: 0,
                  duration: 300.ms,
                  delay: (100 + entry.key * 80).ms,
                );
          }).toList(),
        ),
        const Gap(16),
      ],
    );
  }

  // ─── Input Area ─────────────────────────────────────────────────────────

  Widget _buildInputArea(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFF0F0F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: context.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Hỏi về tài chính của bạn...',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      color: context.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
            ),
            const Gap(8),
            // Send button
            GestureDetector(
              onTap: () => _sendMessage(_textController.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: _isAiTyping ? null : AppColors.aiGradientSubtle,
                  color: _isAiTyping
                      ? (isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.2))
                      : null,
                  shape: BoxShape.circle,
                  boxShadow: _isAiTyping
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.aiGlow.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: _isAiTyping
                      ? context.colorScheme.onSurface.withOpacity(0.3)
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
