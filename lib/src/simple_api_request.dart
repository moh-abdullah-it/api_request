import 'package:fpdart/fpdart.dart';

import '../api_request.dart';
import 'utils/api_request_utils.dart';

/// A simplified, instance-based API request client for direct HTTP operations.
///
/// This class provides the most direct approach to making API requests without
/// the structure of [RequestAction] or [ApiResource]. It's designed for cases
/// where you need maximum flexibility and minimal abstraction.
///
/// ## Key Features
///
/// - **Direct HTTP Methods**: GET, POST, PUT, DELETE support
/// - **Instance-Based**: Create configured instances for reuse
/// - **Authentication Support**: Optional per-instance authentication
/// - **Response Building**: Custom response parsing support
/// - **Dynamic Paths**: Automatic path variable substitution
/// - **Progress Tracking**: Built-in upload/download progress monitoring
/// - **Full Dio Integration**: Access to all Dio features (options, cancellation, progress)
/// - **Functional Error Handling**: Uses Either pattern for error handling
///
/// ## Factory Constructors
///
/// The class provides several factory constructors for different use cases:
///
/// ```dart
/// // Basic instance without authentication
/// final client = SimpleApiRequest.init();
///
/// // Instance with authentication
/// final authClient = SimpleApiRequest.withAuth();
///
/// // Instance with custom response builder
/// final typedClient = SimpleApiRequest.withBuilder(
///   (data) => Post.fromJson(data),
///   withAuth: true,
/// );
/// ```
///
/// ## Basic Usage
///
/// ```dart
/// final client = SimpleApiRequest.init();
///
/// // GET request
/// final result = await client.get<List<Post>>('/posts');
/// result?.fold(
///   (error) => print('Error: ${error.message}'),
///   (posts) => print('Loaded ${posts?.length} posts'),
/// );
///
/// // POST request with data
/// final createResult = await client.post<Post>(
///   '/posts',
///   data: {'title': 'New Post', 'content': 'Post content'},
/// );
/// ```
///
/// ## Authentication
///
/// Use [withAuth] factory for authenticated requests:
///
/// ```dart
/// final authClient = SimpleApiRequest.withAuth();
/// final userProfile = await authClient.get<UserProfile>('/user/profile');
/// ```
///
/// ## Dynamic Paths
///
/// Supports path variables with automatic substitution:
///
/// ```dart
/// // Path variables are extracted from data
/// final result = await client.get<Post>(
///   '/posts/{id}',
///   queryParameters: {'id': 123}, // {id} will be replaced
/// );
/// // Results in: GET /posts/123
/// ```
///
/// ## Custom Response Building
///
/// Configure response parsing with [withBuilder]:
///
/// ```dart
/// final typedClient = SimpleApiRequest.withBuilder<Post>(
///   (data) => Post.fromJson(data),
/// );
///
/// final post = await typedClient.get('/posts/123');
/// // Response is automatically parsed to Post object
/// ```
///
/// ## Progress Tracking
///
/// Track upload and download progress using fluent API methods:
///
/// ```dart
/// final client = SimpleApiRequest.init()
///   .withProgress((progress) {
///     print('${progress.type.name}: ${progress.percentage}%');
///   })
///   .withUploadProgress((progress) {
///     updateUploadProgressBar(progress.percentage);
///   })
///   .withDownloadProgress((progress) {
///     updateDownloadProgressBar(progress.percentage);
///   });
///
/// final result = await client.post<Post>(
///   '/posts',
///   data: largeFileData,
/// );
/// // Progress callbacks will be called automatically
/// ```
///
/// ## File Downloads
///
/// Supports file downloads with progress tracking:
///
/// ```dart
/// final response = await client.download(
///   '/files/{fileId}',
///   '/local/path/file.pdf',
///   data: {'fileId': 'abc123'},
///   onReceiveProgress: (received, total) {
///     print('Progress: ${(received / total * 100).round()}%');
///   },
/// );
/// ```
///
/// ## Error Handling
///
/// All methods return `Either<ActionRequestError, T?>?` for comprehensive error handling:
///
/// ```dart
/// final result = await client.get<Post>('/posts/999');
/// result?.fold(
///   (error) {
///     switch (error.type) {
///       case ActionErrorType.Api:
///         if (error.statusCode == 404) {
///           print('Post not found');
///         }
///         break;
///       case ActionErrorType.Response:
///         print('Failed to parse response');
///         break;
///       default:
///         print('Unknown error: ${error.message}');
///     }
///   },
///   (post) => print('Post loaded: ${post?.title}'),
/// );
/// ```
///
/// ## Comparison with Other Approaches
///
/// **Use SimpleApiRequest when:**
/// - You need direct, low-level HTTP access
/// - Making one-off requests
/// - You want maximum flexibility with minimal structure
/// - You need access to all Dio features
///
/// **Use RequestAction when:**
/// - Building reusable, structured request logic
/// - You need lifecycle hooks and event handling
/// - You want streaming or reactive patterns
///
/// **Use ApiResource when:**
/// - You want a middle ground between SimpleApiRequest and RequestAction
/// - You need some structure but not full action complexity
///
/// See also:
/// - [RequestAction] for the full-featured action-based approach
/// - [ApiResource] for resource-based requests
/// - [RequestClient] for the underlying HTTP client
class SimpleApiRequest {
  /// The HTTP client instance used for making requests
  final RequestClient _requestClient;

