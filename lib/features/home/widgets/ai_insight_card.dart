import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/smart_suggestion_model.dart';

/// AI Insight Card — hiển thị gợi ý thông minh trên Home Screen.
/// Carousel horizontal cho phép swipe qua các suggestions.
class AiInsightCard extends StatefulWidget {
  final List<SmartSuggestion> suggestions;
  final void Function(String id) onDismiss;
  final VoidCallback onOpenChat;
  final void Function(String route)? onActionTap;

  const AiInsightCard({
    super.key,
    required this.suggestions,
    required this.onDismiss,
    required this.onOpenChat,
    this.onActionTap,
  });

  @override
  State<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends State<AiInsightCard> {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getTypeColor(SuggestionType type) {
    switch (type) {
      case SuggestionType.warning:
        return AppColors.warning;
      case SuggestionType.tip:
        return AppColors.info;
      case SuggestionType.praise:
        return AppColors.success;
      case SuggestionType.insight:
        return AppColors.primary;
    }
  }

  LinearGradient _getTypeGradient(SuggestionType type) {
    switch (type) {
      case SuggestionType.warning:
        return const LinearGradient(
          colors: [Color(0xFFFF9F43), Color(0xFFEE5A6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SuggestionType.tip:
        return const LinearGradient(
          colors: [Color(0xFF54A0FF), Color(0xFF5F27CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SuggestionType.praise:
        return const LinearGradient(
          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SuggestionType.insight:
        return AppColors.aiGradientSubtle;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.aiGradientSubtle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      "Fin's Insights",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.suggestions.length > 1)
                Text(
                  '${_currentPage + 1}/${widget.suggestions.length}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: isDark ? AppColors.textLight : AppColors.textMedium,
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onOpenChat,
                child: Text(
                  'Hỏi Fin →',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Carousel
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.suggestions.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final suggestion = widget.suggestions[index];
              return _buildSuggestionCard(suggestion, isDark);
            },
          ),
        ),

        // Dots indicator
        if (widget.suggestions.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.suggestions.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : (isDark ? Colors.white24 : Colors.black12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionCard(SmartSuggestion suggestion, bool isDark) {
    final gradient = _getTypeGradient(suggestion.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getTypeColor(suggestion.type).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glassmorphism overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Emoji
                Text(suggestion.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        suggestion.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestion.description,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (suggestion.actionLabel != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: suggestion.actionRoute != null
                              ? () => widget.onActionTap?.call(suggestion.actionRoute!)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: suggestion.actionRoute != null
                                  ? Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  suggestion.actionLabel!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                if (suggestion.actionRoute != null) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 9,
                                    color: Colors.white,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dismiss button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => widget.onDismiss(suggestion.id),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
