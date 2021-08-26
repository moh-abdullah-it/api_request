class PerformanceReport {
  final String? actionName;
  final String? fullPath;
  final Duration? duration;

  PerformanceReport({required this.actionName, this.duration, this.fullPath});

  @override
  String toString() {
    return "$fullPath end in: ${duration.toString()} in $actionName";
  }
}
