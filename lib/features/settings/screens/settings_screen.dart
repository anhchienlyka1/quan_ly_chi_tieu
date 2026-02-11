import 'package:flutter/material.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Premium Gradient Header
            SliverToBoxAdapter(
              child: _buildGradientHeader(context),
            ),
            
            // Settings Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Single level list - no groups
                        Container(
                          decoration: BoxDecoration(
                            color: context.theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: context.isDarkMode 
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ListenableBuilder(
                                listenable: themeProvider,
                                builder: (context, _) {
                                  return _buildSettingsItem(
                                    context,
                                    icon: Icons.dark_mode_rounded,
                                    label: 'Chế độ tối',
                                    subtitle: _getThemeModeLabel(themeProvider.themeMode),
                                    iconColor: const Color(0xFF6366F1),
                                    trailing: _buildModernSwitch(
                                      value: themeProvider.isDarkMode,
                                      onChanged: (value) {
                                        themeProvider.toggleDarkMode();
                                      },
                                      activeColor: const Color(0xFF6366F1),
                                    ),
                                    onTap: () => _showThemeModeSelector(context),
                                  );
                                },
                              ),
                              _buildDivider(context),
                              
                              _buildSettingsItem(
                                context,
                                icon: Icons.savings_rounded,
                                label: 'Ngân sách hàng tháng',
                                subtitle: 'Thiết lập ngân sách',
                                iconColor: const Color(0xFF10B981),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                onTap: () => context.pushNamed(RouteNames.budget),
                              ),
                              _buildDivider(context),
                              
                              _buildSettingsItem(
                                context,
                                icon: Icons.notifications_active_rounded,
                                label: 'Thông báo vượt ngân sách',
                                subtitle: 'Nhận cảnh báo khi chi quá mức',
                                iconColor: const Color(0xFFF59E0B),
                                trailing: _buildModernSwitch(
                                  value: false,
                                  onChanged: (value) {
                                    // TODO: Toggle notifications
                                  },
                                  activeColor: const Color(0xFFF59E0B),
                                ),
                              ),
                              _buildDivider(context),
                              
                              _buildSettingsItem(
                                context,
                                icon: Icons.auto_mode_rounded,
                                label: 'Ghi chi tiêu tự động',
                                subtitle: 'Từ thông báo ngân hàng',
                                iconColor: const Color(0xFFEC4899),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                onTap: () => context.pushNamed(RouteNames.autoExpense),
                              ),
                              _buildDivider(context),
                              
                              _buildSettingsItem(
                                context,
                                icon: Icons.download_rounded,
                                label: 'Xuất dữ liệu',
                                subtitle: 'Excel, CSV, PDF',
                                iconColor: const Color(0xFF14B8A6),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              _buildDivider(context),
                              
                              _buildSettingsItem(
                                context,
                                icon: Icons.delete_sweep_rounded,
                                label: 'Xóa toàn bộ dữ liệu',
                                subtitle: 'Không thể khôi phục',
                                iconColor: const Color(0xFFEF4444),
                                labelColor: context.colorScheme.error,
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: context.colorScheme.error.withOpacity(0.5),
                                ),
                              ),
                              _buildDivider(context),
                              
                              _buildSettingsItem(
                                context,
                                icon: Icons.info_rounded,
                                label: 'Phiên bản',
                                subtitle: 'Cập nhật mới nhất',
                                iconColor: const Color(0xFF06B6D4),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF06B6D4).withOpacity(0.2),
                                        const Color(0xFF3B82F6).withOpacity(0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '1.0.0',
                                    style: context.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF06B6D4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Sign Out Button with premium design
                        _buildSignOutButton(context),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDarkMode
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ]
              : [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cài đặt',
                            style: context.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tùy chỉnh trải nghiệm của bạn',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.settings_suggest_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 70),
      child: Divider(
        height: 1,
        thickness: 1,
        color: context.colorScheme.onSurface.withOpacity(0.05),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color iconColor,
    required Widget trailing,
    Color? labelColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon with colored background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withOpacity(0.2),
                      iconColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              
              // Label and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: labelColor ?? context.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        activeTrackColor: activeColor.withOpacity(0.5),
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Chế độ sáng';
      case ThemeMode.dark:
        return 'Chế độ tối';
      case ThemeMode.system:
        return 'Theo hệ thống';
    }
  }

  void _showThemeModeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ThemeModeSelectorSheet(),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colorScheme.error.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Show sign out confirmation dialog
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: context.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Đăng xuất',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium bottom sheet for selecting theme mode
class _ThemeModeSelectorSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            'Chọn giao diện',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tùy chỉnh giao diện ứng dụng theo ý bạn',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),

          // Theme options
          ListenableBuilder(
            listenable: themeProvider,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildThemeOption(
                      context,
                      icon: Icons.light_mode_rounded,
                      label: 'Sáng',
                      subtitle: 'Giao diện sáng truyền thống',
                      mode: ThemeMode.light,
                      isSelected: themeProvider.themeMode == ThemeMode.light,
                      gradientColors: [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
                    ),
                    const SizedBox(height: 12),
                    _buildThemeOption(
                      context,
                      icon: Icons.dark_mode_rounded,
                      label: 'Tối',
                      subtitle: 'Bảo vệ mắt trong bóng tối',
                      mode: ThemeMode.dark,
                      isSelected: themeProvider.themeMode == ThemeMode.dark,
                      gradientColors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                    ),
                    const SizedBox(height: 12),
                    _buildThemeOption(
                      context,
                      icon: Icons.settings_suggest_rounded,
                      label: 'Theo hệ thống',
                      subtitle: 'Tự động theo cài đặt thiết bị',
                      mode: ThemeMode.system,
                      isSelected: themeProvider.themeMode == ThemeMode.system,
                      gradientColors: [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
                    ),
                  ],
                ),
              );
            },
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required ThemeMode mode,
    required bool isSelected,
    required List<Color> gradientColors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          themeProvider.setThemeMode(mode);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? gradientColors[0].withOpacity(0.1)
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? gradientColors[0].withOpacity(0.5)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? gradientColors
                        : [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? gradientColors[0]
                            : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Checkmark
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

