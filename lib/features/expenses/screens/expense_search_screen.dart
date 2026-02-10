import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/expense_model.dart';
import '../../../app/routes/route_names.dart';
import '../widgets/expense_item.dart';

class ExpenseSearchScreen extends StatefulWidget {
  final List<ExpenseModel> allExpenses;
  final Function(ExpenseModel) onDelete;
  final Function() onUpdate;

  const ExpenseSearchScreen({
    super.key,
    required this.allExpenses,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<ExpenseSearchScreen> createState() => _ExpenseSearchScreenState();
}

class _ExpenseSearchScreenState extends State<ExpenseSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<ExpenseModel> _searchResults = [];
  String _query = '';
  String _selectedFilter = 'all'; // 'all', 'expense', 'income', 'high_value'

  @override
  void initState() {
    super.initState();
    _searchResults = widget.allExpenses;
    _searchController.addListener(_onSearchChanged);
    
    // Auto focus with a slight delay for better transition
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text.toLowerCase();
      _filterExpenses();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterExpenses();
    });
  }

  void _filterExpenses() {
    _searchResults = widget.allExpenses.where((e) {
      // 1. Text Search
      final title = e.title.toLowerCase();
      final note = e.note?.toLowerCase() ?? '';
      final amount = e.amount.toString();
      final category = e.category.label.toLowerCase();
      
      final matchesQuery = _query.isEmpty || 
             title.contains(_query) || 
             note.contains(_query) || 
             amount.contains(_query) ||
             category.contains(_query);

      if (!matchesQuery) return false;

      // 2. Type Filter
      if (_selectedFilter == 'expense') return e.type == TransactionType.expense;
      if (_selectedFilter == 'income') return e.type == TransactionType.income;
      if (_selectedFilter == 'high_value') return e.amount >= 500000;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const Gap(16),
            // 1. Search Bar Area
            _buildSearchBar(context),
            
            const Gap(16),
            
            // 2. Filter Chips
            _buildFilterChips(context),

            const Gap(8),

            // 3. Results List
            Expanded(
              child: _searchResults.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final expense = _searchResults[index];
                        return ExpenseItem(
                          expense: expense,
                          index: index,
                          onDelete: (e) {
                            widget.onDelete(e);
                            setState(() {
                              _searchResults.removeWhere((item) => item.id == e.id);
                            });
                          },
                          onTap: () async {
                            final result = await context.pushNamed(
                              RouteNames.addExpense,
                              arguments: expense,
                            );
                            if (result == true) {
                              widget.onUpdate();
                              // In a real app, we would reload content here
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: context.isDarkMode 
                    ? context.theme.cardTheme.color 
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: context.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.colorScheme.primary,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, 
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const Gap(12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Hủy',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: -0.5, end: 0, duration: 400.ms);
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = [
      {'id': 'all', 'label': 'Tất cả'},
      {'id': 'expense', 'label': 'Chi tiêu'},
      {'id': 'income', 'label': 'Thu nhập'},
      {'id': 'high_value', 'label': '> 500k'},
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const Gap(8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['id'];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _onFilterChanged(filter['id'] as String);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? context.colorScheme.primary 
                    : context.isDarkMode 
                        ? context.theme.cardTheme.color 
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected 
                    ? [
                        BoxShadow(
                          color: context.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                filter['label'] as String,
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected 
                      ? Colors.white 
                      : context.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fade(delay: 100.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _query.isEmpty ? Icons.search_rounded : Icons.search_off_rounded,
              size: 56,
              color: context.colorScheme.primary.withOpacity(0.5),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
          
          const Gap(24),
          
          Text(
            _query.isEmpty ? 'Nhập từ khóa để tìm kiếm' : 'Không tìm thấy kết quả',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const Gap(8),
          Text(
            _query.isEmpty 
                ? 'Tìm theo tên, ghi chú, số tiền hoặc danh mục' 
                : 'Thử tìm với từ khóa khác xem sao',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    ).animate().fade().scale(duration: 400.ms);
  }
}
