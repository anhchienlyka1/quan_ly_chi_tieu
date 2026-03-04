import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';

class SpendingForecastCard extends StatelessWidget {
  final double currentExpense;
  final DateTime now;

  const SpendingForecastCard({
    super.key,
    required this.currentExpense,
    required this.now,
  });

  int get _daysInMonth {
    return DateTime(now.year, now.month + 1, 0).day;
  }

  int get _daysElapsed => now.day;

  double get _forecastedExpense {
    if (_daysElapsed == 0) return 0;
    return (currentExpense / _daysElapsed) * _daysInMonth;
  }

  double get _dailyAvg {
    if (_daysElapsed == 0) return 0;
    return currentExpense / _daysElapsed;
  }

  int get _daysRemaining => _daysInMonth - _daysElapsed;

  @override
  Widget build(BuildContext context) {
    // Only show after at least 3 days of data
    if (_daysElapsed < 3 || currentExpense == 0) return const SizedBox.shrink();

    final forecast = _forecastedExpense;
    final dailyAvg = _dailyAvg;
    final pctProgress = _daysElapsed / _daysInMonth;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.theme.cardTheme.color
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.orange,
                  size: 18,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dự báo chi tiêu tháng này',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Dựa trên $_daysElapsed ngày đã qua',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Gap(16),

          // Forecast amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '~',
                style: context.textTheme.titleLarge?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                forecast.toCurrency,
                style: context.textTheme.headlineSmall?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          const Gap(12),

          // Month progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ngày 1',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Ngày $_daysInMonth',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const Gap(4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: pctProgress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.orange.withOpacity(0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.orange,
                      ),
                      minHeight: 8,
                    );
                  },
                ),
              ),
              const Gap(4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hôm nay: ngày $_daysElapsed',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Còn $_daysRemaining ngày',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Gap(12),

          // Daily average
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.today_rounded,
                  size: 14,
                  color: AppColors.primary.withOpacity(0.7),
                ),
                const Gap(6),
                Text(
                  'Chi tiêu trung bình/ngày: ',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  dailyAvg.toCurrency,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
