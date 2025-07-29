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
/// ═══════════════════════════════════════════════════════════════════════════════
/// 🚀 API REQUEST
/// 📍 GET https://api.example.com/posts/123
/// 
/// ▶ REQUEST INFO
/// ──────────────
/// Method              : GET
/// Response Type       : JSON
/// Connect Timeout     : 30s
/// 
/// ▶ REQUEST HEADERS
/// ─────────────────
/// Authorization       : Bearer abc123
/// Content-Type        : application/json
/// ═══════════════════════════════════════════════════════════════════════════════
/// 
/// ═══════════════════════════════════════════════════════════════════════════════
/// ✅ API RESPONSE
/// 📍 200 https://api.example.com/posts/123
/// 
/// ▶ RESPONSE INFO
/// ───────────────
/// Status Code         : 200 OK
/// Content Type        : application/json
/// Content Length      : 42
/// 
/// ▶ RESPONSE BODY
/// ───────────────
///   {
///     "id": 123,
///     "title": "Sample Post"
///   }
/// ═══════════════════════════════════════════════════════════════════════════════
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
    _printSeparator();
    _printHeader('🚀 API REQUEST', '${options.method} ${options.uri}');
    
    if (request) {
      _printSection('REQUEST INFO');
      _printKV('Method', options.method);
      _printKV('Response Type', _formatResponseType(options.responseType));
      _printKV('Connect Timeout', _formatDuration(options.connectTimeout));
      _printKV('Send Timeout', _formatDuration(options.sendTimeout));
      _printKV('Receive Timeout', _formatDuration(options.receiveTimeout));
    }
    
    if (requestHeader && options.headers.isNotEmpty) {
      _printSection('REQUEST HEADERS');
      options.headers.forEach((key, value) => _printKV(key, value));
    }
    
    if (requestBody && options.data != null) {
      _printSection('REQUEST BODY');
      if (options.data is FormData) {
        final formData = options.data as FormData;
        if (formData.fields.isNotEmpty) {
          logPrint('📝 Form Fields:');
          for (final field in formData.fields) {
            _printKV('  ${field.key}', field.value, indent: 2);
          }
        }
        if (formData.files.isNotEmpty) {
          logPrint('📎 Form Files:');
          for (final file in formData.files) {
            _printKV('  ${file.key}', '${file.value.filename} (${file.value.length} bytes)', indent: 2);
          }
        }
      } else {
        _printData(options.data);
      }
    }
    
    _printSeparator();
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
    _printSeparator();
    final statusEmoji = _getStatusEmoji(response.statusCode);
    _printHeader('$statusEmoji API RESPONSE', '${response.statusCode} ${response.requestOptions.uri}');
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
      _printSeparator();
      _printHeader('❌ API ERROR', '${err.requestOptions.method} ${err.requestOptions.uri}');
      
      _printSection('ERROR DETAILS');
      _printKV('Type', _formatErrorType(err.type));
      _printKV('Message', err.message ?? 'No message');
      
      if (err.response != null) {
        _printSection('ERROR RESPONSE');
        _printResponse(err.response!);
      }
      
      _printSeparator();
    }

    handler.next(err);
  }

  /// Prints response information based on logging configuration.
  ///
  /// This helper method formats and logs response data including
  /// status codes, headers, redirects, and response body.
  void _printResponse(Response response) {
    if (responseHeader) {
      _printSection('RESPONSE INFO');
      _printKV('Status Code', '${response.statusCode} ${_getStatusMessage(response.statusCode)}');
      _printKV('Content Type', response.headers.value('content-type') ?? 'Unknown');
      _printKV('Content Length', response.headers.value('content-length') ?? 'Unknown');
      
      if (response.isRedirect == true) {
        _printKV('Redirect', response.realUri.toString());
      }

      if (response.headers.map.isNotEmpty) {
        _printSection('RESPONSE HEADERS');
        response.headers.forEach((key, values) => 
          _printKV(key, values.length == 1 ? values.first : values.join(', ')));
      }
    }
    
    if (responseBody && response.data != null) {
      _printSection('RESPONSE BODY');
      _printData(response.data);
    }
    
    _printSeparator();
  }

  /// Prints a separator line for visual clarity.
  void _printSeparator() {
    logPrint('═' * 80);
  }

  /// Prints a formatted header with icon and description.
  void _printHeader(String title, String subtitle) {
    logPrint('$title');
    logPrint('📍 $subtitle');
    logPrint('');
  }

  /// Prints a section header with visual formatting.
  void _printSection(String title) {
    logPrint('');
    logPrint('▶ $title');
    logPrint('─' * (title.length + 2));
  }

  /// Prints a key-value pair in a consistent format.
  ///
  /// Helper method for formatting log output with consistent key-value styling.
  void _printKV(String key, Object? value, {int indent = 0}) {
    final spaces = '  ' * indent;
    final formattedKey = key.padRight(20);
    logPrint('$spaces$formattedKey: $value');
  }

  /// Prints data with proper formatting for different types.
  void _printData(dynamic data) {
    if (data == null) {
      logPrint('null');
      return;
    }
    
    try {
      // Try to format as JSON if it's a string that looks like JSON
      if (data is String && (data.startsWith('{') || data.startsWith('['))) {
        _printFormattedJson(data);
      } else if (data is Map || data is List) {
        _printFormattedJson(data.toString());
      } else {
        // Print as-is for other types
        data.toString().split('\n').forEach((line) => logPrint('  $line'));
      }
    } catch (e) {
      // Fallback to simple printing
      data.toString().split('\n').forEach((line) => logPrint('  $line'));
    }
  }

  /// Formats and prints JSON data with proper indentation.
  void _printFormattedJson(String jsonString) {
    try {
      // Simple JSON formatting - add indentation for readability
      var indent = 0;
      final formatted = <String>[];
      
      for (int i = 0; i < jsonString.length; i++) {
        final char = jsonString[i];
        
        if (char == '{' || char == '[') {
          formatted.add('  ' * indent + char);
          indent++;
        } else if (char == '}' || char == ']') {
          indent--;
          formatted.add('  ' * indent + char);
        } else if (char == ',') {
          formatted.add(char);
        } else if (char != ' ' && char != '\n' && char != '\r') {
          if (formatted.isEmpty || formatted.last.endsWith('\n')) {
            formatted.add('  ' * indent + char);
          } else {
            formatted[formatted.length - 1] += char;
          }
        }
      }
      
      // Print each line
      final lines = formatted.join('').split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          logPrint('  $line');
        }
      }
    } catch (e) {
      // Fallback to simple line-by-line printing
      jsonString.split('\n').forEach((line) => logPrint('  $line'));
    }
  }

  /// Gets appropriate emoji for HTTP status code.
  String _getStatusEmoji(int? statusCode) {
    if (statusCode == null) return '❓';
    
    if (statusCode >= 200 && statusCode < 300) return '✅';
    if (statusCode >= 300 && statusCode < 400) return '🔄';
    if (statusCode >= 400 && statusCode < 500) return '⚠️';
    if (statusCode >= 500) return '❌';
    
    return '❓';
  }

  /// Gets human-readable status message for HTTP status code.
  String _getStatusMessage(int? statusCode) {
    if (statusCode == null) return 'Unknown';
    
    switch (statusCode) {
      case 200: return 'OK';
      case 201: return 'Created';
      case 204: return 'No Content';
      case 301: return 'Moved Permanently';
      case 302: return 'Found';
      case 304: return 'Not Modified';
      case 400: return 'Bad Request';
      case 401: return 'Unauthorized';
      case 403: return 'Forbidden';
      case 404: return 'Not Found';
      case 405: return 'Method Not Allowed';
      case 409: return 'Conflict';
      case 422: return 'Unprocessable Entity';
      case 429: return 'Too Many Requests';
      case 500: return 'Internal Server Error';
      case 502: return 'Bad Gateway';
      case 503: return 'Service Unavailable';
      case 504: return 'Gateway Timeout';
      default: return '';
    }
  }

  /// Formats response type for display.
  String _formatResponseType(ResponseType type) {
    return type.toString().split('.').last.toUpperCase();
  }

  /// Formats duration for display.
  String _formatDuration(Duration? duration) {
    if (duration == null) return 'Not set';
    
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${minutes}m ${seconds}s';
    }
  }

  /// Formats error type for display.
  String _formatErrorType(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection Timeout';
      case DioExceptionType.sendTimeout:
        return 'Send Timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive Timeout';
      case DioExceptionType.badCertificate:
        return 'Bad Certificate';
      case DioExceptionType.badResponse:
        return 'Bad Response';
      case DioExceptionType.cancel:
        return 'Request Cancelled';
      case DioExceptionType.connectionError:
        return 'Connection Error';
      case DioExceptionType.unknown:
        return 'Unknown Error';
    }
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
