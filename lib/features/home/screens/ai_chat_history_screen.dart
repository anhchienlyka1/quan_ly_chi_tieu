import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/services/ai_assistant_service.dart';
import '../../../data/services/chat_export_service.dart';
import '../../../data/services/local_storage_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AiChatHistoryScreen extends StatefulWidget {
  const AiChatHistoryScreen({super.key});

  @override
  State<AiChatHistoryScreen> createState() => _AiChatHistoryScreenState();
}

class _AiChatHistoryScreenState extends State<AiChatHistoryScreen> {
  String? _history;
  LocalStorageService? _storage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final storage = await LocalStorageService.getInstance();
    final history = storage.getConversationSummary();
    if (mounted) {
      setState(() {
        _storage = storage;
        _history = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá bộ nhớ AI?'),
        content: const Text(
          'AI sẽ quên toàn bộ ngữ cảnh và tóm tắt của các cuộc trò chuyện trước đây. Bạn có chắc chắn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = await LocalStorageService.getInstance();
      await storage.clearConversationSummary();
      if (mounted) {
        setState(() {
          _history = null;
        });
        context.showSnackBar('Đã xoá bộ nhớ AI');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bộ nhớ AI (Context)'),
        actions: [
          if (_history != null && _history!.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.error,
              ),
              onPressed: _clearHistory,
              tooltip: 'Xóa bộ nhớ',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history == null || _history!.isEmpty
          ? _buildEmptyState()
          : _buildHistoryContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.memory_rounded,
            size: 64,
            color: context.colorScheme.onSurface.withOpacity(0.2),
          ).animate().scale(
            delay: 200.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 16),
          Text(
            'AI chưa ghi nhớ gì cả',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.5),
            ),
          ).animate().fade(delay: 300.ms),
          const SizedBox(height: 8),
          Text(
            'Sau khi trò chuyện, AI sẽ tổng hợp và lưu lại ngữ cảnh tại đây.',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ).animate().fade(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildHistoryContent() {
    final localStorage = _storage;
    if (localStorage == null) return _buildEmptyState();

    final sessions = localStorage.getConversationHistory();
    if (sessions.isEmpty) return _buildEmptyState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đây là ngữ cảnh AI tự động đúc kết từ ${sessions.length} phiên chat gần nhất.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.1, end: 0, duration: 400.ms),
          const SizedBox(height: 24),

          // Feedback stats
          _buildFeedbackStats(localStorage),
          const SizedBox(height: 20),

          Text(
            'Lịch sử ghi nhớ:',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fade(delay: 200.ms),
          const SizedBox(height: 12),

          // Per-session list
          ...sessions.reversed.toList().asMap().entries.map((entry) {
            final session = entry.value;
            final ts = DateTime.tryParse(session['timestamp'] ?? '');
            final timeLabel = ts != null
                ? localStorage.formatTimeAgo(ts)
                : 'Không rõ';
            final dateLabel = ts != null
                ? '${ts.day}/${ts.month}/${ts.year} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}'
                : '';

            return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: context.theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          context.isDarkMode ? 0.2 : 0.05,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.aiGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        'Phiên chat — $timeLabel',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        dateLabel,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                      initiallyExpanded: entry.key == 0, // expand latest
                      children: [
                        Text(
                          session['summary'] ?? '',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 12,
                            height: 1.6,
                            color: context.colorScheme.onSurface.withOpacity(
                              0.8,
                            ),
                          ),
                        ),
                        if (session['messages'] != null) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showSessionDetails(
                              context,
                              session['messages'],
                              ts,
                            ),
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                            ),
                            label: const Text('Xem chi tiết hội thoại'),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                .animate()
                .fade(delay: (200 + entry.key * 100).ms)
                .slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                );
          }),
        ],
      ),
    );
  }

  Widget _buildFeedbackStats(LocalStorageService storage) {
    final stats = storage.getFeedbackStats();
    final positive = stats['positive'] ?? 0;
    final negative = stats['negative'] ?? 0;
    final total = positive + negative;

    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Đánh giá: 👍 $positive  •  👎 $negative  •  Tổng: $total',
              style: context.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 150.ms);
  }

  void _showSessionDetails(
    BuildContext context,
    List<dynamic> messagesRaw,
    DateTime? sessionTime,
  ) {
    // Convert to ChatMessage list for Export Service
    final messages = messagesRaw.map((m) {
      final map = m as Map<String, dynamic>;
      final rawActions = map['actions'] as List<dynamic>?;
      final actions = rawActions
          ?.map(
            (a) => AiAction.values.firstWhere(
              (val) => val.name == a,
              orElse: () => AiAction.none,
            ),
          )
          .toList();

      return ChatMessage(
        text: map['text'] ?? '',
        isUser: map['isUser'] == true,
        timestamp: DateTime.parse(map['timestamp']),
        actions: actions ?? [],
      );
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: BoxDecoration(
            color: ctx.theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ctx.isDarkMode
                      ? const Color(0xFF1E1E2C)
                      : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded),
                    const SizedBox(width: 12),
                    Text(
                      'Chi tiết phiên chat',
                      style: ctx.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      tooltip: 'Xuất PDF',
                      onPressed: () async {
                        try {
                          await ChatExportService().exportAndSharePdf(
                            messages: messages,
                            sessionTime: sessionTime ?? DateTime.now(),
                          );
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Lỗi xuất file: $e')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded),
                      tooltip: 'Chia sẻ Text',
                      onPressed: () async {
                        try {
                          await ChatExportService().exportAndShareText(
                            messages: messages,
                            sessionTime: sessionTime ?? DateTime.now(),
                          );
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Lỗi chia sẻ: $e')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (ctx, index) {
                    final msg = messages[index];
                    final isUser = msg.isUser;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppColors.primary
                              : (ctx.isDarkMode
                                    ? Colors.white10
                                    : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isUser
                                ? const Radius.circular(4)
                                : null,
                            bottomLeft: !isUser
                                ? const Radius.circular(4)
                                : null,
                          ),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : ctx.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
