import '../../api_request.dart';

class ApiRequestPerformance {
  Map<String?, PerformanceReport?> actionsReport = {};
  late DateTime _startTime;
  String? _actionName;
  String? _fullPath;

  static ApiRequestPerformance? _instance;

  static ApiRequestPerformance? get instance {
    if (_instance == null) {
      _instance = ApiRequestPerformance();
    }
    return _instance;
  }

  init(String? actionName, String fullPath) {
    this._actionName = actionName;
    this._fullPath = fullPath;
  }

  PerformanceReport? getReport() {
    if (!actionsReport.containsKey(this._fullPath)) {
      actionsReport[this._fullPath] = PerformanceReport(
          actionName: this._actionName, fullPath: this._fullPath);
    }
    return actionsReport[this._fullPath];
  }

  startTrack() {
    _startTime = DateTime.now();
  }

  endTrack() {
    Duration? duration = DateTime.now().difference(_startTime);
    actionsReport[this._fullPath] = PerformanceReport(
        actionName: this._actionName,
        duration: duration,
        fullPath: this._fullPath);
  }

  @override
  String toString() {
    String _string = '';
    actionsReport.forEach((key, report) {
      _string += report.toString() + '\n';
    });
    return _string;
  }
}
