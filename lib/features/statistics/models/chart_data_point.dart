class ChartDataPoint {
  final String label;
  final double value;
  final bool isToday;

  ChartDataPoint({
    required this.label,
    required this.value,
    this.isToday = false,
  });
}
