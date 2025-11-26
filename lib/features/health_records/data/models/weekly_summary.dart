class WeeklySummary {
  final int totalSteps;
  final int totalCalories;
  final int totalWater;
  final int daysTracked;
  final String? bestStepsDay;
  final int bestStepsValue;

  const WeeklySummary({
    required this.totalSteps,
    required this.totalCalories,
    required this.totalWater,
    required this.daysTracked,
    required this.bestStepsDay,
    required this.bestStepsValue,
  });

  double get averageSteps => daysTracked == 0 ? 0 : totalSteps / daysTracked;

  double get averageCalories => daysTracked == 0 ? 0 : totalCalories / daysTracked;

  double get averageWater => daysTracked == 0 ? 0 : totalWater / daysTracked;
}

