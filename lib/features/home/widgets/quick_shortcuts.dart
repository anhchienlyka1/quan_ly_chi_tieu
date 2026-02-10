import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/expense_model.dart';

/// A premium shortcut row for quick actions on the home screen.
/// Displays 4 key actions in a single horizontal row to save vertical space.
class QuickShortcuts extends StatelessWidget {
  final VoidCallback? onActionCompleted;

  const QuickShortcuts({super.key, this.onActionCompleted});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Thao tác nhanh',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Gap(16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ShortcutItem(
                icon: Icons.remove_circle_outline_rounded,
                label: 'Chi tiêu',
                iconColor: AppColors.error,
                delay: 100.ms,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await context.pushNamed(
                    RouteNames.addExpense,
                    arguments: TransactionType.expense,
                  );
                  onActionCompleted?.call();
                },
              ),
            ),
            const Gap(8),
            Expanded(
              child: _ShortcutItem(
                icon: Icons.add_circle_outline_rounded,
                label: 'Thu nhập',
                iconColor: AppColors.success,
                delay: 200.ms,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await context.pushNamed(
                    RouteNames.addExpense,
                    arguments: TransactionType.income,
                  );
                  onActionCompleted?.call();
                },
              ),
            ),
            const Gap(8),
            Expanded(
              child: _ShortcutItem(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Quét hoá đơn',
                iconColor: AppColors.info,
                delay: 300.ms,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await context.pushNamed(RouteNames.scanReceipt);
                  onActionCompleted?.call();
                },
              ),
            ),
            const Gap(8),
            Expanded(
              child: _ShortcutItem(
                icon: Icons.pie_chart_rounded,
                label: 'Thống kê',
                iconColor: AppColors.primary,
                delay: 400.ms,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await context.pushNamed(RouteNames.statistics);
                  onActionCompleted?.call();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShortcutItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final Duration delay;

  const _ShortcutItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_ShortcutItem> createState() => _ShortcutItemState();
}

class _ShortcutItemState extends State<_ShortcutItem>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          color: Colors.transparent, // Hit test target
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(
                    context.isDarkMode ? 0.15 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.iconColor.withOpacity(
                      context.isDarkMode ? 0.1 : 0.05,
                    ),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 26,
                ),
              ),
              const Gap(8),
              // Label
              Text(
                widget.label,
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurface.withOpacity(0.8),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      )
          .animate(delay: widget.delay)
          .fade(duration: 400.ms)
          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
    );
  }
}
