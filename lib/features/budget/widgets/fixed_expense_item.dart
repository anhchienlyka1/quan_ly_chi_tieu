import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/fixed_expense_model.dart';

class FixedExpenseItem extends StatelessWidget {
  final FixedExpenseModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const FixedExpenseItem({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // Provider handles actual deletion
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: context.isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isActive
                ? AppColors.primary.withOpacity(0.15)
                : context.colorScheme.onSurface.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDarkMode ? 0.15 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.category.color.withOpacity(item.isActive ? 0.15 : 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.category.icon,
              color: item.isActive
                  ? item.category.color
                  : context.colorScheme.onSurface.withOpacity(0.3),
              size: 22,
            ),
          ),
          title: Text(
            item.title,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: item.isActive
                  ? context.colorScheme.onSurface
                  : context.colorScheme.onSurface.withOpacity(0.4),
              decoration: item.isActive ? null : TextDecoration.lineThrough,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 11,
                color: context.colorScheme.onSurface.withOpacity(0.4),
              ),
              const Gap(4),
              Text(
                'Ngày ${item.dayOfMonth}',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              if (item.note != null && item.note!.isNotEmpty) ...[
                const Gap(8),
                Expanded(
                  child: Text(
                    item.note!,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onSurface.withOpacity(0.35),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt(item.amount),
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: item.isActive
                          ? AppColors.error
                          : context.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
              const Gap(4),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Switch.adaptive(
                    value: item.isActive,
                    onChanged: onToggle,
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              IconButton(
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: context.colorScheme.onSurface.withOpacity(0.4),
                ),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Tr';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
