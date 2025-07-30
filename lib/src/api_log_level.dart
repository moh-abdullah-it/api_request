/// Defines the logging levels for API requests and responses.
///
/// This enum controls what information gets logged by the [ApiLogInterceptor]
/// and how it's handled (console output vs custom callback only).
///
/// ## Logging Levels
///
/// - **[none]**: No logging at all - interceptor is not added
/// - **[error]**: Only log API errors and exceptions
/// - **[info]**: Log basic request/response information + errors (console output)
/// - **[debug]**: Send all log data only to custom [ApiRequestOptions.onLog] callback (no console output)
///
/// ## Usage Examples
///
/// ```dart
/// // No logging
/// ApiRequestOptions.instance!.config(
///   logLevel: ApiLogLevel.none,
/// );
///
/// // Only errors to console
/// ApiRequestOptions.instance!.config(
///   logLevel: ApiLogLevel.error,
/// );
///
/// // Full info to console
/// ApiRequestOptions.instance!.config(
///   logLevel: ApiLogLevel.info,
/// );
///
/// // Send everything to custom logger only
/// ApiRequestOptions.instance!.config(
///   logLevel: ApiLogLevel.debug,
///   onLog: (logData) {
///     // Custom logging logic - no console output
///     customLogger.log(logData.formattedMessage);
///   },
/// );
/// ```
///
/// ## Migration from enableLog
///
/// ```dart
/// // Old way
/// enableLog: true  // → logLevel: ApiLogLevel.info
/// enableLog: false // → logLevel: ApiLogLevel.none
/// ```
enum ApiLogLevel {
  /// No logging at all.
  ///
  /// The [ApiLogInterceptor] will not be added to the HTTP client.
  /// No console output and no custom [onLog] callbacks will be triggered.
  none,

  /// Only log API errors and exceptions.
  ///
  /// Logs error information to both console AND [onLog] callback for errors only.
  /// Request and response information is not logged.
  ///
  /// Use this in production to capture only failures without verbose logging.
  error,

  /// Log basic request and response information plus errors.
  ///
  /// Logs comprehensive request/response data to both console AND [onLog] callback.
  /// This includes:
  /// - Request method, URL, headers, and body
  /// - Response status, headers, and body
  /// - Error details when they occur
  ///
  /// Use this for development and debugging.
  info,

  /// Send all log data only to custom [onLog] callback.
  ///
  /// All logging data is sent to the [ApiRequestOptions.onLog] callback but
  /// nothing is printed to console. This is useful for:
  /// - Custom logging systems
  /// - File-based logging
  /// - Remote logging services
  /// - Analytics and monitoring
  ///
  /// Requires [ApiRequestOptions.onLog] to be configured.
  debug,
}