  /// Optional response builder for parsing responses
  final ResponseBuilder? _responseBuilder;

  /// Whether this instance requires authentication
  final bool _withAuth;

  /// General progress handler for all request types
  ProgressHandler? _progressHandler;

  /// Upload-specific progress handler
  UploadProgressHandler? _uploadProgressHandler;

  /// Download-specific progress handler
  DownloadProgressHandler? _downloadProgressHandler;

  /// Private constructor for creating configured instances.
  ///
  /// This constructor is used by the factory methods to create instances
  /// with specific configurations for authentication and response building.
  ///
  /// Parameters:
  /// - [requestClient]: The HTTP client to use
  /// - [responseBuilder]: Optional response parser
  /// - [withAuth]: Whether to enable authentication
  SimpleApiRequest._({
    required RequestClient requestClient,
    ResponseBuilder? responseBuilder,
    bool withAuth = false,
  })  : _requestClient = requestClient,
        _responseBuilder = responseBuilder,
        _withAuth = withAuth {
    _requestClient.configAuth(_withAuth);
  }

  /// Creates a basic SimpleApiRequest instance without authentication.
  ///
  /// This factory creates a standard instance that can be used for public
  /// API endpoints that don't require authentication.
  ///
  /// Throws [StateError] if [RequestClient] is not initialized.
  ///
  /// Example:
  /// ```dart
  /// final client = SimpleApiRequest.init();
  /// final posts = await client.get<List<Post>>('/posts');
  /// ```
  factory SimpleApiRequest.init() {
    final client = RequestClient.instance;
    if (client == null) {
      throw StateError('RequestClient instance is not initialized');
    }
    return SimpleApiRequest._(requestClient: client);
  }

  /// Creates a SimpleApiRequest instance with authentication enabled.
  ///
  /// This factory creates an instance that automatically includes
  /// authentication headers in all requests using the token configured
  /// in [ApiRequestOptions].
  ///
  /// Throws [StateError] if [RequestClient] is not initialized.
  ///
  /// Example:
  /// ```dart
  /// final authClient = SimpleApiRequest.withAuth();
  /// final profile = await authClient.get<UserProfile>('/user/profile');
  /// ```
  factory SimpleApiRequest.withAuth() {
    final client = RequestClient.instance;
    if (client == null) {
      throw StateError('RequestClient instance is not initialized');
    }
    return SimpleApiRequest._(requestClient: client, withAuth: true);
  }

