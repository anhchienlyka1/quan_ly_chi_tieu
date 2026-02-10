import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Danh sách chi tiêu'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: context.colorScheme.onSurface.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có chi tiêu nào',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
