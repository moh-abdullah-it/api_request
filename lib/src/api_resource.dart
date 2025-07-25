import 'package:fpdart/fpdart.dart';

import '../api_request.dart';
import 'utils/api_request_utils.dart';

/// Abstract base class for creating resource-based API request handlers.
///
/// This class provides a simplified approach to making API requests without
/// the full structure of [RequestAction]. It's designed for quick, one-off
/// requests or when you need a lighter-weight solution.
///
/// ## Key Features
///
/// - **Simplified API**: Fewer abstractions than full action-based approach
/// - **Automatic Path Resolution**: Support for dynamic path variables
/// - **Authentication Support**: Optional authentication via [authRequired]
/// - **Custom Response Building**: Flexible response parsing with [withBuilder]
/// - **Functional Error Handling**: Uses Either pattern for error handling
///
/// ## Basic Usage
///
/// ```dart
/// class PostsResource extends ApiResource {
///   @override
///   String get path => '/posts';
///   
///   @override
///   bool get authRequired => false;
/// }
///
/// final resource = PostsResource();
/// final result = await resource
///   .withBuilder((data) => (data as List).map((item) => Post.fromJson(item)).toList())
///   .get<List<Post>>();
/// 
/// result?.fold(
///   (error) => print('Error: ${error.message}'),
///   (posts) => print('Loaded ${posts?.length} posts'),
/// );
/// ```
///
/// ## Dynamic Paths
///
/// Support for path variables using curly braces:
///
/// ```dart
/// class UserPostsResource extends ApiResource {
///   @override
///   String get path => '/users/{userId}/posts';
///   
///   @override
///   Map<String, dynamic> get toMap => {'userId': 123};
/// }
/// ```
///
/// ## Method Chaining
///
/// The class supports method chaining for configuration:
///
/// ```dart
/// final result = await PostsResource()
///   .withBuilder((data) => Post.fromJson(data))
///   .get<Post>('/posts/123');
/// ```
///
/// ## Comparison with RequestAction
///
/// **Use ApiResource when:**
/// - Making simple, one-off requests
/// - You need quick prototyping
/// - The request logic is straightforward
/// - You don't need lifecycle hooks or complex error handling
///
/// **Use RequestAction when:**
/// - Building reusable, complex request logic
/// - You need lifecycle hooks (onInit, onStart, onSuccess, etc.)
/// - You want structured request/response handling
/// - You need streaming or reactive patterns
///
/// See also:
/// - [RequestAction] for the full-featured action-based approach
/// - [SimpleApiRequest] for an even more direct request interface
abstract class ApiResource {
  /// Whether this resource requires authentication.
  ///
  /// When `true`, the request will automatically include authentication
  /// headers using the token configured in [ApiRequestOptions].
  ///
  /// Default is `false` for public endpoints.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// bool get authRequired => true; // For protected endpoints
  /// ```
  bool get authRequired => false;

  /// The API endpoint path for this resource.
  ///
  /// Supports dynamic path variables using curly braces like `/users/{id}`.
  /// Variables are automatically replaced with values from [toMap].
  ///
  /// Example:
  /// ```dart
  /// @override
  /// String get path => '/posts/{id}/comments';
  /// ```
  String get path;

  /// Additional data to include with the request.
  ///
  /// This data is used for:
  /// - Dynamic path variable substitution
  /// - Query parameters (for GET requests)
  /// - Request body data (for POST/PUT requests)
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, dynamic> get toMap => {
  ///   'id': 123,  // Will replace {id} in path
  ///   'limit': 10, // Will be added as query parameter
  /// };
  /// ```
  Map<String, dynamic> get toMap => {};

  /// Internal response builder function for parsing responses
  ResponseBuilder? _responseBuilder;

  /// Internal HTTP client instance for making requests
  RequestClient? _requestClient = RequestClient.instance;

  /// Executes a GET request to the specified or default path.
  ///
  /// Parameters:
  /// - [path]: Optional path override. Uses [path] property if null.
  ///
  /// Returns an [Either] with error on left and response data on right.
  ///
  /// Example:
  /// ```dart
  /// // Use default path
  /// final result = await resource.get<List<Post>>();
  ///
  /// // Override path
  /// final result = await resource.get<Post>('/posts/123');
  /// ```
  Future<Either<ActionRequestError, T?>?> get<T>([String? path = null]) async {
    return await _get<T>(path ?? this.path);
  }

  /// Sets a custom response builder for parsing server responses.
  ///
  /// The builder function is called with the raw response data and should
  /// return a parsed object of the expected type.
  ///
  /// Parameters:
  /// - [builder]: Function to parse response data
  ///
  /// Returns this resource instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final result = await resource
  ///   .withBuilder((data) => Post.fromJson(data))
  ///   .get<Post>();
  /// ```
  ApiResource withBuilder(ResponseBuilder builder) {
    _responseBuilder = builder;
    return this;
  }

  /// Internal method to execute HTTP GET requests.
  ///
  /// This method handles the actual HTTP GET request execution with
  /// support for query parameters, custom options, and progress tracking.
  ///
  /// Parameters:
  /// - [path]: The request path
  /// - [queryParameters]: Optional query parameters
  /// - [options]: Optional Dio request options
  /// - [cancelToken]: Optional cancellation token
  /// - [onReceiveProgress]: Optional progress callback
  ///
  /// Returns [Either] with error on left and response data on right.
  Future<Either<ActionRequestError, T?>?> _get<T>(String path,
      {Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onReceiveProgress}) async {
    var handler =
        _handleRequest(path, data: queryParameters, isFormData: false);
    try {
      Response? response = await _requestClient?.dio.get(handler['path'],
          queryParameters: handler['data'],
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress);
      return _handleResponse<T>(response: response);
    } catch (e) {
      return _handleError(error: e);
    }
  }

  /// Internal method to process request data and resolve dynamic paths.
  ///
  /// This method:
  /// - Configures authentication based on [authRequired]
  /// - Resolves dynamic path variables using [ApiRequestUtils]
  /// - Formats data as form data if needed
  ///
  /// Parameters:
  /// - [path]: The request path (may contain variables)
  /// - [data]: Optional request data
  /// - [isFormData]: Whether to format data as form data
  ///
  /// Returns a map with resolved 'path' and processed 'data'.
  Map<String, dynamic> _handleRequest(String path,
      {Map<String, dynamic>? data, bool isFormData = true}) {
    _requestClient?.configAuth(authRequired);
    Map<String, dynamic> newData =
        ApiRequestUtils.handleDynamicPathWithData(path, data ?? {});
    if (isFormData) {
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
  Future<Either<ActionRequestError, T?>?> _handleResponse<T>(
      {Response? response}) async {
    Either<ActionRequestError, T?>? either;
    try {
      either = right(_responseBuilder != null
          ? _responseBuilder!(response?.data)
          : response?.data);
    } catch (e) {
      either = left(ActionRequestError(e, res: response));
    }
    return either;
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
  static Future<Either<ActionRequestError, T?>?> _handleError<T>(
          {Object? error}) async =>
      left(ActionRequestError(error));
}