  /// Creates a SimpleApiRequest instance with a custom response builder.
  ///
  /// This factory creates an instance that automatically parses all responses
  /// using the provided builder function. Optionally enables authentication.
  ///
  /// Parameters:
  /// - [builder]: Function to parse response data
  /// - [withAuth]: Whether to enable authentication (default: false)
  ///
  /// Throws [StateError] if [RequestClient] is not initialized.
  ///
  /// Example:
  /// ```dart
  /// final typedClient = SimpleApiRequest.withBuilder(
  ///   (data) => Post.fromJson(data),
  ///   withAuth: true,
  /// );
  /// final post = await typedClient.get('/posts/123');
  /// // Response is automatically parsed to Post object
  /// ```
  factory SimpleApiRequest.withBuilder(
    ResponseBuilder builder, {
    bool withAuth = false,
  }) {
    final client = RequestClient.instance;
    if (client == null) {
      throw StateError('RequestClient instance is not initialized');
    }
    return SimpleApiRequest._(
      requestClient: client,
      responseBuilder: builder,
      withAuth: withAuth,
    );
  }

  /// Sets a general progress handler for all request operations.
  ///
  /// This handler will receive progress updates for both upload and download
  /// operations. If specific upload/download handlers are also set, they will
  /// be called in addition to this general handler.
  ///
  /// Parameters:
  /// - [handler]: The progress handler function to call
  ///
  /// Returns this instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final client = SimpleApiRequest.init()
  ///   .withProgress((progress) {
  ///     print('${progress.type.name}: ${progress.percentage}%');
  ///   });
  /// ```
  SimpleApiRequest withProgress(ProgressHandler handler) {
    _progressHandler = handler;
    return this;
  }

  /// Sets an upload-specific progress handler.
  ///
  /// This handler will only receive upload progress updates. It will be called
  /// in addition to any general progress handler that may be set.
  ///
  /// Parameters:
  /// - [handler]: The upload progress handler function to call
  ///
  /// Returns this instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final client = SimpleApiRequest.init()
  ///   .withUploadProgress((progress) {
  ///     updateUploadProgressBar(progress.percentage);
  ///   });
  /// ```
  SimpleApiRequest withUploadProgress(UploadProgressHandler handler) {
    _uploadProgressHandler = handler;
    return this;
  }

  /// Sets a download-specific progress handler.
  ///
  /// This handler will only receive download progress updates. It will be called
  /// in addition to any general progress handler that may be set.
  ///
  /// Parameters:
  /// - [handler]: The download progress handler function to call
  ///
  /// Returns this instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final client = SimpleApiRequest.init()
  ///   .withDownloadProgress((progress) {
  ///     updateDownloadProgressBar(progress.percentage);
  ///   });
  /// ```
  SimpleApiRequest withDownloadProgress(DownloadProgressHandler handler) {
    _downloadProgressHandler = handler;
    return this;
  }

  /// Executes an HTTP GET request.
  ///
  /// GET requests are typically used for retrieving data. Query parameters
  /// and path variables are supported.
  ///
  /// Parameters:
  /// - [path]: The request path (may contain variables like '/posts/{id}')
  /// - [queryParameters]: Optional query parameters to append to URL
  /// - [options]: Optional Dio request options
  /// - [cancelToken]: Optional cancellation token
  /// - [onReceiveProgress]: Optional progress callback for response
  ///
  /// Returns [Either] with error on left and response data on right.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.get<List<Post>>(
  ///   '/posts',
  ///   queryParameters: {'limit': 10, 'offset': 0},
  /// );
  /// ```
  Future<Either<ActionRequestError, T?>?> get<T>(String path,
      {Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onReceiveProgress}) async {
    final handler =
        _handleRequest(path, data: queryParameters, isFormData: false);
    try {
      final response = await _requestClient.dio.get(handler['path'],
          queryParameters: handler['data'],
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress ?? _onReceiveProgress);
      return _handleResponse<T>(response: response);
    } catch (e) {
      return _handleError<T>(error: e);
    }
  }

