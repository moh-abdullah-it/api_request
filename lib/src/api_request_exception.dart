/// Types of API exceptions (deprecated).
///
/// This enum was used to categorize API exceptions in the legacy error system.
/// Use [ActionErrorType] instead for new implementations.
///
/// @deprecated Use [ActionErrorType] with [ActionRequestError] instead.
enum ApiExceptionType {
  /// Client-side errors (4xx status codes)
  client,

  /// Server-side errors (5xx status codes)
  server,

  /// Custom application errors
  custom
}

/// Legacy exception class for API request errors.
///
/// This class has been superseded by [ActionRequestError] which provides
/// better error categorization, detailed error information, and integration
/// with functional programming patterns.
///
/// ## Migration Guide
///
/// **Old usage:**
/// ```dart
/// try {
///   // API request
/// } catch (e) {
///   final exception = ApiRequestException(
///     message: 'Request failed',
///     type: ApiExceptionType.server,
///     statusCode: 500,
///   );
/// }
/// ```
///
/// **New usage:**
/// ```dart
/// final result = await action.execute();
/// result?.fold(
///   (error) {
///     // error is ActionRequestError with comprehensive info
///     print('Error: ${error.message}');
///     print('Status: ${error.statusCode}');
///   },
///   (data) => handleSuccess(data),
/// );
/// ```
///
/// @deprecated Use [ActionRequestError] instead for better error handling and more detailed error information.
@Deprecated('Please use ActionRequestError instead')
class ApiRequestException {
  /// The error message describing what went wrong
  String message;

  /// The HTTP status code of the failed request
  int? statusCode;

  /// The HTTP status message
  String? statusMessage;

  /// The type of exception that occurred
  ApiExceptionType type;

  /// Additional error details (e.g., validation errors)
  dynamic errors;

  /// Creates a new [ApiRequestException].
  ///
  /// Parameters:
  /// - [message]: Required error message
  /// - [type]: Required exception type
  /// - [statusCode]: Optional HTTP status code
  /// - [statusMessage]: Optional HTTP status message
  /// - [errors]: Optional additional error details
  ///
  /// @deprecated Use [ActionRequestError] constructor instead.
  ApiRequestException(
      {required this.message,
      required this.type,
      this.statusCode,
      this.statusMessage,
      this.errors});
}
