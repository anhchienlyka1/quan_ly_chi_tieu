import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/models/bank_notification_model.dart';
import '../../../data/services/auto_expense_service.dart';

/// Shows the notification bottom sheet modal.
Future<bool> showNotificationBottomSheet(
    BuildContext context, {
    VoidCallback? onTransactionProcessed,
  }) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => _NotificationBottomSheet(
      onTransactionProcessed: onTransactionProcessed,
    ),
  );
  return result ?? false;
}

class _NotificationBottomSheet extends StatefulWidget {
  final VoidCallback? onTransactionProcessed;
  const _NotificationBottomSheet({this.onTransactionProcessed});

  @override
  State<_NotificationBottomSheet> createState() => _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<_NotificationBottomSheet> {
  late List<BankNotificationModel> _pending;
  late List<BankNotificationModel> _recorded;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final service = AutoExpenseService.instance;
    setState(() {
      _pending = List.from(service?.pendingNotifications ?? []);
      _recorded = (service?.allNotifications ?? [])
          .where((n) => n.isAutoRecorded)
          .toList();
    });
  }

  Future<void> _handleAccept(BankNotificationModel item) async {
    final service = AutoExpenseService.instance;
    if (service != null) {
      final success = await service.acceptTransaction(item.id);
      if (success && mounted) {
        HapticFeedback.mediumImpact();
        widget.onTransactionProcessed?.call();
        _refreshData();
      }
    }
  }

  void _handleReject(BankNotificationModel item) {
    final service = AutoExpenseService.instance;
    if (service != null) {
      HapticFeedback.lightImpact();
      service.rejectTransaction(item.id);
      widget.onTransactionProcessed?.call();
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = context.screenHeight * 0.85;

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
          _buildSheetHeader(context, _pending.length),

          // Divider
          Divider(
            height: 1,
            color: context.colorScheme.onSurface.withOpacity(0.06),
          ),

          // Content
          Flexible(
            child: (_pending.isEmpty && _recorded.isEmpty)
                ? _buildEmptyState(context)
                : _buildNotificationList(context),
          ),

          // Footer
          if (_pending.isNotEmpty || _recorded.isNotEmpty) 
            _buildFooterAction(context),
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
                  'Giao dịch chờ duyệt',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(2),
                Text(
                  pendingCount > 0
                      ? 'Bạn có $pendingCount giao dịch cần xử lý'
                      : 'Đã xử lý hết các giao dịch mới',
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
              Icons.check_circle_outline_rounded,
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
            'Không có giao dịch mới',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const Gap(8),
          Text(
            'Tuyệt vời! Bạn đã xử lý hết các thông báo\ngiao dịch từ ngân hàng.',
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

  Widget _buildNotificationList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      shrinkWrap: true,
      children: [
        // Pending section
        if (_pending.isNotEmpty) ...[
          ..._pending.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPendingCard(
                context,
                entry.value,
              )
                  .animate(delay: Duration(milliseconds: 50 * entry.key))
                  .fade()
                  .slideX(begin: 0.05, end: 0),
            );
          }),
        ],

        // Recorded section
        if (_recorded.isNotEmpty) ...[
          const Gap(12),
          _buildSectionLabel(context, 'Lịch sử gần đây', _recorded.length,
              const Color(0xFF10B981)),
          const Gap(10),
          ..._recorded.take(5).toList().asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildRecordedCard(
                context,
                entry.value,
              )
                  .animate(
                      delay: Duration(
                          milliseconds:
                              (50 * (entry.key + _pending.length)).toInt()))
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
      ],
    );
  }

  /// Compact Card for Pending Transactions (from Auto Expense Screen)
  Widget _buildPendingCard(BuildContext context, BankNotificationModel notification) {
    final isIncoming = notification.isIncoming;
    final accentColor = isIncoming
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withOpacity(0.2)
                : const Color(0xFFF59E0B).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Category icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notification.category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification.category.icon,
                  color: notification.category.color,
                  size: 20,
                ),
              ),
              const Gap(12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.parsedTitle.isNotEmpty
                          ? notification.parsedTitle
                          : notification.rawContent,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: notification.category.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notification.category.label,
                            style: context.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: notification.category.color,
                            ),
                          ),
                        ),
                        const Gap(6),
                        Icon(
                          Icons.account_balance_rounded,
                          size: 11,
                          color: context.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const Gap(3),
                        Text(
                          notification.bankName,
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: context.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(6),
              // Amount
              Text(
                '${isIncoming ? '+' : '-'}${notification.amount.toCurrency}',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Gap(10),
          // Accept/Reject buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.03)
                  : Colors.grey.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Reject button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleReject(notification),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            color: AppColors.error,
                            size: 18,
                          ),
                          const Gap(6),
                          Text(
                            'Từ chối',
                            style: context.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(8),
                // Accept button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleAccept(notification),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                          const Gap(6),
                          Text(
                            'Chấp nhận',
                            style: context.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact card for history/recorded items
  Widget _buildRecordedCard(
    BuildContext context,
    BankNotificationModel notification,
  ) {
    final isIncome = notification.isIncoming;
    final amountColor = isIncome
            ? const Color(0xFF10B981).withOpacity(0.7)
            : AppColors.error.withOpacity(0.7);
    final amountPrefix = isIncome ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: Color(0xFF10B981),
            ),
          ),
          const Gap(12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.parsedTitle.isNotEmpty
                      ? notification.parsedTitle
                      : notification.rawContent,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: context.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                // Bank + time
                Text(
                  '${notification.bankName} • ${_formatTime(notification.timestamp)}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11,
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
    );
  }

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
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: context.colorScheme.onSurface.withOpacity(0.6),
            ),
            child: Text(
              'Xem tất cả lịch sử',
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
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
