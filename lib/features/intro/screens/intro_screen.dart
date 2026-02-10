import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/pro_button.dart';
import '../../../app/routes/route_names.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F7FA), // Very light teal
              Color(0xFFFCE4EC), // Very light pink
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // 1. Illustration Area (Composition of icons)
                _buildIllustration(context)
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.easeOutBack)
                    .fade(duration: 400.ms),
                
                const Spacer(flex: 1),

                // 2. Title & Description
                Text(
                  'Tiền bạc rõ ràng,\ngia đình nhẹ nhàng',
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    height: 1.2,
                  ),
                ).animate(delay: 300.ms).fade().slideY(begin: 0.2, end: 0),
                
                const Gap(16),
                
                Text(
                  'Cùng nhau ghi chép, thấu hiểu chi tiêu\nvà vun vén cho tổ ấm hạnh phúc. 💕',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                ).animate(delay: 500.ms).fade().slideY(begin: 0.2, end: 0),

                const Spacer(flex: 3),

                // 3. Action Button
                ProButton(
                  label: 'Bắt đầu ngay',
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, RouteNames.home);
                  },
                ).animate(delay: 700.ms).fade().slideY(begin: 0.5, end: 0),
                
                const Gap(40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(BuildContext context) {
    return SizedBox(
      height: 280,
      width: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background blobs
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.husband.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.wife.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Main Icon Composition
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heart with house
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home_rounded, // Assuming material icon or similar metaphor
                  size: 64,
                  color: AppColors.primary, // Teal
                ),
              ),
              const Gap(24),
              // Couple icons connected
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPersonIcon(Icons.person_rounded, AppColors.husband),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: AppColors.accent, // Coral
                      size: 24,
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1000.ms),
                  ),
                  _buildPersonIcon(Icons.person_rounded, AppColors.wife),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }
}