  /// Executes an HTTP POST request.
  ///
  /// POST requests are typically used for creating new resources.
  /// Data is sent in the request body.
  ///
  /// Parameters:
  /// - [path]: The request path (may contain variables like '/posts/{id}')
  /// - [data]: Optional data to send in the request body
  /// - [queryParameters]: Optional query parameters to append to URL
  /// - [options]: Optional Dio request options
  /// - [cancelToken]: Optional cancellation token
  /// - [onSendProgress]: Optional progress callback for sending data
  /// - [onReceiveProgress]: Optional progress callback for response
  ///
  /// Returns [Either] with error on left and response data on right.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.post<Post>(
  ///   '/posts',
  ///   data: {'title': 'New Post', 'content': 'Post content'},
  /// );
  /// ```
  Future<Either<ActionRequestError, T?>?> post<T>(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) async {
    final handler = _handleRequest(path, data: data);
    try {
      final response = await _requestClient.dio.post(handler['path'],
          data: handler['data'],
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress ?? _onReceiveProgress,
          onSendProgress: onSendProgress ?? _onSendProgress);
      return _handleResponse<T>(response: response);
    } catch (e) {
      return _handleError<T>(error: e);
    }
  }

  /// Executes an HTTP PUT request.
  ///
  /// PUT requests are typically used for updating existing resources.
  /// Data is sent in the request body.
  ///
  /// Parameters:
  /// - [path]: The request path (may contain variables like '/posts/{id}')
  /// - [data]: Optional data to send in the request body
  /// - [queryParameters]: Optional query parameters to append to URL
  /// - [options]: Optional Dio request options
  /// - [cancelToken]: Optional cancellation token
  /// - [onSendProgress]: Optional progress callback for sending data
  /// - [onReceiveProgress]: Optional progress callback for response
  ///
  /// Returns [Either] with error on left and response data on right.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.put<Post>(
  ///   '/posts/{id}',
  ///   data: {'id': 123, 'title': 'Updated Title'},
  /// );
  /// ```
  Future<Either<ActionRequestError, T?>?> put<T>(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) async {
    final handler = _handleRequest(path, data: data);
    try {
      final response = await _requestClient.dio.put(handler['path'],
          data: handler['data'],
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress ?? _onReceiveProgress,
          onSendProgress: onSendProgress ?? _onSendProgress);
      return _handleResponse<T>(response: response);
    } catch (e) {
      return _handleError<T>(error: e);
    }
  }

  /// Executes an HTTP DELETE request.
  ///
  /// DELETE requests are typically used for removing resources.
  /// Optional data can be sent in the request body.
  ///
  /// Parameters:
  /// - [path]: The request path (may contain variables like '/posts/{id}')
  /// - [data]: Optional data to send in the request body
  /// - [queryParameters]: Optional query parameters to append to URL
  /// - [options]: Optional Dio request options
  /// - [cancelToken]: Optional cancellation token
  ///
  /// Returns [Either] with error on left and response data on right.
  ///
  /// Example:
  /// ```dart
  /// final result = await client.delete<void>(
  ///   '/posts/{id}',
  ///   data: {'id': 123},
  /// );
  /// ```
  Future<Either<ActionRequestError, T?>?> delete<T>(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) async {
    final handler = _handleRequest(path, data: data);
    try {
      final response = await _requestClient.dio.delete(handler['path'],
          data: handler['data'],
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);
      return _handleResponse<T>(response: response);
    } catch (e) {
      return _handleError<T>(error: e);
    }
  }

  /// Downloads a file from the specified path to local storage.
  ///
  /// This method streams file content directly to disk, making it suitable
  /// for large files. Progress tracking is supported.
  ///
  /// Parameters:
  /// - [path]: The request path (may contain variables like '/files/{id}')
  /// - [savePath]: Local file path where the file will be saved
  /// - [onReceiveProgress]: Optional progress callback (received, total)
  /// - [queryParameters]: Optional query parameters to append to URL
  /// - [cancelToken]: Optional cancellation token
  /// - [deleteOnError]: Whether to delete partial file on error (default: true)
  /// - [lengthHeader]: Header used to determine content length
  /// - [data]: Optional data for path variables
  /// - [options]: Optional Dio request options
  ///
  /// Returns the HTTP [Response] object or null if failed.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.download(
  ///   '/files/{fileId}',
  ///   '/local/downloads/document.pdf',
  ///   data: {'fileId': 'abc123'},
  ///   onReceiveProgress: (received, total) {
  ///     final progress = (received / total * 100).round();
  ///     print('Download progress: $progress%');
  ///   },
  /// );
  /// ```
  Future<Response?> download(
    String path,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    final handler = _handleRequest(path, data: data);
    return await _requestClient.dio.download(handler['path'], savePath,
        data: handler['data'],
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress ?? _onReceiveProgress,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader);
  }

