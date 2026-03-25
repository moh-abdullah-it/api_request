import 'dart:convert';

/// Represents the result of a background request execution.
///
/// This class encapsulates the outcome of an API request that was executed
/// in a background isolate via WorkManager. Results are persisted using
/// SharedPreferences and can be retrieved when the app returns to foreground.
///
/// ## Factory Constructors
///
/// - [BackgroundResult.success] — For successful standard requests
/// - [BackgroundResult.failure] — For failed requests
/// - [BackgroundResult.downloadSuccess] — For successful file downloads
///
/// ## Serialization
///
/// Results can be serialized to/from JSON for persistent storage:
/// ```dart
/// final json = result.toJsonString();
/// final restored = BackgroundResult.fromJsonString(json);
/// ```
class BackgroundResult {
  /// Tag identifying the background task that produced this result.
  final String taskTag;

  /// Whether the request completed successfully.
  final bool isSuccess;

  /// HTTP status code from the response, if available.
  final int? statusCode;

  /// Response body as a string, if available.
  final String? responseBody;

  /// Error message if the request failed.
  final String? errorMessage;

  /// Local file path where a downloaded file was saved.
  final String? savedFilePath;

  /// Timestamp when the request completed.
  final DateTime completedAt;

  BackgroundResult({
    required this.taskTag,
    required this.isSuccess,
    this.statusCode,
    this.responseBody,
    this.errorMessage,
    this.savedFilePath,
    required this.completedAt,
  });

  /// Creates a successful result for standard API requests.
  factory BackgroundResult.success({
    required String taskTag,
    int? statusCode,
    String? responseBody,
  }) {
    return BackgroundResult(
      taskTag: taskTag,
      isSuccess: true,
      statusCode: statusCode,
      responseBody: responseBody,
      completedAt: DateTime.now(),
    );
  }

  /// Creates a failure result.
  factory BackgroundResult.failure({
    required String taskTag,
    int? statusCode,
    String? errorMessage,
  }) {
    return BackgroundResult(
      taskTag: taskTag,
      isSuccess: false,
      statusCode: statusCode,
      errorMessage: errorMessage,
      completedAt: DateTime.now(),
    );
  }

  /// Creates a successful result for file download operations.
  factory BackgroundResult.downloadSuccess({
    required String taskTag,
    required String savedFilePath,
    int? statusCode,
  }) {
    return BackgroundResult(
      taskTag: taskTag,
      isSuccess: true,
      statusCode: statusCode,
      savedFilePath: savedFilePath,
      completedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskTag': taskTag,
      'isSuccess': isSuccess,
      if (statusCode != null) 'statusCode': statusCode,
      if (responseBody != null) 'responseBody': responseBody,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (savedFilePath != null) 'savedFilePath': savedFilePath,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory BackgroundResult.fromJson(Map<String, dynamic> json) {
    return BackgroundResult(
      taskTag: json['taskTag'] as String,
      isSuccess: json['isSuccess'] as bool,
      statusCode: json['statusCode'] as int?,
      responseBody: json['responseBody'] as String?,
      errorMessage: json['errorMessage'] as String?,
      savedFilePath: json['savedFilePath'] as String?,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory BackgroundResult.fromJsonString(String jsonString) {
    return BackgroundResult.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  @override
  String toString() {
    return 'BackgroundResult(taskTag: $taskTag, isSuccess: $isSuccess, '
        'statusCode: $statusCode, savedFilePath: $savedFilePath)';
  }
}
