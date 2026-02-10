import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Cài đặt'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSettingsGroup(
                  context,
                  title: 'Giao diện',
                  items: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.palette_outlined,
                      label: 'Chế độ tối',
                      trailing: Switch(
                        value: context.isDarkMode,
                        onChanged: (value) {
                          // TODO: Toggle theme mode
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingsGroup(
                  context,
                  title: 'Ngân sách',
                  items: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Ngân sách hàng tháng',
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: context.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.notifications_outlined,
                      label: 'Thông báo vượt ngân sách',
                      trailing: Switch(
                        value: false,
                        onChanged: (value) {
                          // TODO: Toggle notifications
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingsGroup(
                  context,
                  title: 'Dữ liệu',
                  items: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.download_outlined,
                      label: 'Xuất dữ liệu',
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: context.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                    _buildSettingsItem(
                      context,
                      icon: Icons.delete_outline_rounded,
                      label: 'Xóa toàn bộ dữ liệu',
                      labelColor: context.colorScheme.error,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: context.colorScheme.error.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingsGroup(
                  context,
                  title: 'Thông tin',
                  items: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.info_outline_rounded,
                      label: 'Phiên bản',
                      trailing: Text(
                        '1.0.0',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
            color: context.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget trailing,
    Color? labelColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: labelColor ?? context.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: labelColor,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
