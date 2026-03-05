import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service thông báo cảnh báo thông minh — dùng in-app overlay
/// thay vì push notification để tránh phải cấu hình platform phức tạp.
class SmartAlertService {
  static SmartAlertService? _instance;
  bool _enabled = true;

  SmartAlertService._();

  static SmartAlertService get instance {
    _instance ??= SmartAlertService._();
    return _instance!;
  }

  bool get isEnabled => _enabled;
  set enabled(bool value) => _enabled = value;

  /// Hiển thị cảnh báo vượt ngân sách
  static void showOverBudgetAlert(
    BuildContext context, {
    required String category,
    required double spent,
    required double budget,
  }) {
    if (!instance._enabled) return;

    final percent = ((spent / budget - 1) * 100).round();
    HapticFeedback.heavyImpact();

    _showSmartAlert(
      context,
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFEF4444),
      title: '⚠️ Vượt ngân sách!',
      message:
          'Bạn đã chi vượt $percent% ngân sách${category.isNotEmpty ? ' mục "$category"' : ''}.',
      actionLabel: 'Xem chi tiết',
      onAction: () => Navigator.of(context).pushNamed('/budget'),
    );
  }

  /// Hiển thị cảnh báo gần vượt ngân sách
  static void showNearBudgetAlert(
    BuildContext context, {
    required int percentUsed,
    required int daysRemaining,
  }) {
    if (!instance._enabled) return;

    HapticFeedback.mediumImpact();

    _showSmartAlert(
      context,
      icon: Icons.trending_up_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: '🎯 Cẩn thận ngân sách!',
      message: 'Đã dùng $percentUsed% ngân sách tuần, còn $daysRemaining ngày.',
      actionLabel: 'Xem thống kê',
      onAction: () => Navigator.of(context).pushNamed('/statistics'),
    );
  }

  /// Hiển thị cảnh báo chi tiêu tăng đột biến
  static void showSpikeAlert(
    BuildContext context, {
    required String category,
    required int percent,
  }) {
    if (!instance._enabled) return;

    HapticFeedback.lightImpact();

    _showSmartAlert(
      context,
      icon: Icons.show_chart_rounded,
      iconColor: const Color(0xFF8B5CF6),
      title: '📈 Chi tiêu tăng mạnh!',
      message: 'Mục "$category" tăng $percent% so với tuần trước.',
      actionLabel: 'Phân tích',
      onAction: () => Navigator.of(context).pushNamed('/statistics'),
    );
  }

  /// Hiển thị in-app alert banner
  static void _showSmartAlert(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _SmartAlertBanner(
        icon: icon,
        iconColor: iconColor,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: () {
          entry.remove();
          onAction?.call();
        },
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // Auto-dismiss after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (entry.mounted) entry.remove();
    });
  }
}

/// In-app alert banner widget
class _SmartAlertBanner extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _SmartAlertBanner({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_SmartAlertBanner> createState() => _SmartAlertBannerState();
}

class _SmartAlertBannerState extends State<_SmartAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -100) {
                  _dismiss();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.iconColor.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.iconColor.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withOpacity(0.6),
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Action button
                    if (widget.actionLabel != null)
                      TextButton(
                        onPressed: widget.onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: widget.iconColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          widget.actionLabel!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Close button
                    GestureDetector(
                      onTap: _dismiss,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
