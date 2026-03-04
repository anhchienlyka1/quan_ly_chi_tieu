import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../models/chart_data_point.dart';
import '../screens/statistics_screen.dart';

class DailyBarChart extends StatefulWidget {
  final List<ChartDataPoint> data;
  final double maxHeight;
  final StatsPeriod period;

  const DailyBarChart({
    super.key,
    required this.data,
    required this.period,
    this.maxHeight = 200,
  });

  @override
  State<DailyBarChart> createState() => _DailyBarChartState();
}

class _DailyBarChartState extends State<DailyBarChart> {
  int? _selectedIndex;

  String get _chartTitle {
    switch (widget.period) {
      case StatsPeriod.week:
        return 'Chi tiêu 7 ngày qua';
      case StatsPeriod.month:
        return 'Chi tiêu theo tuần';
      case StatsPeriod.year:
        return 'Chi tiêu theo tháng';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final maxValue = widget.data
        .map((e) => e.value)
        .reduce((curr, next) => curr > next ? curr : next);
    final safeMax = maxValue == 0 ? 1.0 : maxValue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: widget.maxHeight,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _chartTitle,
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
                // Narrow bars for year view (12 items)
                final barWidth = widget.period == StatsPeriod.year ? 8.0 : 12.0;

                return Expanded(
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _selectedIndex = index),
                    onTapUp: (_) => setState(() => _selectedIndex = null),
                    onTapCancel: () => setState(() => _selectedIndex = null),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: barWidth,
                                decoration: BoxDecoration(
                                  color: context.isDarkMode
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              FractionallySizedBox(
                                heightFactor: heightPercentage == 0
                                    ? 0.02
                                    : heightPercentage,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                  width: barWidth,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (item.isToday
                                              ? AppColors.primary.withOpacity(
                                                  0.8,
                                                )
                                              : AppColors.primary.withOpacity(
                                                  0.3,
                                                )),
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
                        const Gap(8),
                        Text(
                          item.label,
                          style: context.textTheme.labelSmall?.copyWith(
                            fontSize: widget.period == StatsPeriod.year
                                ? 9
                                : 10,
                            fontWeight: item.isToday || isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: item.isToday || isSelected
                                ? context.colorScheme.onSurface
                                : context.colorScheme.onSurface.withOpacity(
                                    0.5,
                                  ),
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
