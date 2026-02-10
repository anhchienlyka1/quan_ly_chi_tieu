import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../models/chart_data_point.dart';

class DailyBarChart extends StatefulWidget {
  final List<ChartDataPoint> data;
  final double maxHeight;

  const DailyBarChart({
    super.key,
    required this.data,
    this.maxHeight = 200,
  });

  @override
  State<DailyBarChart> createState() => _DailyBarChartState();
}

class _DailyBarChartState extends State<DailyBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    // Calculate max value for scaling
    final maxValue = widget.data
        .map((e) => e.value)
        .reduce((curr, next) => curr > next ? curr : next);
    // Avoid division by zero
    final safeMax = maxValue == 0 ? 1.0 : maxValue;

    return Container(
      height: widget.maxHeight,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(
        color: context.isDarkMode ? context.theme.cardTheme.color : Colors.white,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chi tiêu 7 ngày qua',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedIndex != null)
                Text(
                  widget.data[_selectedIndex!].value.toCurrency,
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
                    .animate(key: ValueKey(_selectedIndex))
                    .fadeIn()
                    .slideX(begin: 0.1, end: 0),
            ],
          ),
          const Gap(24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: widget.data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final heightPercentage = item.value / safeMax;
                final isSelected = _selectedIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _selectedIndex = index),
                    onTapUp: (_) => setState(() => _selectedIndex = null),
                    onTapCancel: () => setState(() => _selectedIndex = null),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Bar
                        Flexible(
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Background track (optional)
                              Container(
                                width: 12,
                                decoration: BoxDecoration(
                                  color: context.isDarkMode
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              // Animated Bar
                              FractionallySizedBox(
                                heightFactor: heightPercentage == 0 ? 0.02 : heightPercentage,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  width: 12,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (item.isToday
                                            ? AppColors.primary.withOpacity(0.8)
                                            : AppColors.primary.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: isSelected || item.isToday
                                        ? AppColors.primaryGradient
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(12),
                        // Label
                        Text(
                          item.label,
                          style: context.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: item.isToday || isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: item.isToday || isSelected
                                ? context.colorScheme.onSurface
                                : context.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
