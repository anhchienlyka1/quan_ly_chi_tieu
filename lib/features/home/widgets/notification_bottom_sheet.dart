import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/models/bank_notification_model.dart';
import '../../../data/services/auto_expense_service.dart';

/// Shows the notification bottom sheet modal (view-only).
/// Returns true if the user navigated to the detail screen.
Future<bool> showNotificationBottomSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => const _NotificationBottomSheet(),
  );
  return result ?? false;
}

class _NotificationBottomSheet extends StatelessWidget {
  const _NotificationBottomSheet();

  @override
  Widget build(BuildContext context) {
    final service = AutoExpenseService.instance;
    final pending = service?.pendingNotifications ?? [];
    final recorded = (service?.allNotifications ?? [])
        .where((n) => n.isAutoRecorded)
        .toList();
    final allItems = service?.allNotifications ?? [];
    final maxHeight = context.screenHeight * 0.7;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF1A1A2E)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          _buildDragHandle(context),

          // Header
          _buildSheetHeader(context, pending.length),

          // Divider
          Divider(
            height: 1,
            color: context.colorScheme.onSurface.withOpacity(0.06),
          ),

          // Content
          Flexible(
            child: allItems.isEmpty
                ? _buildEmptyState(context)
                : _buildNotificationList(context, pending, recorded),
          ),

          // Footer: navigate to detail screen
          if (pending.isNotEmpty) _buildFooterAction(context),
        ],
      ),
    )
        .animate()
        .slideY(
            begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
        .fade(duration: 200.ms);
  }

  Widget _buildDragHandle(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.colorScheme.onSurface.withOpacity(0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSheetHeader(BuildContext context, int pendingCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.sync_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const Gap(14),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đồng bộ chi tiêu',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(2),
                Text(
                  pendingCount > 0
                      ? '$pendingCount giao dịch chờ xác nhận'
                      : 'Không có giao dịch mới',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: pendingCount > 0
                        ? AppColors.warning
                        : context.colorScheme.onSurface.withOpacity(0.5),
                    fontWeight:
                        pendingCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.primary.withOpacity(0.4),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const Gap(20),
          Text(
            'Chưa có thông báo',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const Gap(8),
          Text(
            'Thông báo từ ngân hàng sẽ hiện ở đây\nkhi bật tính năng ghi chi tiêu tự động',
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.4),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    List<BankNotificationModel> pending,
    List<BankNotificationModel> recorded,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      shrinkWrap: true,
      children: [
        // Pending section
        if (pending.isNotEmpty) ...[
          _buildSectionLabel(
              context, 'Chờ xác nhận', pending.length, const Color(0xFFF59E0B)),
          const Gap(10),
          ...pending.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildNotificationCard(
                context,
                entry.value,
                isPending: true,
              )
                  .animate(delay: Duration(milliseconds: 50 * entry.key))
                  .fade()
                  .slideX(begin: 0.05, end: 0),
            );
          }),
        ],

        // Recorded section
        if (recorded.isNotEmpty) ...[
          const Gap(12),
          _buildSectionLabel(context, 'Đã ghi nhận', recorded.length,
              const Color(0xFF10B981)),
          const Gap(10),
          ...recorded.take(5).toList().asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildNotificationCard(
                context,
                entry.value,
                isPending: false,
              )
                  .animate(
                      delay: Duration(
                          milliseconds:
                              (50 * (entry.key + pending.length)).toInt()))
                  .fade()
                  .slideX(begin: 0.05, end: 0),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(8),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  /// View-only notification card — no approve/reject buttons.
  Widget _buildNotificationCard(
    BuildContext context,
    BankNotificationModel notification, {
    required bool isPending,
  }) {
    final isIncome = notification.isIncoming;
    final amountColor = isPending
        ? (isIncome ? const Color(0xFF10B981) : AppColors.error)
        : (isIncome
            ? const Color(0xFF10B981).withOpacity(0.7)
            : AppColors.error.withOpacity(0.7));
    final amountPrefix = isIncome ? '+' : '-';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop(true); // Close and signal to navigate
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? Colors.white.withOpacity(isPending ? 0.05 : 0.03)
              : Colors.grey.withOpacity(isPending ? 0.04 : 0.03),
          borderRadius: BorderRadius.circular(14),
          border: isPending
              ? Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPending
                    ? const Color(0xFFF59E0B).withOpacity(0.1)
                    : const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPending
                    ? Icons.schedule_rounded
                    : Icons.check_circle_rounded,
                size: 18,
                color: isPending
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
              ),
            ),
            const Gap(12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    notification.parsedTitle.isNotEmpty
                        ? notification.parsedTitle
                        : notification.rawContent,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isPending
                          ? null
                          : context.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  // Bank + category + time (Wrap to avoid overflow)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        notification.bankName,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color:
                              context.colorScheme.onSurface.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            notification.category.icon,
                            size: 11,
                            color: notification.category.color.withOpacity(0.8),
                          ),
                          const Gap(3),
                          Text(
                            notification.category.label,
                            style: TextStyle(
                              color: notification.category.color.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color:
                              context.colorScheme.onSurface.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        _formatTime(notification.timestamp),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  
                  // Transfer Content (Note)
                  if (notification.rawContent.isNotEmpty && 
                      notification.rawContent != notification.parsedTitle)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '"${notification.rawContent}"',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const Gap(8),
            // Amount
            Text(
              '$amountPrefix${notification.amount.toCompactCurrency}',
              style: context.textTheme.bodyMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Footer with "Xem chi tiết" button to navigate to the full AutoExpense screen.
  Widget _buildFooterAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.colorScheme.onSurface.withOpacity(0.06),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              // Close bottom sheet first, then navigate
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.open_in_new_rounded, size: 18),
                Gap(8),
                Text(
                  'Xem chi tiết & xử lý',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(delay: 200.ms, duration: 300.ms);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    if (diff.inDays < 7) return '${diff.inDays}d trước';

    return '${time.day}/${time.month}';
  }
}
