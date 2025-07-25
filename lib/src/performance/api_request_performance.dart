import '../../api_request.dart';

/// A singleton service for tracking API request performance metrics.
///
/// This class automatically monitors the performance of all API requests made
/// through [RequestAction] and provides detailed timing reports. It's designed
/// to help developers identify performance bottlenecks and optimize their API usage.
///
/// ## Automatic Tracking
///
/// Performance tracking is automatically enabled for all requests and works
/// transparently without requiring any additional code:
///
/// ```dart
/// // Performance is automatically tracked
/// final result = await GetPostsAction().execute();
///
/// // Access the performance report
/// final report = action.performanceReport;
/// print('Request took: ${report?.duration?.inMilliseconds}ms');
/// ```
///
/// ## Global Performance Overview
///
/// Get performance data for all requests that have been made:
///
/// ```dart
/// final performance = ApiRequestPerformance.instance;
///
/// // Print all performance reports
/// print('All API Performance:');
/// print(performance.toString());
///
/// // Access individual reports
/// performance.actionsReport.forEach((url, report) {
///   if (report?.duration != null && report!.duration!.inSeconds > 2) {
///     print('Slow request: ${report.actionName} - ${report.duration}');
///   }
/// });
/// ```
///
/// ## Performance Analysis
///
/// Use the collected data to identify patterns and optimize performance:
///
/// ```dart
/// final performance = ApiRequestPerformance.instance;
/// final reports = performance.actionsReport.values
///   .where((report) => report?.duration != null)
///   .toList();
///
/// // Find slowest requests
/// reports.sort((a, b) => b!.duration!.compareTo(a!.duration!));
/// print('Slowest requests:');
/// reports.take(5).forEach((report) {
///   print('${report!.actionName}: ${report.duration}');
/// });
///
/// // Calculate average request time
/// final avgMs = reports
///   .map((r) => r!.duration!.inMilliseconds)
///   .reduce((a, b) => a + b) / reports.length;
/// print('Average request time: ${avgMs.round()}ms');
/// ```
///
/// ## Integration with Monitoring
///
/// Integrate with analytics or monitoring services:
///
/// ```dart
/// class PerformanceMonitor {
///   static void trackSlowRequests() {
///     final performance = ApiRequestPerformance.instance;
///
///     performance.actionsReport.forEach((url, report) {
///       if (report?.duration != null && report!.duration!.inSeconds > 3) {
///         Analytics.track('slow_api_request', {
///           'action': report.actionName,
///           'url': report.fullPath,
///           'duration_ms': report.duration!.inMilliseconds,
///         });
///       }
///     });
///   }
/// }
/// ```
///
/// ## Data Persistence
///
/// The performance data is stored in memory during the app session. Reports
/// persist until the app is restarted, allowing you to analyze performance
/// across multiple requests.
///
/// ## Thread Safety
///
/// The singleton is designed to be thread-safe for typical Flutter usage
/// patterns, though heavy concurrent usage might require additional
/// synchronization.
///
/// See also:
/// - [PerformanceReport] for individual request metrics
/// - [RequestAction.performanceReport] for accessing action-specific reports
class ApiRequestPerformance {
  /// Map of all performance reports indexed by request URL.
  ///
  /// Each entry contains the performance report for a specific API endpoint.
  /// If the same URL is requested multiple times, only the most recent
  /// report is stored.
  ///
  /// Example usage:
  /// ```dart
  /// final reports = ApiRequestPerformance.instance!.actionsReport;
  /// reports.forEach((url, report) {
  ///   print('$url: ${report?.duration}');
  /// });
  /// ```
  Map<String?, PerformanceReport?> actionsReport = {};

  /// The timestamp when the current request tracking started
  late DateTime _startTime;

  /// The name/type of the current action being tracked
  String? _actionName;

  /// The full URL path of the current request being tracked
  String? _fullPath;

  /// The singleton instance of the performance tracker
  static ApiRequestPerformance? _instance;

  /// Gets the singleton instance of the performance tracker.
  ///
  /// Creates a new instance if one doesn't exist. This ensures that
  /// performance data is collected globally across all API requests
  /// in the application.
  ///
  /// Example:
  /// ```dart
  /// final performance = ApiRequestPerformance.instance;
  /// print('Total tracked requests: ${performance?.actionsReport.length}');
  /// ```
  ///
  /// Returns the singleton [ApiRequestPerformance] instance.
  static ApiRequestPerformance? get instance {
    if (_instance == null) {
      _instance = ApiRequestPerformance();
    }
    return _instance;
  }

