import 'package:api_request/api_request.dart';
import 'package:flutter/cupertino.dart';

/// Types of errors that can occur during API request execution.
///
/// This enum categorizes different error scenarios to help with
/// error handling and debugging:
///
/// - [Api]: Network or HTTP-related errors from Dio
/// - [Response]: Response parsing or processing errors
/// - [Unknown]: Unexpected errors that don't fit other categories
enum ActionErrorType {
  /// Network or HTTP-related errors.
  ///
  /// This type indicates errors that occur during HTTP communication,
  /// such as network timeouts, connection failures, or HTTP status errors.
  /// These errors typically originate from Dio exceptions.
  Api,

  /// Response parsing or processing errors.
  ///
  /// This type indicates errors that occur while processing the server
  /// response, such as JSON parsing failures or response builder errors.
  /// These errors typically occur after receiving a response.
  Response,

  /// Unknown or unexpected errors.
  ///
  /// This type indicates errors that don't fit into the other categories.
  /// These are typically programming errors or unexpected exceptions.
  Unknown
}

/// A comprehensive error class for API request failures.
///
/// This class wraps various types of errors that can occur during API requests,
/// providing detailed information for debugging and error handling. It implements
/// the [Exception] interface and can be used with functional programming patterns.
///
/// ## Error Types
///
/// The error is categorized by [type]:
/// - [ActionErrorType.Api]: Network/HTTP errors from Dio
/// - [ActionErrorType.Response]: Response parsing errors
/// - [ActionErrorType.Unknown]: Unexpected errors
///
/// ## Usage with Either Pattern
///
/// ```dart
/// final result = await action.execute();
/// result?.fold(
///   (error) {
///     switch (error.type) {
///       case ActionErrorType.Api:
///         handleNetworkError(error);
///         break;
///       case ActionErrorType.Response:
///         handleParsingError(error);
///         break;
///       case ActionErrorType.Unknown:
///         handleUnknownError(error);
///         break;
///     }
///   },
///   (data) => handleSuccess(data),
/// );
/// ```
///
/// ## Error Information
///
/// The class provides comprehensive error details:
/// - [message]: Human-readable error description
/// - [statusCode]: HTTP status code (if applicable)
/// - [requestOptions]: Details about the failed request
/// - [response]: Server response (if received)
/// - [errors]: Validation errors from server (if any)
/// - [apiErrorResponse]: Parsed error response object
///
/// ## Custom Error Objects
///
/// If [ApiRequestOptions.errorBuilder] is configured, server error responses
/// are automatically parsed into custom error objects:
///
/// ```dart
/// ApiRequestOptions.instance!.config(
///   errorBuilder: (data) => ApiError.fromJson(data),
/// );
///
/// // Later, access the parsed error
/// if (error.apiErrorResponse != null) {
///   final apiError = error.apiErrorResponse as ApiError;
///   showError(apiError.userMessage);
/// }
/// ```
///
/// See also:
/// - [ActionErrorType] for error categorization
/// - [ApiRequestOptions.errorBuilder] for custom error parsing
/// - [RequestAction.execute] for the Either return pattern
class ActionRequestError<E> implements Exception {
  /// Information about the HTTP request that failed.
  ///
  /// Contains details such as URL, method, headers, and other request
  /// configuration. This is null for non-HTTP errors.
  late RequestOptions? requestOptions;

  /// The category of error that occurred.
  ///
  /// Helps distinguish between network errors, parsing errors, and
  /// unexpected errors for appropriate handling.
  ActionErrorType? type;

  /// The HTTP status code of the failed request.
  ///
  /// This is null for errors that don't involve HTTP communication
  /// (e.g., parsing errors, network connectivity issues).
  late int? statusCode;

  /// The HTTP response received from the server.
  ///
  /// This may be null if the request couldn't reach the server due to
  /// network issues, DNS errors, or connection timeouts.
  Response? response;

  /// The parsed error response object using [ApiRequestOptions.errorBuilder].
  ///
  /// If a custom error builder is configured in [ApiRequestOptions], server
  /// error responses are automatically parsed into this typed object.
  ///
  /// Example:
  /// ```dart
  /// if (error.apiErrorResponse != null) {
  ///   final customError = error.apiErrorResponse as MyCustomError;
  ///   print('Error code: ${customError.code}');
  /// }
  /// ```
  E? apiErrorResponse;

  /// The original error or exception object that caused this error.
  ///
  /// For [ActionErrorType.Api] errors, this contains the original [DioException].
  /// For [ActionErrorType.Response] errors, this contains the parsing error.
  dynamic error;

