# Structured Logging with ApiLogData

The API Request package now provides structured logging through the `ApiLogData` class, giving you comprehensive access to all request/response information.

## Basic Usage

```dart
import 'package:api_request/api_request.dart';

// Configure structured logging
ApiRequestOptions.instance!.config(
  baseUrl: 'https://api.example.com',
  onLog: (ApiLogData logData) {
    // Access structured data
    print('Type: ${logData.type.name}');
    print('Method: ${logData.method}');
    print('URL: ${logData.url}');
    print('Status: ${logData.statusCode}');
    
    // Or use the formatted message for display
    print(logData.formattedMessage);
  },
);
```

## Advanced Analytics Integration

```dart
ApiRequestOptions.instance!.config(
  onLog: (ApiLogData logData) {
    // Send structured data to analytics
    Analytics.trackApiEvent({
      'event_type': 'api_${logData.type.name}',
      'method': logData.method,
      'url': logData.url,
      'status_code': logData.statusCode,
      'duration_ms': logData.durationMs,
      'timestamp': logData.timestamp.toIso8601String(),
    });
    
    // Log errors to crash reporting
    if (logData.type == ApiLogType.error) {
      Crashlytics.recordError(
        logData.error,
        logData.error?.stackTrace,
        information: logData.toJson(),
      );
    }
  },
);
```

## Custom Logger Integration

```dart
ApiRequestOptions.instance!.config(
  onLog: (ApiLogData logData) {
    final level = switch (logData.type) {
      ApiLogType.request => LogLevel.debug,
      ApiLogType.response => LogLevel.info,
      ApiLogType.error => LogLevel.error,
    };
    
    Logger.instance.log(
      logData.formattedMessage,
      level: level,
      context: {
        'method': logData.method,
        'url': logData.url,
        'statusCode': logData.statusCode,
        'requestHeaders': logData.requestHeaders,
        'responseHeaders': logData.responseHeaders,
        'duration': logData.durationMs,
      },
    );
  },
);
```

## File Logging with Rotation

```dart
class ApiFileLogger {
  static final _logFile = File('api_logs.txt');
  static const maxFileSize = 1024 * 1024; // 1MB
  
  static void logToFile(ApiLogData logData) {
    // Rotate log file if too large
    if (_logFile.existsSync() && _logFile.lengthSync() > maxFileSize) {
      _logFile.renameSync('api_logs_old.txt');
    }
    
    // Write structured log entry
    final entry = {
      'timestamp': logData.timestamp.toIso8601String(),
      'type': logData.type.name,
      'method': logData.method,
      'url': logData.url,
      'statusCode': logData.statusCode,
      'duration': logData.durationMs,
      'error': logData.errorMessage,
    };
    
    _logFile.writeAsStringSync(
      '${jsonEncode(entry)}\n',
      mode: FileMode.append,
    );
  }
}

// Configure file logging
ApiRequestOptions.instance!.config(
  onLog: ApiFileLogger.logToFile,
);
```

## Performance Monitoring

```dart
class ApiPerformanceMonitor {
  static final Map<String, List<int>> _endpointTimes = {};
  
  static void trackPerformance(ApiLogData logData) {
    if (logData.type == ApiLogType.response && logData.durationMs != null) {
      final endpoint = '${logData.method} ${logData.url}';
      _endpointTimes.putIfAbsent(endpoint, () => []);
      _endpointTimes[endpoint]!.add(logData.durationMs!);
      
      // Calculate and log average response time
      final times = _endpointTimes[endpoint]!;
      final avgTime = times.reduce((a, b) => a + b) / times.length;
      
      if (avgTime > 2000) { // Slow endpoint warning
        print('⚠️ Slow endpoint detected: $endpoint (avg: ${avgTime.toInt()}ms)');
      }
    }
  }
}

ApiRequestOptions.instance!.config(
  onLog: ApiPerformanceMonitor.trackPerformance,
);
```

## Error Aggregation

```dart
class ApiErrorAggregator {
  static final Map<String, int> _errorCounts = {};
  
  static void aggregateErrors(ApiLogData logData) {
    if (logData.type == ApiLogType.error) {
      final errorKey = '${logData.statusCode} ${logData.errorMessage}';
      _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;
      
      // Alert on repeated errors
      if (_errorCounts[errorKey]! > 5) {
        print('🚨 Repeated error detected: $errorKey (${_errorCounts[errorKey]} times)');
      }
    }
  }
}

ApiRequestOptions.instance!.config(
  onLog: ApiErrorAggregator.aggregateErrors,
);
```

## Available Data Fields

### ApiLogData Properties:
- `type` - Log type (request, response, error)
- `method` - HTTP method (GET, POST, etc.)
- `url` - Complete request URL
- `statusCode` - HTTP status code (responses/errors)
- `requestHeaders` - Request headers map
- `responseHeaders` - Response headers map
- `requestData` - Request body/data
- `responseData` - Response body/data
- `error` - DioException (errors only)
- `errorMessage` - Error message
- `durationMs` - Request duration in milliseconds
- `metadata` - Additional metadata
- `timestamp` - Log creation timestamp
- `formattedMessage` - Formatted log message for display

### Utility Methods:
- `toJson()` - Convert to JSON map
- `copyWith()` - Create modified copy
- `toString()` - Returns formatted message

## Factory Constructors

Create log data manually using factory constructors:

```dart
// Request log
final requestLog = ApiLogData.request(
  formattedMessage: 'Custom request message',
  method: 'POST',
  url: 'https://api.example.com/posts',
  headers: {'Authorization': 'Bearer token'},
  data: {'title': 'New Post'},
);

// Response log  
final responseLog = ApiLogData.response(
  formattedMessage: 'Custom response message',
  statusCode: 201,
  responseData: {'id': 123},
  durationMs: 250,
);

// Error log
final errorLog = ApiLogData.error(
  formattedMessage: 'Custom error message',
  errorMessage: 'Network timeout',
  statusCode: 408,
);
```