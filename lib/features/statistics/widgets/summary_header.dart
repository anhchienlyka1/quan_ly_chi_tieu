import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';

class SummaryHeader extends StatelessWidget {
  final double income;
  final double expense;
  final DateTime date;

  const SummaryHeader({
    super.key,
    required this.income,
    required this.expense,
    required this.date,
  });

  double get balance => income - expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.isDarkMode ? const Color(0xFF2C2C3E) : const Color(0xFF2E2E3E),
            context.isDarkMode ? const Color(0xFF1E1E2C) : const Color(0xFF1A1A2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Số dư khả dụng',
            style: context.textTheme.labelMedium?.copyWith(
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 0.5,
            ),
          ),
          const Gap(8),
          Text(
            balance.toCurrency,
            style: context.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const Gap(24),
          Row(
            children: [
              Expanded(
                child: _buildItem(
                  context,
                  label: 'Thu vào',
                  amount: income,
                  color: const Color(0xFF4ADE80), // Green
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: Colors.white.withOpacity(0.1),
              ),
              Expanded(
                child: _buildItem(
                  context,
                  label: 'Chi ra',
                  amount: expense,
                  color: const Color(0xFFFB7185), // Red
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const Gap(8),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const Gap(2),
        Text(
          amount.toCurrency,
          style: context.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
