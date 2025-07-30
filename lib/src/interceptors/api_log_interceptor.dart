import 'package:api_request/api_request.dart';
import '../api_log_data.dart';

/// A logging interceptor for API requests and responses.
///
/// This interceptor provides comprehensive logging of HTTP requests and responses
/// for debugging purposes. It's automatically enabled in debug mode when
/// [ApiRequestOptions.logLevel] is not [ApiLogLevel.none].
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
/// By default, logs are printed to console. You can customize the output in two ways:
///
/// ### Global Configuration (Recommended)
///
/// Configure logging globally via [ApiRequestOptions]:
///
/// ```dart
/// ApiRequestOptions.instance!.config(
///   onLog: (logMessage) {
///     // Send to custom logger
///     Logger.instance.debug(logMessage);
///     
///     // Write to file
///     logFile.writeAsStringSync('$logMessage\n', mode: FileMode.append);
///   },
/// );
/// ```
///
/// ### Per-Interceptor Configuration
///
/// Configure logging for specific interceptor instances:
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
/// - [ApiRequestOptions.logLevel] is not [ApiLogLevel.none] (default: [ApiLogLevel.info])
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
/// - [ApiRequestOptions.logLevel] for controlling log levels
/// - [ApiRequestOptions.onLog] for global log message handling
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
    void Function(Object object)? logPrint,
  }) : logPrint = logPrint ?? _defaultLogPrint;

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
  /// Defaults to [_defaultLogPrint] which checks for global [onLog] callback
  /// first, then falls back to [print]. You can customize this to redirect 
  /// logs to files, use [debugPrint] in Flutter, or integrate with logging frameworks.
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

  /// Default log print function that checks for global onLog callback.
  ///
  /// This function first attempts to use the global [ApiRequestOptions.onLog]
  /// callback if configured, then always falls back to the standard [print] function.
  static void _defaultLogPrint(Object object) {
    final logMessage = object.toString();
    
    // Use global onLog callback if configured
    final globalOnLog = ApiRequestOptions.instance?.onLog;
    if (globalOnLog != null) {
      // For backward compatibility, create a simple log data when only string is provided
      final logData = ApiLogData(
        type: ApiLogType.request, // Default type, will be overridden by structured calls
        formattedMessage: logMessage,
      );
      globalOnLog(logData);
    }
    
    // Always print to console as well
    print(object);
  }

  /// Sends structured log data to global callback and prints formatted message based on log level.
  void _sendLogData(ApiLogData logData) {
    final logLevel = ApiRequestOptions.instance?.logLevel ?? ApiLogLevel.info;
    final globalOnLog = ApiRequestOptions.instance?.onLog;
    
    // Always send to custom callback if configured
    if (globalOnLog != null) {
      globalOnLog(logData);
    }
    
    // Handle console output based on log level
    switch (logLevel) {
      case ApiLogLevel.none:
        // No output (shouldn't reach here since interceptor isn't added)
        break;
      case ApiLogLevel.error:
        // Only print errors
        if (logData.type == ApiLogType.error) {
          logPrint(logData.formattedMessage);
        }
        break;
      case ApiLogLevel.info:
        // Print all logs to console
        logPrint(logData.formattedMessage);
        break;
      case ApiLogLevel.debug:
        // Only send to callback, no console output
        break;
    }
  }

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
    
    final logLevel = ApiRequestOptions.instance?.logLevel ?? ApiLogLevel.info;
    
    // Only log requests for info level (error level skips requests)
    if (logLevel == ApiLogLevel.info || logLevel == ApiLogLevel.debug) {
      // Build formatted message for display
      final formattedMessage = _buildRequestMessage(options);
      
      // Create structured log data
      final logData = ApiLogData.request(
        formattedMessage: formattedMessage,
        method: options.method,
        url: options.uri.toString(),
        headers: Map<String, dynamic>.from(options.headers),
        data: options.data,
        metadata: {
          'connectTimeout': options.connectTimeout?.inMilliseconds,
          'sendTimeout': options.sendTimeout?.inMilliseconds,
          'receiveTimeout': options.receiveTimeout?.inMilliseconds,
          'responseType': options.responseType.toString(),
        },
      );
      
      // Send structured data or print formatted message
      _sendLogData(logData);
    }
    
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
    final logLevel = ApiRequestOptions.instance?.logLevel ?? ApiLogLevel.info;
    
    // Only log responses for info level (error level skips responses)
    if (logLevel == ApiLogLevel.info || logLevel == ApiLogLevel.debug) {
      // Build formatted message for display
      final formattedMessage = _buildResponseMessage(response);
      
      // Create structured log data
      final logData = ApiLogData.response(
        formattedMessage: formattedMessage,
        method: response.requestOptions.method,
        url: response.requestOptions.uri.toString(),
        statusCode: response.statusCode,
        requestHeaders: Map<String, dynamic>.from(response.requestOptions.headers),
        responseHeaders: response.headers.map.map((key, value) => MapEntry(key, value.join(', '))),
        requestData: response.requestOptions.data,
        responseData: response.data,
        metadata: {
          'isRedirect': response.isRedirect,
          'realUri': response.realUri?.toString(),
          'contentType': response.headers.value('content-type'),
          'contentLength': response.headers.value('content-length'),
        },
      );
      
      // Send structured data or print formatted message
      _sendLogData(logData);
    }
    
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
      // Build formatted message for display
      final formattedMessage = _buildErrorMessage(err);
      
      // Create structured log data
      final logData = ApiLogData.error(
        formattedMessage: formattedMessage,
        method: err.requestOptions.method,
        url: err.requestOptions.uri.toString(),
        error: err,
        errorMessage: err.message,
        statusCode: err.response?.statusCode,
        requestHeaders: Map<String, dynamic>.from(err.requestOptions.headers),
        responseHeaders: err.response?.headers.map.map((key, value) => MapEntry(key, value.join(', '))),
        requestData: err.requestOptions.data,
        responseData: err.response?.data,
        metadata: {
          'errorType': err.type.toString(),
          'stackTrace': err.stackTrace?.toString(),
        },
      );
      
      // Send structured data or print formatted message
      _sendLogData(logData);
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

  /// Builds formatted request message for display.
  String _buildRequestMessage(RequestOptions options) {
    final buffer = StringBuffer();
    
    buffer.writeln('═' * 80);
    buffer.writeln('🚀 API REQUEST');
    buffer.writeln('📍 ${options.method} ${options.uri}');
    buffer.writeln('');
    
    if (request) {
      buffer.writeln('▶ REQUEST INFO');
      buffer.writeln('─' * 14);
      buffer.writeln('Method              : ${options.method}');
      buffer.writeln('Response Type       : ${_formatResponseType(options.responseType)}');
      buffer.writeln('Connect Timeout     : ${_formatDuration(options.connectTimeout)}');
      buffer.writeln('Send Timeout        : ${_formatDuration(options.sendTimeout)}');
      buffer.writeln('Receive Timeout     : ${_formatDuration(options.receiveTimeout)}');
    }
    
    if (requestHeader && options.headers.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('▶ REQUEST HEADERS');
      buffer.writeln('─' * 17);
      options.headers.forEach((key, value) {
        buffer.writeln('${key.padRight(20)}: $value');
      });
    }
    
    if (requestBody && options.data != null) {
      buffer.writeln('');
      buffer.writeln('▶ REQUEST BODY');
      buffer.writeln('─' * 14);
      if (options.data is FormData) {
        final formData = options.data as FormData;
        if (formData.fields.isNotEmpty) {
          buffer.writeln('📝 Form Fields:');
          for (final field in formData.fields) {
            buffer.writeln('  ${field.key.padRight(18)}: ${field.value}');
          }
        }
        if (formData.files.isNotEmpty) {
          buffer.writeln('📎 Form Files:');
          for (final file in formData.files) {
            buffer.writeln('  ${file.key.padRight(18)}: ${file.value.filename} (${file.value.length} bytes)');
          }
        }
      } else {
        buffer.writeln(_formatData(options.data));
      }
    }
    
    buffer.writeln('═' * 80);
    return buffer.toString();
  }

  /// Builds formatted response message for display.
  String _buildResponseMessage(Response response) {
    final buffer = StringBuffer();
    
    buffer.writeln('═' * 80);
    final statusEmoji = _getStatusEmoji(response.statusCode);
    buffer.writeln('$statusEmoji API RESPONSE');
    buffer.writeln('📍 ${response.statusCode} ${response.requestOptions.uri}');
    buffer.writeln('');
    
    if (responseHeader) {
      buffer.writeln('▶ RESPONSE INFO');
      buffer.writeln('─' * 15);
      buffer.writeln('Status Code         : ${response.statusCode} ${_getStatusMessage(response.statusCode)}');
      buffer.writeln('Content Type        : ${response.headers.value('content-type') ?? 'Unknown'}');
      buffer.writeln('Content Length      : ${response.headers.value('content-length') ?? 'Unknown'}');
      
      if (response.isRedirect == true) {
        buffer.writeln('Redirect            : ${response.realUri}');
      }

      if (response.headers.map.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('▶ RESPONSE HEADERS');
        buffer.writeln('─' * 18);
        response.headers.forEach((key, values) {
          final value = values.length == 1 ? values.first : values.join(', ');
          buffer.writeln('${key.padRight(20)}: $value');
        });
      }
    }
    
    if (responseBody && response.data != null) {
      buffer.writeln('');
      buffer.writeln('▶ RESPONSE BODY');
      buffer.writeln('─' * 15);
      buffer.writeln(_formatData(response.data));
    }
    
    buffer.writeln('═' * 80);
    return buffer.toString();
  }

  /// Builds formatted error message for display.
  String _buildErrorMessage(DioException err) {
    final buffer = StringBuffer();
    
    buffer.writeln('═' * 80);
    buffer.writeln('❌ API ERROR');
    buffer.writeln('📍 ${err.requestOptions.method} ${err.requestOptions.uri}');
    buffer.writeln('');
    
    buffer.writeln('▶ ERROR DETAILS');
    buffer.writeln('─' * 15);
    buffer.writeln('Type                : ${_formatErrorType(err.type)}');
    buffer.writeln('Message             : ${err.message ?? 'No message'}');
    
    if (err.response != null) {
      buffer.writeln('');
      buffer.writeln('▶ ERROR RESPONSE');
      buffer.writeln('─' * 16);
      buffer.writeln('Status Code         : ${err.response!.statusCode} ${_getStatusMessage(err.response!.statusCode)}');
      
      if (err.response!.data != null) {
        buffer.writeln('Response Data:');
        buffer.writeln(_formatData(err.response!.data));
      }
    }
    
    buffer.writeln('═' * 80);
    return buffer.toString();
  }

  /// Formats data for display with proper indentation.
  String _formatData(dynamic data) {
    if (data == null) return '  null';
    
    try {
      // Try to format as JSON if it's a string that looks like JSON
      if (data is String && (data.startsWith('{') || data.startsWith('['))) {
        return _formatJson(data);
      } else if (data is Map || data is List) {
        return _formatJson(data.toString());
      } else {
        // Add indentation to each line
        return data.toString().split('\n').map((line) => '  $line').join('\n');
      }
    } catch (e) {
      // Fallback to simple indented printing
      return data.toString().split('\n').map((line) => '  $line').join('\n');
    }
  }

  /// Formats JSON data with proper indentation.
  String _formatJson(String jsonString) {
    try {
      // Simple JSON formatting - add indentation for readability
      final lines = <String>[];
      var indent = 0;
      
      for (int i = 0; i < jsonString.length; i++) {
        final char = jsonString[i];
        
        if (char == '{' || char == '[') {
          lines.add('  ' * (indent + 1) + char);
          indent++;
        } else if (char == '}' || char == ']') {
          indent--;
          lines.add('  ' * (indent + 1) + char);
        } else if (char == ',' && i + 1 < jsonString.length) {
          lines.add(char);
        } else if (char != ' ' && char != '\n' && char != '\r') {
          if (lines.isEmpty || lines.last.endsWith('\n')) {
            lines.add('  ' * (indent + 1) + char);
          } else {
            lines[lines.length - 1] += char;
          }
        }
      }
      
      return lines.join('\n');
    } catch (e) {
      // Fallback to simple line-by-line printing with indentation
      return jsonString.split('\n').map((line) => '  $line').join('\n');
    }
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
