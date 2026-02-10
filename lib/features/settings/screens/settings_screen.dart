import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Cài đặt',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fade(duration: 400.ms),
                const Gap(24),

                // Couple info card
                _buildCoupleCard(context)
                    .animate(delay: 100.ms)
                    .fade()
                    .slideY(begin: 0.1, end: 0),
                const Gap(24),

                // Settings groups
                _buildSettingsGroup(
                  context,
                  title: 'Giao diện',
                  items: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.palette_outlined,
                      iconColor: AppColors.primary,
                      label: 'Chế độ tối',
                      trailing: Switch(
                        value: context.isDarkMode,
                        activeColor: AppColors.primary,
                        onChanged: (value) {},
                      ),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.language_rounded,
                      iconColor: AppColors.info,
                      label: 'Ngôn ngữ',
                      trailing: _buildTrailingText(context, 'Tiếng Việt'),
                    ),
                  ],
                ).animate(delay: 200.ms).fade().slideY(begin: 0.1, end: 0),
                const Gap(16),

                _buildSettingsGroup(
                  context,
                  title: 'Ngân sách',
                  items: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: AppColors.warning,
                      label: 'Ngân sách hàng tháng',
                      trailing: _buildTrailingArrow(context),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.notifications_outlined,
                      iconColor: AppColors.categoryCeremony,
                      label: 'Nhắc nhở ngân sách',
                      subtitle: 'Nhắc nhở nhẹ nhàng khi gần hết ngân sách',
                      trailing: Switch(
                        value: true,
                        activeColor: AppColors.primary,
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ).animate(delay: 300.ms).fade().slideY(begin: 0.1, end: 0),
                const Gap(16),

                _buildSettingsGroup(
                  context,
                  title: 'Gia đình',
                  items: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.person_rounded,
                      iconColor: AppColors.husband,
                      label: 'Tên chồng',
                      trailing: _buildTrailingText(context, 'Minh'),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.person_rounded,
                      iconColor: AppColors.wife,
                      label: 'Tên vợ',
                      trailing: _buildTrailingText(context, 'Hạnh'),
                    ),
                  ],
                ).animate(delay: 400.ms).fade().slideY(begin: 0.1, end: 0),
                const Gap(16),

                _buildSettingsGroup(
                  context,
                  title: 'Dữ liệu',
                  items: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.download_outlined,
                      iconColor: AppColors.success,
                      label: 'Xuất dữ liệu (Excel)',
                      trailing: _buildTrailingArrow(context),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.cloud_sync_outlined,
                      iconColor: AppColors.info,
                      label: 'Đồng bộ dữ liệu',
                      trailing: _buildTrailingArrow(context),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.delete_outline_rounded,
                      iconColor: AppColors.error,
                      label: 'Xóa toàn bộ dữ liệu',
                      labelColor: AppColors.error,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.error.withOpacity(0.5),
                      ),
                    ),
                  ],
                ).animate(delay: 500.ms).fade().slideY(begin: 0.1, end: 0),
                const Gap(16),

                _buildSettingsGroup(
                  context,
                  title: 'Thông tin',
                  items: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.textLight,
                      label: 'Phiên bản',
                      trailing: _buildTrailingText(context, '1.0.0'),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.favorite_outline_rounded,
                      iconColor: AppColors.accent,
                      label: 'Đánh giá ứng dụng',
                      trailing: _buildTrailingArrow(context),
                    ),
                  ],
                ).animate(delay: 600.ms).fade().slideY(begin: 0.1, end: 0),
                const Gap(32),

                // App tagline
                Center(
                  child: Text(
                    'Cùng nhau quản lý, hạnh phúc bền lâu 💕',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withOpacity(0.3),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ).animate(delay: 700.ms).fade(),
                const Gap(40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoupleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.coupleGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Husband avatar
          _buildAvatar('M', AppColors.husband),
          const Gap(12),
          // Heart
          const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
          const Gap(12),
          // Wife avatar
          _buildAvatar('H', AppColors.wife),
          const Gap(16),
          // Names
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gia đình Minh & Hạnh',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Gap(4),
                Text(
                  'Cùng nhau quản lý tài chính',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String initial, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 13,
          ),
        ),
        const Gap(10),
        Container(
          decoration: BoxDecoration(
            color: context.theme.cardTheme.color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              return Column(
                children: [
                  entry.value,
                  if (entry.key < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: context.colorScheme.onSurface.withOpacity(0.05),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget trailing,
    Color? labelColor,
    String? subtitle,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: labelColor,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const Gap(2),
                      Text(
                        subtitle,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingText(BuildContext context, String text) {
    return Text(
      text,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurface.withOpacity(0.4),
        fontSize: 13,
      ),
    );
  }

  Widget _buildTrailingArrow(BuildContext context) {
    return Icon(
      Icons.arrow_forward_ios_rounded,
      size: 14,
      color: context.colorScheme.onSurface.withOpacity(0.25),
    );
  }
}
