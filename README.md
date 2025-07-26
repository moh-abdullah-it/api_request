# API Request

⚡ **Action-based HTTP client for Flutter** - Single-responsibility API request classes built on Dio.

A Flutter package that introduces a clean, testable approach to organizing API logic through dedicated action classes. Instead of monolithic service classes, create small, focused classes that handle specific API requests.

[![Pub Version](https://img.shields.io/pub/v/api_request)](https://pub.dev/packages/api_request)
[![Dart Version](https://img.shields.io/badge/dart-%3E%3D3.5.0-blue)](https://dart.dev)
[![Flutter Version](https://img.shields.io/badge/flutter-%3E%3D3.10.0-blue)](https://flutter.dev)

## ✨ Features

- **Single Responsibility Principle**: Each action class handles one specific API request
- **File Download Support**: Action-based and direct file download with progress tracking
- **Functional Error Handling**: Uses `Either<Error, Success>` pattern with fpdart
- **Dynamic Configuration**: Runtime base URL and token resolution
- **Performance Monitoring**: Built-in request timing and reporting
- **Flexible Authentication**: Multiple token provider strategies
- **Path Variables**: Dynamic URL path substitution
- **Global Error Handling**: Centralized error management
- **Comprehensive Logging**: Request/response debugging

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  api_request: ^1.0.9
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
    enableLog: true,
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
- `FileDownloadAction`: Specialized action class for file downloads
- `SimpleApiRequest`: Direct HTTP client with download support
- `ApiRequestOptions`: Global configuration singleton
- `RequestClient`: HTTP client wrapper around Dio
- `ApiRequestPerformance`: Performance monitoring

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
- File download operations
- Error handling
- Performance monitoring
- Mock vs live API switching
- Clean architecture implementation

To run the example:

```bash
cd example
flutter run
```

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