  /// Internal method to process request data and resolve dynamic paths.
  ///
  /// This method:
  /// - Resolves dynamic path variables using [ApiRequestUtils]
  /// - Converts data to form data if needed for non-GET requests
  ///
  /// Parameters:
  /// - [path]: The request path (may contain variables)
  /// - [data]: Optional request data
  /// - [isFormData]: Whether to format data as form data (default: true)
  ///
  /// Returns a map with resolved 'path' and processed 'data'.
  Map<String, dynamic> _handleRequest(String path,
      {Map<String, dynamic>? data, bool isFormData = true}) {
    final newData = ApiRequestUtils.handleDynamicPathWithData(path, data ?? {});
    if (isFormData && newData['data'] is Map<String, dynamic>) {
      newData['data'] = FormData.fromMap(
          newData['data'], ApiRequestOptions.instance!.listFormat);
    }
    return newData;
  }

  /// Internal method to process HTTP responses.
  ///
  /// This method:
  /// - Applies the response builder if configured
  /// - Wraps parsing errors in [ActionRequestError]
  /// - Returns parsed data wrapped in Either pattern
  ///
  /// Parameters:
  /// - [response]: The HTTP response to process
  ///
  /// Returns [Either] with error on left and parsed data on right.
  Future<Either<ActionRequestError, T?>?> _handleResponse<T>({
    Response? response,
  }) async {
    try {
      final result = _responseBuilder != null
          ? _responseBuilder(response?.data)
          : response?.data;
      return right(result);
    } catch (e) {
      return left(ActionRequestError(e, res: response));
    }
  }

  /// Internal method to wrap errors in [ActionRequestError].
  ///
  /// This method converts any error into an [ActionRequestError] and
  /// returns it wrapped in the left side of an Either.
  ///
  /// Parameters:
  /// - [error]: The error to wrap
  ///
  /// Returns [Either] with wrapped error on the left side.
  Future<Either<ActionRequestError, T?>?> _handleError<T>({
    Object? error,
  }) async =>
      left(ActionRequestError(error));

  /// Whether any progress handlers are configured.
  ///
  /// Returns true if at least one progress handler is set.
  bool get _hasProgressHandlers =>
      _progressHandler != null ||
      _uploadProgressHandler != null ||
      _downloadProgressHandler != null;

  /// Creates a Dio-compatible upload progress callback.
  ///
  /// Converts Dio's (sent, total) callback format to ProgressData
  /// and calls the appropriate progress handlers.
  ProgressCallback? get _onSendProgress {
    if (!_hasProgressHandlers) return null;
    
    return (int sent, int total) {
      final progress = ProgressData.fromBytes(
        sentBytes: sent,
        totalBytes: total,
        type: ProgressType.upload,
      );
      
      _progressHandler?.call(progress);
      _uploadProgressHandler?.call(progress);
    };
  }

  /// Creates a Dio-compatible download progress callback.
  ///
  /// Converts Dio's (received, total) callback format to ProgressData
  /// and calls the appropriate progress handlers.
  ProgressCallback? get _onReceiveProgress {
    if (!_hasProgressHandlers) return null;
    
    return (int received, int total) {
      final progress = ProgressData.fromBytes(
        sentBytes: received,
        totalBytes: total,
        type: ProgressType.download,
      );
      
      _progressHandler?.call(progress);
      _downloadProgressHandler?.call(progress);
    };
  }
}