  /// Initializes tracking for a new request.
  ///
  /// This method is called by [RequestAction] before making an HTTP request
  /// to set up the tracking context. It stores the action name and full URL
  /// for later use in the performance report.
  ///
  /// Parameters:
  /// - [actionName]: The name/type of the action making the request
  /// - [fullPath]: The complete URL being requested
  ///
  /// This method is typically called internally and not used directly
  /// by application code.
  ///
  /// Example (internal usage):
  /// ```dart
  /// performance.init('GetPostsAction', 'https://api.example.com/posts');
  /// ```
  init(String? actionName, String fullPath) {
    this._actionName = actionName;
    this._fullPath = fullPath;
  }

  /// Gets or creates a performance report for the current request.
  ///
  /// This method returns the performance report for the currently tracked
  /// request. If no report exists for the current URL, it creates a new
  /// one with the initialized action name and path.
  ///
  /// The report initially has no duration (request not completed). The
  /// duration is added when [endTrack] is called.
  ///
  /// Returns the [PerformanceReport] for the current request.
  ///
  /// This method is typically called internally by [RequestAction] to
  /// access the performance report after request completion.
  ///
  /// Example (internal usage):
  /// ```dart
  /// final report = performance.getReport();
  /// // report.duration will be null until endTrack() is called
  /// ```
  PerformanceReport? getReport() {
    if (!actionsReport.containsKey(this._fullPath)) {
      actionsReport[this._fullPath] = PerformanceReport(
          actionName: this._actionName, fullPath: this._fullPath);
    }
    return actionsReport[this._fullPath];
  }

  /// Starts timing measurement for the current request.
  ///
  /// This method records the current timestamp as the start time for
  /// performance measurement. It's called by [RequestAction] just before
  /// making the HTTP request.
  ///
  /// The start time is used later by [endTrack] to calculate the total
  /// request duration.
  ///
  /// This method is typically called internally and not used directly
  /// by application code.
  ///
  /// Example (internal usage):
  /// ```dart
  /// performance.startTrack(); // Records start time
  /// // ... HTTP request is made ...
  /// performance.endTrack();   // Calculates duration
  /// ```
  startTrack() {
    _startTime = DateTime.now();
  }

  /// Completes timing measurement and creates the final performance report.
  ///
  /// This method calculates the total request duration by comparing the
  /// current time with the start time recorded by [startTrack]. It then
  /// creates or updates the performance report with the measured duration.
  ///
  /// The final report includes:
  /// - Action name (set during [init])
  /// - Full request path (set during [init])
  /// - Total request duration (calculated here)
  ///
  /// This method is called by [RequestAction] after the HTTP request
  /// completes (successfully or with an error).
  ///
  /// This method is typically called internally and not used directly
  /// by application code.
  ///
  /// Example (internal usage):
  /// ```dart
  /// performance.startTrack();
  /// // ... HTTP request and processing ...
  /// performance.endTrack(); // Creates final report with duration
  /// ```
  endTrack() {
    Duration? duration = DateTime.now().difference(_startTime);
    actionsReport[this._fullPath] = PerformanceReport(
        actionName: this._actionName,
        duration: duration,
        fullPath: this._fullPath);
  }

  /// Returns a formatted string containing all performance reports.
  ///
  /// This method creates a multi-line string with performance information
  /// for all tracked requests. Each line contains the details for one request,
  /// formatted by [PerformanceReport.toString].
  ///
  /// The output format for each request is:
  /// ```
  /// {url} end in: {duration} in {actionName}
  /// ```
  ///
  /// Example output:
  /// ```
  /// https://api.example.com/posts end in: 0:00:01.234567 in GetPostsAction
  /// https://api.example.com/users/123 end in: 0:00:00.567890 in GetUserAction
  /// https://api.example.com/posts end in: 0:00:02.345678 in CreatePostAction
  /// ```
  ///
  /// This is useful for debugging and logging overall API performance:
  ///
  /// ```dart
  /// print('API Performance Summary:');
  /// print(ApiRequestPerformance.instance.toString());
  /// ```
  ///
  /// Returns a formatted string with all performance reports.
  @override
  String toString() {
    String _string = '';
    actionsReport.forEach((key, report) {
      _string += report.toString() + '\n';
    });
    return _string;
  }
}
