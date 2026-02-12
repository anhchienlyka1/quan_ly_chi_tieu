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

  /// New Designed Card for Pending Transactions
  Widget _buildPendingCard(BuildContext context, BankNotificationModel notification) {
    final isIncome = notification.isIncoming;
    final amountColor = isIncome ? const Color(0xFF10B981) : AppColors.error;
    final amountPrefix = isIncome ? '+' : '-';
    final category = notification.category;

    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Icon - Title - Amount
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    size: 20,
                    color: category.color,
                  ),
                ),
                const Gap(12),
                // Title & Time column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncome ? 'Nhận tiền' : 'Chuyển tiền',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Gap(2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 10,
                            color: context.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const Gap(4),
                          Text(
                            _formatTime(notification.timestamp),
                            style: context.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: context.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  '$amountPrefix${notification.amount.toCompactCurrency}',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: context.colorScheme.onSurface.withOpacity(0.05),
            indent: 16,
            endIndent: 16,
          ),

          // 2. Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Bank
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.colorScheme.onSurface.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        size: 16,
                        color: context.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        notification.bankName,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                
                // Raw Content Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colorScheme.onSurface.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.colorScheme.onSurface.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nội dung giao dịch',
                        style: context.textTheme.labelSmall?.copyWith(
                           color: context.colorScheme.onSurface.withOpacity(0.5),
                           fontSize: 10,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        notification.rawContent,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const Gap(12),

                // AI Category Detection
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const Gap(8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.onSurface,
                            ),
                            children: [
                              TextSpan(
                                text: 'Loại giao dịch: ',
                                style: TextStyle(
                                  color: context.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              TextSpan(
                                text: category.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: 'Từ chối',
                    icon: Icons.close_rounded,
                    color: AppColors.error,
                    onTap: () => _handleReject(notification),
                    isPrimary: false,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: 'Chấp nhận',
                    icon: Icons.check_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => _handleAccept(notification),
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary ? Colors.transparent : context.colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                size: 18, 
                color: isPrimary ? color : context.colorScheme.onSurface.withOpacity(0.6)
              ),
              const Gap(8),
              Text(
                label,
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? color : context.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
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
