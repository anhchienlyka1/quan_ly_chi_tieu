import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/smart_suggestion_model.dart';
import '../../../data/services/ai_assistant_service.dart';
import '../../../data/services/budget_service.dart';
import '../../../data/services/intent_classifier_service.dart';
import '../../../data/services/local_storage_service.dart';

/// Shows the AI chat assistant bottom sheet
Future<void> showAiAssistantSheet(
  BuildContext context, {
  required List<ExpenseModel> expenses,
  required double totalBalance,
  required BudgetProgress? budgetProgress,
  FinancialGoal? goal,
  List<SmartSuggestion>? suggestions,
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
      goal: goal,
      suggestions: suggestions,
    ),
  );
}

class _AiChatSheet extends StatefulWidget {
  final List<ExpenseModel> expenses;
  final double totalBalance;
  final BudgetProgress? budgetProgress;
  final FinancialGoal? goal;
  final List<SmartSuggestion>? suggestions;

  const _AiChatSheet({
    required this.expenses,
    required this.totalBalance,
    required this.budgetProgress,
    this.goal,
    this.suggestions,
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
  final Set<int> _ratedMessageIndices = {}; // Track rated messages
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
    // Save session summary khi đóng popup
    _saveSessionOnClose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _glowController.dispose();
    super.dispose();
  }

  /// Lưu tóm tắt phiên chat khi đóng popup
  void _saveSessionOnClose() {
    if (_service != null && _messages.length >= 3) {
      // Fire and forget — không cần await
      _service!.saveSessionSummary(_messages);
    }
  }

  Future<void> _initChat() async {
    try {
      _service = await AiAssistantService.getInstance();

      // Show typing indicator while AI generates proactive welcome
      if (mounted) setState(() => _isAiTyping = true);

      final aiResponse = await _service!.startNewSession(
        expenses: widget.expenses,
        totalBalance: widget.totalBalance,
        monthlyBudget: widget.budgetProgress?.budget.totalBudget ?? 0,
        categoryBudgets: widget.budgetProgress?.budget.categoryBudgets,
        goal: widget.goal,
        suggestions: widget.suggestions,
      );

      if (mounted) {
        setState(() {
          _isAiTyping = false;
          _messages.add(
            ChatMessage(
              text: aiResponse.text,
              isUser: false,
              timestamp: DateTime.now(),
              actions: aiResponse.actions,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAiTyping = false;
          _messages.add(
            ChatMessage(
              text:
                  '⚠️ Không thể kết nối AI. Vui lòng kiểm tra kết nối mạng hoặc API key.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isAiTyping) return;

    final userMsg = text.trim();
    _textController.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: userMsg, isUser: true, timestamp: DateTime.now()),
      );
    });

    _scrollToBottom();

    // ─── Intent Classification ─────────────────────────────────
    final intent = IntentClassifierService.classify(userMsg);

    if (intent != IntentType.query) {
      // Direct action — no AI call needed
      final confirmation = IntentClassifierService.confirmationMessage(intent);
      final route = IntentClassifierService.routeName(intent);

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: confirmation,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }

      // Small delay for user to see the message
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(route);
      }
      return;
    }

    // ─── AI Query ─────────────────────────────────────────────
    if (_service == null) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Chưa kết nối được AI. Vui lòng kiểm tra API key.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
      return;
    }

    setState(() => _isAiTyping = true);

    final aiMessageIndex = _messages.length;
    setState(() {
      _messages.add(
        ChatMessage(
          text: '', // Start empty for streaming
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    String fullText = '';
    try {
      await for (final chunk in _service!.sendMessageStream(userMsg)) {
        fullText += chunk;
        if (mounted) {
          setState(() {
            _messages[aiMessageIndex] = _messages[aiMessageIndex].copyWith(
              text: fullText,
            );
          });
          _scrollToBottom();
        }
      }

      if (mounted && fullText.isNotEmpty) {
        final actions = _service!.parseActionsFromText(fullText);
        setState(() {
          _messages[aiMessageIndex] = _messages[aiMessageIndex].copyWith(
            actions: actions,
          );
          _isAiTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages[aiMessageIndex] = _messages[aiMessageIndex].copyWith(
            text: '$fullText\n⚠️ Đã có lỗi xảy ra trong lúc nhận tin nhắn.',
          );
          _isAiTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  /// Xử lý khi user tap vào action chip
  void _handleAction(AiAction action) {
    HapticFeedback.mediumImpact();
    // Đóng bottom sheet trước
    Navigator.of(context).pop();
    // Navigate tới screen tương ứng
    Navigator.of(context).pushNamed(action.routeName);
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
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(RouteNames.aiHistory);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colorScheme.onSurface.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: context.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
              const Gap(8),
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
      itemCount:
          _messages.length +
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
    BuildContext context,
    ChatMessage message,
    int index,
  ) {
    final isDark = context.isDarkMode;
    final isUser = message.isUser;

    return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                                : Colors.black.withOpacity(
                                    isDark ? 0.15 : 0.04,
                                  ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isUser
                          ? Text(
                              message.text,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.white,
                              ),
                            )
                          : _buildRichText(
                              message.text,
                              context.colorScheme.onSurface.withOpacity(0.9),
                            ),
                    ),
                  ),
                  if (isUser) const Gap(8),
                ],
              ),

              // Action Chips
              if (!isUser && message.actions.isNotEmpty)
                _buildActionChips(context, message.actions),

              // Feedback loop for AI messages
              if (!isUser && message.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 4),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _ratedMessageIndices.contains(index)
                            ? null
                            : () async {
                                HapticFeedback.lightImpact();
                                setState(() => _ratedMessageIndices.add(index));
                                final storage =
                                    await LocalStorageService.getInstance();
                                await storage.saveFeedback(isPositive: true);
                                if (mounted) context.showSnackBar('Cảm ơn! 😊');
                              },
                        child: Icon(
                          _ratedMessageIndices.contains(index)
                              ? Icons.thumb_up_rounded
                              : Icons.thumb_up_outlined,
                          size: 14,
                          color: _ratedMessageIndices.contains(index)
                              ? AppColors.success
                              : AppColors.primary.withOpacity(0.5),
                        ),
                      ),
                      const Gap(12),
                      GestureDetector(
                        onTap: _ratedMessageIndices.contains(index)
                            ? null
                            : () async {
                                HapticFeedback.lightImpact();
                                setState(() => _ratedMessageIndices.add(index));
                                final storage =
                                    await LocalStorageService.getInstance();
                                await storage.saveFeedback(isPositive: false);
                                if (mounted) {
                                  context.showSnackBar('Cảm ơn góp ý! 🙏');
                                }
                              },
                        child: Icon(
                          _ratedMessageIndices.contains(index)
                              ? Icons.thumb_down_rounded
                              : Icons.thumb_down_outlined,
                          size: 14,
                          color: _ratedMessageIndices.contains(index)
                              ? AppColors.error.withOpacity(0.6)
                              : AppColors.primary.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 500.ms),
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

  // ─── Rich Text Parser ─────────────────────────────────────────────────

  /// Parse **bold** text and • bullets thành rich TextSpan
  Widget _buildRichText(String text, Color baseColor) {
    final spans = <TextSpan>[];
    final boldPattern = RegExp(r'\*\*(.+?)\*\*');

    // Split text by lines to handle bullets
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));

      final line = lines[i];

      // Process bold text within each line
      int lastEnd = 0;
      for (final match in boldPattern.allMatches(line)) {
        // Text before bold
        if (match.start > lastEnd) {
          spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
        }
        // Bold text
        spans.add(
          TextSpan(
            text: match.group(1),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
        lastEnd = match.end;
      }
      // Remaining text after last bold
      if (lastEnd < line.length) {
        spans.add(TextSpan(text: line.substring(lastEnd)));
      }
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.outfit(fontSize: 14, height: 1.5, color: baseColor),
        children: spans,
      ),
    );
  }

  // ─── Action Chips ──────────────────────────────────────────────────────

  Widget _buildActionChips(BuildContext context, List<AiAction> actions) {
    final isDark = context.isDarkMode;

    return Padding(
          padding: const EdgeInsets.only(
            left: 40,
            top: 8,
          ), // align with AI bubble
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: actions.map((action) {
              return OutlinedButton.icon(
                onPressed: () => _handleAction(action),
                icon: Icon(action.icon, size: 16),
                label: Text(action.label),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.2),
                  ),
                  backgroundColor: AppColors.primary.withOpacity(
                    isDark ? 0.08 : 0.04,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        )
        .animate()
        .fade(duration: 300.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: 200.ms);
  }

  // ─── Typing Indicator ──────────────────────────────────────────────────

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
      ).animate().fade(duration: 300.ms),
    );
  }

  Widget _buildSuggestedQuestions(BuildContext context) {
    final isDark = context.isDarkMode;
    final suggestions =
        _service?.suggestedQuestions ?? AiAssistantService.defaultQuestions;

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(
                          isDark ? 0.2 : 0.12,
                        ),
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