  /// Validation errors from the server response.
  ///
  /// If the server returns validation errors in a 'errors' field,
  /// they are automatically extracted and stored here.
  ///
  /// Example server response:
  /// ```json
  /// {
  ///   "message": "Validation failed",
  ///   "errors": {
  ///     "email": ["Email is required"],
  ///     "password": ["Password must be at least 8 characters"]
  ///   }
  /// }
  /// ```
  Map<String, dynamic>? errors;

  /// A human-readable error message.
  ///
  /// This message is automatically determined from:
  /// 1. Server response 'message' field (if available)
  /// 2. Dio error message (for network errors)
  /// 3. Exception message (for parsing errors)
  String? message;

  /// The stack trace associated with the error.
  ///
  /// This is primarily useful for [ActionErrorType.Response] errors
  /// to help debug parsing issues.
  StackTrace? stackTrace;

  /// Returns a string representation of the error.
  ///
  /// Includes the error message and stack trace (if available) for debugging.
  ///
  /// Example output:
  /// ```
  /// ApiRequest Error: Network request failed
  /// #0  RequestAction.execute (package:api_request/src/actions/request_action.dart:123)
  /// ...
  /// ```
  @override
  String toString() {
    var msg = 'ApiRequest Error: $message';
    if (stackTrace != null) {
      msg += '\n$stackTrace';
    }
    return msg;
  }

  /// Creates an [ActionRequestError] from various error types.
  ///
  /// This constructor automatically categorizes and processes different types
  /// of errors that can occur during API requests:
  ///
  /// - [DioException]: Network/HTTP errors from the Dio client
  /// - [Error]: Dart errors (typically parsing failures)
  /// - Other types: Treated as unknown errors
  ///
  /// Parameters:
  /// - [apiError]: The original error object to wrap
  /// - [res]: Optional response object for additional context
  ///
  /// ## Automatic Processing
  ///
  /// The constructor automatically:
  /// - Extracts request details and status codes
  /// - Parses server error messages from response data
  /// - Applies custom error builders if configured
  /// - Extracts validation errors from server responses
  /// - Logs detailed error information for debugging
  ///
  /// Example usage (typically done internally by RequestAction):
  /// ```dart
  /// try {
  ///   // Some API request
  /// } catch (e) {
  ///   final error = ActionRequestError(e);
  ///   // Handle the wrapped error
  /// }
  /// ```
  ActionRequestError(dynamic apiError, {Response? res}) {
    if (apiError is DioException) {
      this.requestOptions = apiError.requestOptions;
      this.response = apiError.response;
      this.error = apiError.error;
      this.statusCode = apiError.response?.statusCode;
      message = apiError.message;
      this.type = ActionErrorType.Api;
      if (ApiRequestOptions.instance?.errorBuilder != null) {
        final errorData = res?.data ?? response?.data;
        if (errorData is Map<String, dynamic>) {
          this.apiErrorResponse =
              ApiRequestOptions.instance?.errorBuilder!(errorData);
        }
      }
      debugPrint(
          "🛑️ 🛑️ 🛑️ 🛑️ 🛑️ 🛑 🛑️ 🛑 Start Action Request Error 🛑 🛑 🛑 🛑 🛑 🛑 🛑 🛑️ \n"
          "message: ${this.message}\n"
          "statusCode: ${this.statusCode}\n"
          "url: ${this.requestOptions?.uri.toString()}\n"
          "method: ${this.requestOptions?.method}\n"
          "type: ${this.type.toString().split('.').last.toString()}\n"
          "response: ${this.response}\n"
          "----------------- End Action Request Error -------------------");
      if (this.response?.data is Map) {
        if (this.response?.data['errors'] is Map) {
          this.errors = this.response?.data['errors'];
        }
        if (this.response?.data['message'] != null) {
          message = this.response?.data['message'];
        }
      }
    } else if (apiError is Error) {
      this.type = ActionErrorType.Response;
      this.message = apiError.toString();
      this.stackTrace = apiError.stackTrace;
      error = apiError;
      debugPrint(
          "⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ Start Action Request Error ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ \n"
          "message: ${this.message}\n"
          "statusCode: ${res?.statusCode}\n"
          "url: ${res?.requestOptions.uri.toString()}\n"
          "method: ${res?.requestOptions.method}\n"
          "type: ${this.type.toString().split('.').last.toString()}: ${apiError.runtimeType}\n"
          "stackTrace: ${this.stackTrace}\n"
          "response: ${res?.data}");
    } else {
      this.type = ActionErrorType.Unknown;
      debugPrint('Error: $apiError');
      debugPrintStack(stackTrace: this.stackTrace, label: "Unknown Error");
      throw Exception('Unknown Error');
    }
  }
}
