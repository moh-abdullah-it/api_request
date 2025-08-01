# API Request

⚡ **Action-based HTTP client for Flutter** - Single-responsibility API request classes built on Dio.

A Flutter package that introduces a clean, testable approach to organizing API logic through dedicated action classes. Instead of monolithic service classes, create small, focused classes that handle specific API requests.

[![Pub Version](https://img.shields.io/pub/v/api_request)](https://pub.dev/packages/api_request)
[![Dart Version](https://img.shields.io/badge/dart-%3E%3D3.5.0-blue)](https://dart.dev)
[![Flutter Version](https://img.shields.io/badge/flutter-%3E%3D3.10.0-blue)](https://flutter.dev)

## ✨ Features

- **Single Responsibility Principle**: Each action class handles one specific API request
- **Progress Tracking**: Unified upload/download progress monitoring across all request types
- **File Operations**: Complete file upload and download support with progress tracking
- **Functional Error Handling**: Uses `Either<Error, Success>` pattern with fpdart
- **Dynamic Configuration**: Runtime base URL and token resolution
- **Performance Monitoring**: Built-in request timing and data transfer reporting
- **Flexible Authentication**: Multiple token provider strategies
- **Path Variables**: Dynamic URL path substitution
- **Global Error Handling**: Centralized error management
- **🎨 Colored Logging**: Beautiful syntax-highlighted console output with JSON formatting
- **Comprehensive Logging**: Request/response debugging with professional visual design

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  api_request: ^1.5.0
```

Then run:
```bash
flutter pub get
```

## 🚀 Quick Start

### 1. Global Configuration

Configure the package in your `main()` function:

```dart
import 'package:api_request/api_request.dart';

void main() {
  ApiRequestOptions.instance?.config(
    baseUrl: 'https://jsonplaceholder.typicode.com/',
    
    // Authentication
    tokenType: ApiRequestOptions.bearer,
    getAsyncToken: () => getTokenFromSecureStorage(),
    
    // Global error handling
    onError: (error) => print('API Error: ${error.message}'),
    
    // Default headers
    defaultHeaders: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    
    // Development settings
    logLevel: ApiLogLevel.info,
    connectTimeout: const Duration(seconds: 30),
  );
  
  runApp(MyApp());
}
```

### 2. Create Action Classes

#### Simple GET Request (No Request Data)

```dart
class GetPostsAction extends ApiRequestAction<List<Post>> {
  @override
  bool get authRequired => false;

  @override
  String get path => 'posts';

  @override
  RequestMethod get method => RequestMethod.GET;

  @override
  ResponseBuilder<List<Post>> get responseBuilder =>
      (json) => (json as List).map((item) => Post.fromJson(item)).toList();
}
```

#### POST Request with Data

```dart
class CreatePostRequest with ApiRequest {
  final String title;
  final String body;
  final int userId;

  CreatePostRequest({
    required this.title,
    required this.body,
    required this.userId,
  });

  @override
  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'userId': userId,
  };
}

class CreatePostAction extends RequestAction<Post, CreatePostRequest> {
  CreatePostAction(CreatePostRequest request) : super(request);

  @override
  bool get authRequired => true;

  @override
  String get path => 'posts';

  @override
  RequestMethod get method => RequestMethod.POST;

  @override
  ResponseBuilder<Post> get responseBuilder => 
      (json) => Post.fromJson(json);
}
```

### 3. Execute Actions

#### Simple Execution

```dart
// GET request
final postsResult = await GetPostsAction().execute();
postsResult?.fold(
  (error) => print('Error: ${error.message}'),
  (posts) => print('Loaded ${posts.length} posts'),
);

// POST request
final request = CreatePostRequest(
  title: 'My New Post',
  body: 'This is the post content',
  userId: 1,
);
final result = await CreatePostAction(request).execute();
```

#### Queue Execution with Callbacks

```dart
final action = GetPostsAction();

action.subscribe(
  onSuccess: (posts) => print('Success: ${posts.length} posts loaded'),
  onError: (error) => print('Error: ${error.message}'),
  onDone: () => print('Request completed'),
);

action.onQueue(); // Execute without waiting
```

#### File Downloads

Download files using either action-based or direct approaches:

```dart
// Action-based approach
class DownloadFileAction extends FileDownloadAction {
  DownloadFileAction(String savePath) : super(savePath);
  
  @override
  String get path => '/files/{fileId}';
}

// Download with progress tracking
final result = await DownloadFileAction('/downloads/document.pdf')
  .where('fileId', 'abc123')
  .onProgress((received, total) {
    final percentage = (received / total * 100).round();
    print('Downloaded: $percentage%');
  })
  .execute();

result?.fold(
  (error) => print('Download failed: ${error.message}'),
  (response) => print('Download completed: ${response.statusCode}'),
);

// Direct approach using SimpleApiRequest
final client = SimpleApiRequest.init();
final response = await client.download(
  '/files/{fileId}',
  '/downloads/document.pdf',
  data: {'fileId': 'abc123'},
  onReceiveProgress: (received, total) {
    print('Progress: ${(received / total * 100).round()}%');
  },
);

// Stream-based progress monitoring
final action = DownloadFileAction('/downloads/video.mp4');
action.progressStream.listen((progress) {
  print('${progress.formattedProgress}');
});

// Cancellation support
final cancelToken = CancelToken();
final action = DownloadFileAction('/downloads/large-file.zip')
  .withCancelToken(cancelToken);

// Cancel after 10 seconds
Timer(Duration(seconds: 10), () => cancelToken.cancel());
```

## 📊 Progress Tracking

Track upload and download progress across all request types with a unified progress system.

### Basic Progress Tracking with Actions

Add progress tracking to any RequestAction:

```dart
// Basic progress tracking
final result = await CreatePostAction(request)
  .withProgress((progress) {
    print('${progress.type.name}: ${progress.percentage.toStringAsFixed(1)}%');
    updateProgressBar(progress.percentage);
  })
  .execute();

// Separate upload and download tracking
final result = await FileUploadAction({'file': file})
  .withUploadProgress((progress) {
    print('Uploading: ${progress.percentage}% (${progress.sentBytes}/${progress.totalBytes} bytes)');
    updateUploadUI(progress);
  })
  .withDownloadProgress((progress) {
    print('Processing response: ${progress.percentage}%');
    updateDownloadUI(progress);
  })
  .execute();
```

### Progress with SimpleApiRequest

Use fluent API for direct HTTP requests with progress:

```dart
final client = SimpleApiRequest.init()
  .withProgress((progress) {
    if (progress.isUpload) {
      showUploadProgress(progress.percentage);
    } else if (progress.isDownload) {
      showDownloadProgress(progress.percentage);
    }
  });

// Progress is automatically tracked for all requests
final result = await client.post<Post>('/posts', data: largeData);

// Or use specific progress handlers
final client = SimpleApiRequest.withAuth()
  .withUploadProgress((progress) => updateUploadBar(progress.percentage))
  .withDownloadProgress((progress) => updateDownloadBar(progress.percentage));
```

### File Upload with Progress

Upload files with comprehensive progress tracking:

```dart
class UploadAvatarAction extends FileUploadAction<User> {
  UploadAvatarAction(File avatarFile) : super({'avatar': avatarFile});

  @override
  String get path => '/users/avatar';

  @override
  ResponseBuilder<User> get responseBuilder => (data) => User.fromJson(data);
}

// Single file upload with progress
final result = await UploadAvatarAction(avatarFile)
  .withUploadProgress((progress) {
    setState(() {
      uploadProgress = progress.percentage;
    });
    
    if (progress.isCompleted) {
      showSnackBar('Upload completed!');
    }
  })
  .withFormData({
    'description': 'Profile photo',
    'category': 'avatar',
  })
  .execute();

// Multi-file upload
class UploadDocumentsAction extends FileUploadAction<List<Document>> {
  UploadDocumentsAction(List<File> files)
      : super(Map.fromEntries(
          files.asMap().entries.map((entry) => 
            MapEntry('document_${entry.key}', entry.value)
          )
        ));

  @override
  String get path => '/documents/upload';

  @override
  ResponseBuilder<List<Document>> get responseBuilder => 
      (data) => (data as List).map((doc) => Document.fromJson(doc)).toList();
}

final documents = await UploadDocumentsAction([file1, file2, file3])
  .withProgress((progress) {
    print('${progress.type.name}: ${progress.percentage}% complete');
    print('${(progress.sentBytes / 1024).round()} KB transferred');
  })
  .execute();
```

### Enhanced File Downloads

File downloads with unified progress system (backward compatible):

```dart
class DownloadVideoAction extends FileDownloadAction {
  DownloadVideoAction(String savePath) : super(savePath);
  
  @override
  String get path => '/videos/{videoId}/download';
}

// New unified progress system
final result = await DownloadVideoAction('/downloads/video.mp4')
  .where('videoId', 'abc123')
  .withDownloadProgress((progress) {
    print('Download: ${progress.percentage.toStringAsFixed(1)}%');
    print('Speed: ${calculateSpeed(progress)} MB/s');
    
    if (progress.isCompleted) {
      showNotification('Download completed!');
    }
  })
  .execute();

// Legacy progress callback still works
final result = await DownloadVideoAction('/downloads/video.mp4')
  .where('videoId', 'abc123')
  .onProgress((received, total) {
    final percentage = (received / total * 100).round();
    print('Legacy progress: $percentage%');
  })
  .execute();

// Both systems can be used together
final result = await DownloadVideoAction('/downloads/video.mp4')
  .onProgress((received, total) => updateLegacyUI(received, total))
  .withDownloadProgress((progress) => updateModernUI(progress))
  .execute();
```

### Stream-Based Progress

Use Dart Streams for reactive progress updates:

```dart
class ProgressStreamExample extends StatefulWidget {
  @override
  _ProgressStreamExampleState createState() => _ProgressStreamExampleState();
}

class _ProgressStreamExampleState extends State<ProgressStreamExample> {
  final StreamController<ProgressData> _progressController = 
      StreamController<ProgressData>.broadcast();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProgressData>(
      stream: _progressController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final progress = snapshot.data!;
          return LinearProgressIndicator(
            value: progress.percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress.isUpload ? Colors.blue : Colors.green,
            ),
          );
        }
        return LinearProgressIndicator(value: 0);
      },
    );
  }

  Future<void> uploadFile(File file) async {
    final result = await UploadFileAction(file)
      .withProgress((progress) {
        _progressController.add(progress);
      })
      .execute();
  }
}
```

### Performance Monitoring with Progress Data

Enhanced performance reports include transfer data:

```dart
// Execute request with progress tracking
final result = await CreatePostAction(request)
  .withProgress((progress) => updateUI(progress))
  .execute();

// Access enhanced performance report
final report = action.performanceReport;
if (report != null) {
  print('Request completed in: ${report.duration?.inMilliseconds}ms');
  
  if (report.hasProgressData) {
    print('Data uploaded: ${report.uploadBytes} bytes');
    print('Data downloaded: ${report.downloadBytes} bytes');
    print('Total transferred: ${report.bytesTransferred} bytes');
    print('Average transfer rate: ${(report.transferRate / 1024).toStringAsFixed(2)} KB/s');
    print('Upload rate: ${(report.uploadRate / 1024).toStringAsFixed(2)} KB/s');
    print('Download rate: ${(report.downloadRate / 1024).toStringAsFixed(2)} KB/s');
  }
}

// Global performance overview with transfer data
final performance = ApiRequestPerformance.instance;
print('All API Performance with Transfer Data:');
print(performance.toString()); // Now includes transfer rates and bytes
```

## 🔧 Advanced Features

### Dynamic Path Variables

Use path variables in your URLs:

```dart
class GetPostAction extends RequestAction<Post, GetPostRequest> {
  @override
  String get path => 'posts/{id}'; // {id} will be replaced

  // ... other implementation
}

class GetPostRequest with ApiRequest {
  final int id;
  
  GetPostRequest(this.id);
  
  @override
  Map<String, dynamic> toMap() => {'id': id}; // Provides value for {id}
}
```

### Multi-Environment Support

Configure different base URLs for different environments:

```dart
ApiRequestOptions.instance?.config(
  getBaseUrl: () {
    switch (Environment.current) {
      case Environment.dev:
        return 'https://api-dev.example.com';
      case Environment.staging:
        return 'https://api-staging.example.com';
      case Environment.prod:
        return 'https://api.example.com';
    }
  },
);
```

### Custom Error Handling

```dart
// Per-action error handling
class MyAction extends ApiRequestAction<Data> {
  @override
  ErrorHandler get onError => (error) {
    // Handle specific errors for this action
    if (error.statusCode == 404) {
      // Handle not found
    }
  };

  @override
  bool get disableGlobalOnError => true; // Skip global error handler
}
```

### Performance Monitoring

```dart
// Get performance report
final report = ApiRequestPerformance.instance?.actionsReport;
print('Request Performance: $report');

// Or log to console
print(ApiRequestPerformance.instance.toString());
```

### Action Lifecycle Events

```dart
class MyAction extends ApiRequestAction<Data> {
  @override
  Function get onInit => () => print('Action initialized');

  @override
  Function get onStart => () => print('Request started');

  @override
  SuccessHandler<Data> get onSuccess => 
      (data) => print('Request succeeded: $data');

  @override
  ErrorHandler get onError => 
      (error) => print('Request failed: ${error.message}');
}
```

### Logging and Debugging

The package provides flexible logging with multiple levels to suit different environments:

#### Log Levels

```dart
ApiRequestOptions.instance!.config(
  // Choose your logging level
  logLevel: ApiLogLevel.info,  // Default: full console logging
  
  // Optional: Custom log handler
  onLog: (logData) {
    // Handle logs however you want
    customLogger.log(logData.formattedMessage);
  },
);
```

**Available Log Levels:**

- **`ApiLogLevel.none`** - No logging at all
- **`ApiLogLevel.error`** - Only log API errors and exceptions (console + custom `onLog`)
- **`ApiLogLevel.info`** - Log all request/response data (console + custom `onLog`) - default
- **`ApiLogLevel.debug`** - Send all data only to custom `onLog` callback (no console output)

#### Advanced Logging Examples

**File Logging (Production):**
```dart
ApiRequestOptions.instance!.config(
  logLevel: ApiLogLevel.debug,  // No console output
  onLog: (logData) {
    // Write to file with timestamp
    final timestamp = DateTime.now().toIso8601String();
    logFile.writeAsStringSync(
      '[$timestamp] ${logData.formattedMessage}\n',
      mode: FileMode.append,
    );
  },
);
```

**Error Monitoring:**
```dart
ApiRequestOptions.instance!.config(
  logLevel: ApiLogLevel.error,  // Errors to both console AND custom callback
  onLog: (logData) {
    if (logData.type == ApiLogType.error) {
      // Send errors to monitoring service (also printed to console)
      errorTracker.captureException(
        logData.error,
        extra: {
          'url': logData.url,
          'method': logData.method,
          'statusCode': logData.statusCode,
        },
      );
    }
  },
);
```

**Development with Custom Logger:**
```dart
ApiRequestOptions.instance!.config(
  logLevel: ApiLogLevel.info,  // Full console logging + custom callback
  onLog: (logData) {
    // Also send to custom logger (in addition to console)
    logger.info('API ${logData.type.name}: ${logData.method} ${logData.url}');
    
    // Performance tracking
    if (logData.metadata?['duration'] != null) {
      performanceTracker.record(
        logData.url!,
        Duration(milliseconds: logData.metadata!['duration']),
      );
    }
  },
);
```

#### Migration from enableLog

The old `enableLog` parameter is deprecated but still supported:

```dart
// Old way (deprecated)
enableLog: true   // → logLevel: ApiLogLevel.info
enableLog: false  // → logLevel: ApiLogLevel.none

// New way (recommended)
logLevel: ApiLogLevel.info,
```

### 🎨 Colored Console Logging

The package now includes beautiful colored console output that makes debugging API requests much more pleasant and efficient.

#### Visual Features

- **🎯 HTTP Method Colors**: GET (blue), POST (green), DELETE (red), PUT (yellow), PATCH (magenta)
- **📊 Status Code Colors**: 2xx (green), 3xx (yellow), 4xx (red), 5xx (bright red)
- **🌈 JSON Syntax Highlighting**: 
  - Cyan property keys for easy identification
  - Green string values 
  - Yellow numbers
  - Magenta booleans (true/false)
  - Gray null values
  - Bright cyan brackets and braces
- **🎨 Structured Themes**: 
  - Cyan theme for outgoing requests
  - Green theme for successful responses
  - Red theme for errors and failures

#### Automatic Color Management

Colors are intelligently managed for optimal performance:

```dart
// Colors are automatically:
// ✅ Enabled in debug mode for development
// ❌ Disabled in release mode for production performance
// 🔄 Gracefully fallback to plain text when not supported

ApiRequestOptions.instance!.config(
  logLevel: ApiLogLevel.info, // Beautiful colored output
);
```

#### Custom Color Integration

You can still use custom logging while benefiting from colored output:

```dart
ApiRequestOptions.instance!.config(
  logLevel: ApiLogLevel.info, // Colored console + custom callback
  onLog: (logData) {
    // Custom processing while keeping colored console output
    if (logData.type == ApiLogType.error) {
      errorTracker.captureException(logData.error);
    }
    
    // Access structured data
    print('Request to: ${logData.url}');
    print('Status: ${logData.statusCode}');
    print('Duration: ${logData.metadata?['duration']}ms');
  },
);
```

#### Production Logging

For production environments, use debug mode to keep colors out of production logs:

```dart
ApiRequestOptions.instance!.config(
  // Send colored output only to custom callback (no console)
  logLevel: ApiLogLevel.debug,
  onLog: (logData) {
    // Clean, uncolored logs for production
    productionLogger.log(logData.formattedMessage);
  },
);
```

#### Color Utility Access

Access the color utilities directly for custom logging:

```dart
import 'package:api_request/api_request.dart';

// Use color utilities in your own logging
print(LogColors.green('✅ Success!'));
print(LogColors.red('❌ Error occurred'));
print(LogColors.statusCode(200, 'OK')); // Auto-colored based on status
print(LogColors.httpMethod('GET', 'GET')); // Auto-colored based on method

// Format JSON with syntax highlighting
final coloredJson = JsonFormatter.formatWithColors({'key': 'value'});
print(coloredJson);
```

## 🏗️ Architecture

The package follows these core principles:

- **Action Classes**: Each API request is a dedicated class
- **Functional Error Handling**: Using `Either<Error, Success>` pattern
- **Dependency Injection Ready**: Easy to mock for testing
- **Configuration Management**: Centralized options with runtime flexibility
- **Performance Tracking**: Built-in monitoring and reporting

### Core Components

- `ApiRequestAction<T>`: Base class for simple requests
- `RequestAction<T, R>`: Base class for requests with data
- `FileDownloadAction`: Specialized action class for file downloads with progress
- `FileUploadAction<T>`: Specialized action class for file uploads with progress
- `SimpleApiRequest`: Direct HTTP client with progress tracking support
- `ApiRequestOptions`: Global configuration singleton
- `RequestClient`: HTTP client wrapper around Dio
- `ApiRequestPerformance`: Performance monitoring with transfer data
- `ProgressData`: Unified progress information structure
- `ProgressHandler`: Progress callback function types
- **🎨 `LogColors`**: ANSI color utility with 30+ color methods and smart detection
- **📝 `JsonFormatter`**: Advanced JSON syntax highlighting with intelligent formatting

## 🧪 Testing

Actions are easy to test due to their single responsibility:

```dart
void main() {
  group('GetPostsAction', () {
    test('should return list of posts', () async {
      final action = GetPostsAction();
      final result = await action.execute();
      
      expect(result, isNotNull);
      result?.fold(
        (error) => fail('Expected success but got error: ${error.message}'),
        (posts) => expect(posts, isA<List<Post>>()),
      );
    });
  });
}
```

## 📖 Complete Example

Check out the [example directory](example/) for a complete Flutter app demonstrating:

- CRUD operations
- File upload and download operations with progress tracking
- Error handling
- Performance monitoring with transfer data
- Mock vs live API switching
- Clean architecture implementation

To run the example:

```bash
cd example
flutter run
```

## 📋 Migration Guide

Upgrading from an older version? Check out our comprehensive guides:

- **[Progress Tracking Migration Guide](PROGRESS_MIGRATION_GUIDE.md)** - Add progress tracking to existing actions
- **[Progress Examples](PROGRESS_EXAMPLES.md)** - Real-world examples and UI integration patterns

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📚 API Reference

For detailed API documentation, visit [pub.dev](https://pub.dev/packages/api_request).

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/moh-abdullah-it/api_request/issues)
- **Discussions**: [GitHub Discussions](https://github.com/moh-abdullah-it/api_request/discussions)
- **Documentation**: [pub.dev documentation](https://pub.dev/packages/api_request)