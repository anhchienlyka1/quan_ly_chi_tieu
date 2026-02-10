/// Model representing a category with aggregated stats (for statistics).
class CategoryModel {
  final String name;
  final double totalAmount;
  final int count;
  final double percentage;

  const CategoryModel({
    required this.name,
    required this.totalAmount,
    required this.count,
    required this.percentage,
  });
}
