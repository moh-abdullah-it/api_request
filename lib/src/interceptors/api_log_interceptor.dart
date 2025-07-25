import 'package:api_request/api_request.dart';

/// A logging interceptor for API requests and responses.
///
/// This interceptor provides comprehensive logging of HTTP requests and responses
/// for debugging purposes. It's automatically enabled in debug mode when
/// [ApiRequestOptions.enableLog] is true.
///
/// ## Features
///
/// - **Request Logging**: Method, URL, headers, and body data
/// - **Response Logging**: Status code, headers, and response body
/// - **Error Logging**: Detailed error information and stack traces
/// - **FormData Support**: Special handling for multipart form data
/// - **Customizable Output**: Configure what gets logged and where
///
/// ## Default Behavior
///
/// By default, all logging features are enabled:
/// - Request details (method, URL, timeout)
/// - Request headers and body
/// - Response headers and body
/// - Error messages and details
///
/// ## Customization
///
/// You can customize what gets logged:
///
/// ```dart
/// final logInterceptor = ApiLogInterceptor(
///   request: true,          // Log request details
///   requestHeader: false,   // Don't log request headers
///   requestBody: true,      // Log request body
///   responseHeader: false,  // Don't log response headers
///   responseBody: true,     // Log response body
///   error: true,           // Log errors
/// );
///
/// ApiRequestOptions.instance!.config(
///   interceptors: [logInterceptor],
/// );
/// ```
///
/// ## Custom Log Output
///
/// By default, logs are printed to console. You can customize the output:
///
/// ```dart
/// // Log to file
/// var file = File('./api_logs.txt');
/// var sink = file.openWrite();
/// 
/// final logInterceptor = ApiLogInterceptor(
///   logPrint: sink.writeln,
/// );
///
/// // Remember to close the file when done
/// await sink.close();
/// ```
///
/// ```dart
/// // Use Flutter's debugPrint
/// import 'package:flutter/foundation.dart';
/// 
/// final logInterceptor = ApiLogInterceptor(
///   logPrint: debugPrint,
/// );
/// ```
///
/// ## Automatic Registration
///
/// This interceptor is automatically added by [RequestClient] when:
/// - The app is running in debug mode (not release mode)
/// - [ApiRequestOptions.enableLog] is true (default)
///
/// ## Example Output
///
/// ```
/// *** Api Request ***
/// uri: https://api.example.com/posts/123
/// method: GET
/// headers:
///  Authorization: Bearer abc123
///  Content-Type: application/json
/// 
/// *** Api Response ***
/// uri: https://api.example.com/posts/123
/// statusCode: 200
/// headers:
///  content-type: application/json
/// Response Text:
/// {"id":123,"title":"Sample Post"}
/// ```
///
/// See also:
/// - [ApiRequestOptions.enableLog] for enabling/disabling logs
/// - [RequestClient] for automatic interceptor management
/// - [ApiInterceptor] for the base interceptor class
class ApiLogInterceptor extends ApiInterceptor {
  /// Internal tag for interceptor identification
  final String _tag = 'log';

  /// Creates a new [ApiLogInterceptor] with customizable logging options.
  ///
  /// All logging options are enabled by default. Set any to `false` to
  /// disable that type of logging.
  ///
  /// Parameters:
  /// - [request]: Whether to log request details (method, URL, timeout)
  /// - [requestHeader]: Whether to log request headers
  /// - [requestBody]: Whether to log request body/data
  /// - [responseHeader]: Whether to log response headers
  /// - [responseBody]: Whether to log response body/data
  /// - [error]: Whether to log error details
  /// - [logPrint]: Custom function for outputting log messages
  ApiLogInterceptor({
    this.request = true,
    this.requestHeader = true,
    this.requestBody = true,
    this.responseHeader = true,
    this.responseBody = true,
    this.error = true,
    this.logPrint = print,
  });

  /// Whether to log basic request information.
  ///
  /// When enabled, logs the HTTP method, response type, and timeout settings.
  ///
  /// Example output:
  /// ```
  /// method: GET
  /// responseType: ResponseType.json
  /// connectTimeout: 0:00:30.000000
  /// ```
  bool request;

  /// Whether to log request headers.
  ///
  /// When enabled, logs all headers sent with the request, including
  /// authentication tokens and custom headers.
  ///
  /// Example output:
  /// ```
  /// headers:
  ///  Authorization: Bearer abc123
  ///  Content-Type: application/json
  ///  X-Custom-Header: custom-value
  /// ```
  bool requestHeader;

  /// Whether to log request body data.
  ///
  /// When enabled, logs the request payload. For form data requests,
  /// it shows both fields and files separately.
  ///
  /// Example output:
  /// ```
  /// data:
  /// {"title":"New Post","content":"Post content"}
  /// ```
  bool requestBody;

  /// Whether to log response body data.
  ///
  /// When enabled, logs the complete response body received from the server.
  ///
  /// Example output:
  /// ```
  /// Response Text:
  /// {"id":123,"title":"Sample Post","content":"Post content"}
  /// ```
  bool responseBody;

