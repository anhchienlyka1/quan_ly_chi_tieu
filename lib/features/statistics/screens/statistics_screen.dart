import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thống kê'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 64,
                color: context.colorScheme.onSurface.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có dữ liệu thống kê',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy thêm chi tiêu để xem thống kê',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
