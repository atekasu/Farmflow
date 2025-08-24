// Rules for evaluating maintenance/inspection thresholds across components
class MaintenanceRules {
  const MaintenanceRules({
    this.yellowThreshold = 0.3,
    this.criticalThreshold = 0.2,
    this.inspectionMaxDaysWarning = 30,
    this.inspectionMaxDaysCritical = 60,
  });

  /// If the remaining ratio is below this value, treat as warning (e.g., 0.2 = 20%)
  final double yellowThreshold;

  /// If the remaining ratio is below this value, treat as critical (e.g., 0.2 = 20%)
  final double criticalThreshold;

  /// For inspection-only items: days after last inspection to be considered warning
  final int inspectionMaxDaysWarning;

  /// For inspection-only items: days after last inspection to be considered critical
  final int inspectionMaxDaysCritical;
}