  /// Whether to log response headers.
  ///
  /// When enabled, logs all headers returned by the server, including
  /// status code and redirect information.
  ///
  /// Example output:
  /// ```
  /// statusCode: 200
  /// headers:
  ///  content-type: application/json
  ///  cache-control: no-cache
  /// ```
  bool responseHeader;

  /// Whether to log error messages and details.
  ///
  /// When enabled, logs comprehensive error information including
  /// the request that failed and any response data.
  ///
  /// Example output:
  /// ```
  /// *** ApiRequestError ***:
  /// uri: https://api.example.com/posts
  /// DioException [DioExceptionType.badResponse]: Http status error [400]
  /// statusCode: 400
  /// Response Text:
  /// {"error":"Invalid request data"}
  /// ```
  bool error;

  /// Function used to output log messages.
  ///
  /// Defaults to [print] which outputs to console. You can customize
  /// this to redirect logs to files, use [debugPrint] in Flutter,
  /// or integrate with logging frameworks.
  ///
  /// Examples:
  /// ```dart
  /// // Use Flutter's debugPrint
  /// logPrint: debugPrint
  ///
  /// // Write to file
  /// logPrint: file.openWrite().writeln
  ///
  /// // Use logger package
  /// logPrint: (msg) => logger.debug(msg)
  /// ```
  void Function(Object object) logPrint;

  /// Intercepts and logs outgoing requests.
  ///
  /// This method is called before each HTTP request is sent. It logs
  /// request details based on the configured logging options.
  ///
  /// The logged information includes:
  /// - Request URI (always logged)
  /// - HTTP method, response type, and timeout (if [request] is true)
  /// - Request headers (if [requestHeader] is true)
  /// - Request body with special handling for FormData (if [requestBody] is true)
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    logPrint('*** Api Request ***');
    _printKV('uri', options.uri);

    if (request) {
      _printKV('method', options.method);
      _printKV('responseType', options.responseType.toString());
      _printKV('connectTimeout', options.connectTimeout);
    }
    if (requestHeader) {
      logPrint('headers:');
      options.headers.forEach((key, v) => _printKV(' $key', v));
    }
    if (requestBody) {
      if (options.data is FormData) {
        _printKV(
            'Data Fields: ',
            options.data.fields
                .map((MapEntry entry) => '${entry.key}: ${entry.value}')
                .toString());
        _printKV('Data Files: ', options.data.files);
      } else {
        logPrint('data:');
        _printAll(options.data);
      }
    }
    logPrint('');

    handler.next(options);
  }

  /// Intercepts and logs incoming responses.
  ///
  /// This method is called after receiving an HTTP response. It logs
  /// response details based on the configured logging options.
  ///
  /// The logged information includes:
  /// - Response URI (always logged)
  /// - Status code, headers, and redirect info (if [responseHeader] is true)
  /// - Response body (if [responseBody] is true)
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    logPrint('*** Api Response ***');
    _printResponse(response);
    handler.next(response);
  }

  /// Intercepts and logs request errors.
  ///
  /// This method is called when an HTTP request fails due to network
  /// issues, server errors, or other problems. It logs comprehensive
  /// error information if [error] logging is enabled.
  ///
  /// The logged information includes:
  /// - Error URI and exception details
  /// - Response information (if a response was received)
  /// - Full error stack trace and context
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (error) {
      logPrint('*** ApiRequestError ***:');
      logPrint('uri: ${err.requestOptions.uri}');
      logPrint('$err');
      if (err.response != null) {
        _printResponse(err.response!);
      }
      logPrint('');
    }

    handler.next(err);
  }

  /// Prints response information based on logging configuration.
  ///
  /// This helper method formats and logs response data including
  /// status codes, headers, redirects, and response body.
  void _printResponse(Response response) {
    _printKV('uri', response.requestOptions.uri);
    if (responseHeader) {
      _printKV('statusCode', response.statusCode);
      if (response.isRedirect == true) {
        _printKV('redirect', response.realUri);
      }

      logPrint('headers:');
      response.headers.forEach((key, v) => _printKV(' $key', v.join('\r\n\t')));
    }
    if (responseBody) {
      logPrint('Response Text:');
      _printAll(response.toString());
    }
    logPrint('');
  }

  /// Prints a key-value pair in a consistent format.
  ///
  /// Helper method for formatting log output with consistent key-value styling.
  void _printKV(String key, Object? v) {
    logPrint('$key: $v');
  }

  /// Prints multi-line text by splitting on newlines.
  ///
  /// Helper method for properly formatting multi-line content like
  /// JSON responses or error messages.
  void _printAll(msg) {
    msg.toString().split('\n').forEach(logPrint);
  }

  /// Compares two [ApiLogInterceptor] instances for equality.
  ///
  /// Two interceptors are considered equal if they have the same type
  /// and internal tag. This is used by [RequestClient] to prevent
  /// duplicate interceptors.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiLogInterceptor &&
          runtimeType == other.runtimeType &&
          _tag == other._tag;

  /// Returns the hash code for this interceptor.
  ///
  /// Based on the internal tag to ensure consistent hashing for
  /// equality comparison and collection membership.
  @override
  int get hashCode => _tag.hashCode;
}
