import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/models/expense_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedTab = 1; // 0=Tuần, 1=Tháng, 2=Năm

  // Mock data
  final Map<ExpenseCategory, double> _categoryBreakdown = {
    ExpenseCategory.rent: 5000000,
    ExpenseCategory.food: 2500000,
    ExpenseCategory.children: 1200000,
    ExpenseCategory.utilities: 650000,
    ExpenseCategory.ceremony: 500000,
    ExpenseCategory.transport: 350000,
    ExpenseCategory.shopping: 280000,
    ExpenseCategory.other: 120000,
  };

  double get _total =>
      _categoryBreakdown.values.fold(0.0, (sum, v) => sum + v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Thống kê',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Tab selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildTabSelector(context)
                    .animate()
                    .fade(duration: 400.ms),
              ),
            ),

            // Donut Chart Placeholder
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _buildDonutChart(context)
                    .animate(delay: 100.ms)
                    .fade()
                    .scale(begin: const Offset(0.9, 0.9)),
              ),
            ),

            // Couple comparison
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildCoupleComparison(context)
                    .animate(delay: 200.ms)
                    .fade()
                    .slideY(begin: 0.1, end: 0),
              ),
            ),

            // Category breakdown title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Chi tiết theo danh mục',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate(delay: 300.ms).fade(),
              ),
            ),

            // Category breakdown list
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry =
                        _categoryBreakdown.entries.toList()[index];
                    final percentage = (entry.value / _total * 100);
                    return _buildCategoryRow(
                            context, entry.key, entry.value, percentage)
                        .animate(delay: (350 + index * 60).ms)
                        .fade()
                        .slideX(begin: 0.05, end: 0);
                  },
                  childCount: _categoryBreakdown.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: Gap(100)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context) {
    final tabs = ['Tuần', 'Tháng', 'Năm'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final isSelected = _selectedTab == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = entry.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : context.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDonutChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular chart using custom painter
          SizedBox(
            height: 200,
            width: 200,
            child: CustomPaint(
              painter: _DonutChartPainter(
                segments: _categoryBreakdown.entries
                    .map((e) => _ChartSegment(
                          value: e.value / _total,
                          color: e.key.color,
                        ))
                    .toList(),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _total.toCompactCurrency,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Tổng chi tiêu',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Gap(16),

          // Legend (top 4)
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _categoryBreakdown.entries.take(4).map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: entry.key.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Gap(6),
                  Text(
                    entry.key.label,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoupleComparison(BuildContext context) {
    const husbandTotal = 5880000.0;
    const wifeTotal = 4720000.0;
    const total = husbandTotal + wifeTotal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'So sánh chi tiêu',
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const Gap(16),

          // Husband bar
          _buildComparisonBar(
            context,
            label: 'Chồng',
            amount: husbandTotal,
            ratio: husbandTotal / total,
            color: AppColors.husband,
          ),
          const Gap(12),

          // Wife bar
          _buildComparisonBar(
            context,
            label: 'Vợ',
            amount: wifeTotal,
            ratio: wifeTotal / total,
            color: AppColors.wife,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBar(
    BuildContext context, {
    required String label,
    required double amount,
    required double ratio,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 12,
            ),
          ),
        ),
        const Gap(8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(10),
        Text(
          amount.toCompactCurrency,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: context.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    ExpenseCategory category,
    double amount,
    double percentage,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(category.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const Gap(12),

          // Label & progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.label,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      amount.toCurrency,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const Gap(6),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (percentage / 100).clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: category.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Gap(10),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: category.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Donut Chart Painter ---
class _ChartSegment {
  final double value;
  final Color color;
  _ChartSegment({required this.value, required this.color});
}

class _DonutChartPainter extends CustomPainter {
  final List<_ChartSegment> segments;

  _DonutChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;
    const gapAngle = 0.03; // Small gap between segments

    double startAngle = -1.5708; // -π/2 (start from top)

    for (final segment in segments) {
      final sweepAngle = segment.value * 2 * 3.14159265 - gapAngle;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
