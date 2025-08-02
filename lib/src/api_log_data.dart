import 'package:dio/dio.dart';

/// Represents the type of API log event.
enum ApiLogType {
  /// Request being sent
  request,

  /// Response received
  response,

  /// Error occurred
  error,
}

/// Structured data class containing comprehensive API request/response log information.
///
/// This class provides detailed information about API requests, responses, and errors
/// in a structured format, allowing for rich logging, analytics, and debugging capabilities.
///
/// ## Usage
///
/// ```dart
/// ApiRequestOptions.instance!.config(
///   onLog: (ApiLogData logData) {
///     switch (logData.type) {
///       case ApiLogType.request:
///         print('🚀 REQUEST: ${logData.method} ${logData.url}');
///         break;
///       case ApiLogType.response:
///         print('✅ RESPONSE: ${logData.statusCode} ${logData.url}');
///         break;
///       case ApiLogType.error:
///         print('❌ ERROR: ${logData.error} ${logData.url}');
///         break;
///     }
///   },
/// );
/// ```
class ApiLogData {
  /// The type of log event (request, response, or error)
  final ApiLogType type;

  /// The HTTP method (GET, POST, PUT, DELETE, etc.)
  final String? method;

  /// The complete request URL
  final String? url;

  /// HTTP status code (only available for responses and some errors)
  final int? statusCode;

  /// Request headers
  final Map<String, dynamic>? requestHeaders;

  /// Response headers
  final Map<String, dynamic>? responseHeaders;

  /// Request body/data
  final dynamic requestData;

  /// Response body/data
  final dynamic responseData;

  /// Error information (only available for error logs)
  final DioException? error;

  /// Error message (only available for error logs)
  final String? errorMessage;

  /// Request/response duration in milliseconds
  final int? durationMs;

  /// Additional metadata or custom information
  final Map<String, dynamic>? metadata;

  /// Timestamp when the log was created
  final DateTime timestamp;

  /// The formatted log message (for backward compatibility)
  final String formattedMessage;

  /// Creates a new [ApiLogData] instance.
  ///
  /// All parameters are optional except [type] and [formattedMessage] to provide
  /// maximum flexibility for different logging scenarios.
  ApiLogData({
    required this.type,
    required this.formattedMessage,
    this.method,
    this.url,
    this.statusCode,
    this.requestHeaders,
    this.responseHeaders,
    this.requestData,
    this.responseData,
    this.error,
    this.errorMessage,
    this.durationMs,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates an [ApiLogData] for request logging.
  factory ApiLogData.request({
    required String formattedMessage,
    String? method,
    String? url,
    Map<String, dynamic>? headers,
    dynamic data,
    Map<String, dynamic>? metadata,
  }) {
    return ApiLogData(
      type: ApiLogType.request,
      formattedMessage: formattedMessage,
      method: method,
      url: url,
      requestHeaders: headers,
      requestData: data,
      metadata: metadata,
    );
  }

  /// Creates an [ApiLogData] for response logging.
  factory ApiLogData.response({
    required String formattedMessage,
    String? method,
    String? url,
    int? statusCode,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? responseHeaders,
    dynamic requestData,
    dynamic responseData,
    int? durationMs,
    Map<String, dynamic>? metadata,
  }) {
    return ApiLogData(
      type: ApiLogType.response,
      formattedMessage: formattedMessage,
      method: method,
      url: url,
      statusCode: statusCode,
      requestHeaders: requestHeaders,
      responseHeaders: responseHeaders,
      requestData: requestData,
      responseData: responseData,
      durationMs: durationMs,
      metadata: metadata,
    );
  }

  /// Creates an [ApiLogData] for error logging.
  factory ApiLogData.error({
    required String formattedMessage,
    String? method,
    String? url,
    DioException? error,
    String? errorMessage,
    int? statusCode,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? responseHeaders,
    dynamic requestData,
    dynamic responseData,
    Map<String, dynamic>? metadata,
  }) {
    return ApiLogData(
      type: ApiLogType.error,
      formattedMessage: formattedMessage,
      method: method,
      url: url,
      statusCode: statusCode,
      requestHeaders: requestHeaders,
      responseHeaders: responseHeaders,
      requestData: requestData,
      responseData: responseData,
      error: error,
      errorMessage: errorMessage ?? error?.message,
      metadata: metadata,
    );
  }

  /// Converts the log data to a JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'method': method,
      'url': url,
      'statusCode': statusCode,
      'requestHeaders': requestHeaders,
      'responseHeaders': responseHeaders,
      'requestData': requestData,
      'responseData': responseData,
      'errorMessage': errorMessage,
      'durationMs': durationMs,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'formattedMessage': formattedMessage,
    };
  }

  /// Creates a copy of this [ApiLogData] with updated fields.
  ApiLogData copyWith({
    ApiLogType? type,
    String? formattedMessage,
    String? method,
    String? url,
    int? statusCode,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? responseHeaders,
    dynamic requestData,
    dynamic responseData,
    DioException? error,
    String? errorMessage,
    int? durationMs,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return ApiLogData(
      type: type ?? this.type,
      formattedMessage: formattedMessage ?? this.formattedMessage,
      method: method ?? this.method,
      url: url ?? this.url,
      statusCode: statusCode ?? this.statusCode,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      requestData: requestData ?? this.requestData,
      responseData: responseData ?? this.responseData,
      error: error ?? this.error,
      errorMessage: errorMessage ?? this.errorMessage,
      durationMs: durationMs ?? this.durationMs,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() => formattedMessage;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiLogData &&
        other.type == type &&
        other.method == method &&
        other.url == url &&
        other.statusCode == statusCode &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(type, method, url, statusCode, timestamp);
  }
}
