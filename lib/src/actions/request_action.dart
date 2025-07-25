import 'dart:async';
import 'dart:developer';

import 'package:api_request/api_request.dart';
import 'package:fpdart/fpdart.dart';

import '../utils/api_request_utils.dart';

/// HTTP request methods supported by the API request system.
///
/// These methods correspond to standard HTTP verbs and determine how
/// the request will be processed by the server.
enum RequestMethod {
  /// HTTP GET method for retrieving data
  GET,
  
  /// HTTP POST method for creating new resources
  POST,
  
  /// HTTP PUT method for updating existing resources
  PUT,
  
  /// HTTP DELETE method for removing resources
  DELETE
}

/// Function type for building response objects from raw response data.
///
/// This function is called after a successful HTTP request to transform
/// the raw response data into a strongly-typed object.
///
/// Example:
/// ```dart
/// ResponseBuilder<Post> get responseBuilder => (data) => Post.fromJson(data);
/// ```
typedef ResponseBuilder<T> = T Function(dynamic);

/// Function type for handling request errors.
///
/// This callback is invoked when an API request fails, providing access
/// to the error details for custom error handling logic.
///
/// Example:
/// ```dart
/// ErrorHandler<String> onError = (error) {
///   print('Request failed: ${error.message}');
/// };
/// ```
typedef ErrorHandler<E> = Function(ActionRequestError<E> error);

/// Function type for handling successful request responses.
///
/// This callback is invoked when an API request completes successfully,
/// providing access to the parsed response data.
///
/// Example:
/// ```dart
/// SuccessHandler<Post> onSuccess = (post) {
///   print('Post loaded: ${post?.title}');
/// };
/// ```
typedef SuccessHandler<T> = Function(T? response);

/// The core base class for all API request actions in the system.
///
/// This abstract class provides a comprehensive framework for making HTTP requests
/// with features like authentication, error handling, performance monitoring,
/// dynamic path resolution, and functional programming patterns using the Either type.
///
/// ## Type Parameters
///
/// - `T`: The expected response type after parsing
/// - `R`: The request data type (must extend [ApiRequest])
///
/// ## Core Features
///
/// - **Lifecycle Management**: Automatic handling of request initialization, execution, and cleanup
/// - **Authentication**: Built-in token management with automatic header injection
/// - **Error Handling**: Functional error handling using Either<Error, Success> pattern
/// - **Performance Monitoring**: Optional request timing and performance tracking
/// - **Dynamic Paths**: Support for path variables like `/users/{id}` with automatic substitution
/// - **Streaming**: Built-in support for reactive programming with Dart Streams
/// - **Interceptors**: Automatic integration with global and request-specific interceptors
///
/// ## Usage Example
///
/// ```dart
/// class CreatePostAction extends RequestAction<Post, CreatePostRequest> {
///   CreatePostAction(CreatePostRequest request) : super(request);
///   
///   @override
///   String get path => '/posts';
///   
///   @override
///   RequestMethod get method => RequestMethod.POST;
///   
///   @override
///   bool get authRequired => true;
///   
///   @override
///   ResponseBuilder<Post> get responseBuilder => (data) => Post.fromJson(data);
/// }
///
/// // Execute with error handling
/// final result = await CreatePostAction(createRequest).execute();
/// result?.fold(
///   (error) => print('Error: ${error.message}'),
///   (post) => print('Created post: ${post.title}'),
/// );
/// ```
///
/// ## Lifecycle Hooks
///
/// Override these methods to customize request behavior:
///
/// - [onInit]: Called during construction for setup
/// - [onStart]: Called before HTTP request execution
/// - [onSuccess]: Called after successful response parsing
/// - [onError]: Called when request or parsing fails
/// - [onDone]: Called after request completion (success or failure)
///
/// ## Method Chaining
///
/// The class supports fluent method chaining for building requests:
///
/// ```dart
/// final result = await MyAction()
///   .where('userId', 123)           // Add data parameter
///   .whereQuery('page', 1)          // Add query parameter
///   .withHeader('Custom', 'value')  // Add header
///   .listen(
///     onSuccess: (data) => handleSuccess(data),
///     onError: (error) => handleError(error),
///   )
///   .execute();
/// ```
///
/// See also:
/// - [ApiRequestAction] for simple requests without request data
/// - [ApiRequestOptions] for global configuration
/// - [RequestClient] for the underlying HTTP client
abstract class RequestAction<T, R extends ApiRequest> {
  /// Creates a new request action with optional request data.
  ///
  /// The constructor automatically:
  /// - Calls [onInit] for custom initialization logic
  /// - Configures authentication settings on the HTTP client
  ///
  /// Parameters:
  /// - [_request]: The request data object, can be null for simple requests
  RequestAction(this._request) {
    this.onInit();
    _requestClient?.configAuth(authRequired);
  }

  /// The singleton HTTP client instance for making requests
  final RequestClient? _requestClient = RequestClient.instance;
  
  /// The singleton performance monitoring instance for tracking request timing
  final ApiRequestPerformance? _performanceUtils =
      ApiRequestPerformance.instance;
      
  /// Stream controller for reactive programming support
  final StreamController<T?> _streamController = StreamController<T?>();

  /// Stream of response data for reactive programming patterns.
  ///
  /// Listen to this stream to receive response data when using [onQueue] method.
  /// The stream emits the parsed response data on success or an error on failure.
  ///
  /// Example:
  /// ```dart
  /// action.stream.listen(
  ///   (data) => print('Received: $data'),
  ///   onError: (error) => print('Error: $error'),
  /// );
  /// action.onQueue();
  /// ```
  Stream<T?> get stream => _streamController.stream;
  
  /// The request data object passed to the constructor
  R? _request;

  /// The content type for request data serialization.
  ///
  /// Override this to specify how request data should be serialized:
  /// - `null` (default): JSON serialization
  /// - `ContentDataType.formData`: Multipart form data serialization
  ///
  /// Example:
  /// ```dart
  /// @override
  /// ContentDataType? get contentDataType => ContentDataType.formData;
  /// ```
  ContentDataType? get contentDataType => null;

  /// Whether this request requires authentication.
  ///
  /// When `true`, the request will:
  /// - Automatically include the auth token in headers
  /// - Fail if no token is available
  /// - Trigger the unauthenticated callback on 401 responses
  ///
  /// Example:
  /// ```dart
  /// @override
  /// bool get authRequired => true;
  /// ```
  bool get authRequired => false;

  /// Whether to bypass global error handling for this request.
  ///
  /// When `true`, the global `onError` callback in [ApiRequestOptions]
  /// will not be invoked for this request, allowing for custom error handling.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// bool get disableGlobalOnError => true;
  /// ```
  bool get disableGlobalOnError => false;

  /// The API endpoint path for this request.
  ///
  /// Supports dynamic path variables using curly braces like `/users/{id}`.
  /// Variables are automatically replaced with values from request data.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// String get path => '/posts/{id}/comments';
  /// ```
  String get path;

  /// The HTTP method for this request.
  ///
  /// Must be one of: [RequestMethod.GET], [RequestMethod.POST],
  /// [RequestMethod.PUT], or [RequestMethod.DELETE].
  ///
  /// Example:
  /// ```dart
  /// @override
  /// RequestMethod get method => RequestMethod.POST;
  /// ```
  RequestMethod get method;

  /// The resolved path after dynamic variable substitution
  late String _dynamicPath;

  /// Function to build the response object from raw response data.
  ///
  /// This function is called after a successful HTTP request to parse
  /// the raw response data into a strongly-typed object.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// ResponseBuilder<Post> get responseBuilder => (data) => Post.fromJson(data);
  /// ```
  ResponseBuilder<T> get responseBuilder;

  /// Additional data to include in the request.
  ///
  /// Override this method to provide static data that should be included
  /// with every request. This data is merged with the request object data
  /// and any data added via [where] or [whereMap] methods.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, dynamic> get toMap => {'version': '1.0', 'source': 'mobile'};
  /// ```
  Map<String, dynamic> get toMap => {};

  /// The processed request data ready for HTTP transmission
  var _dataMap;

  /// Lifecycle hook called during action construction.
  ///
  /// Override this to perform any initialization logic needed before
  /// the request can be executed.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Function get onInit => () {
  ///   print('Initializing ${runtimeType}');
  ///   validateRequest();
  /// };
  /// ```
  Function onInit = () => {};

  /// Lifecycle hook called just before HTTP request execution.
  ///
  /// Override this to perform any pre-request logic such as logging,
  /// validation, or analytics tracking.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Function get onStart => () {
  ///   analytics.trackRequest(path);
  /// };
  /// ```
  Function onStart = () => {};

  /// Additional data parameters to include in the request
  Map<String, dynamic> _data = {};
  
  /// Query parameters to append to the request URL
  Map<String, dynamic> _query = {};

  /// Error handler callback for request failures.
  ///
  /// This callback is invoked when the request fails due to network issues,
  /// server errors, or response parsing problems.
  ///
  /// Example:
  /// ```dart
  /// action.listen(
  ///   onError: (error) {
  ///     logger.error('Request failed', error);
  ///     showErrorDialog(error.message);
  ///   },
  /// );
  /// ```
  ErrorHandler onError = (error) => {};
  
  /// Success handler callback for successful responses.
  ///
  /// This callback is invoked after successful request execution and
  /// response parsing, providing access to the parsed response data.
  ///
  /// Example:
  /// ```dart
  /// action.listen(
  ///   onSuccess: (post) {
  ///     print('Received post: ${post?.title}');
  ///     updateUI(post);
  ///   },
  /// );
  /// ```
  SuccessHandler<T> onSuccess = (response) => {};
  
  /// Completion handler callback called after request finishes.
  ///
  /// This callback is invoked after request completion, regardless of
  /// success or failure. Useful for cleanup or analytics.
  ///
  /// Example:
  /// ```dart
  /// action.listen(
  ///   onDone: () {
  ///     hideLoadingIndicator();
  ///     analytics.trackRequestComplete();
  ///   },
  /// );
  /// ```
  Function onDone = () => {};
  
  /// Custom headers to include with the request
  Map<String, dynamic> _headers = {};

  /// Internal method to handle and propagate errors through the stream.
  ///
  /// This method:
  /// 1. Calls the local [onError] handler
  /// 2. Calls the global error handler (unless [disableGlobalOnError] is true)
  /// 3. Adds the error to the stream
  /// 4. Disposes of resources
  void _streamError(ActionRequestError error) {
    this.onError(error);
    if (ApiRequestOptions.instance!.onError != null && !disableGlobalOnError) {
      ApiRequestOptions.instance!.onError!(error);
    }
    if (!this._streamController.isClosed) {
      _streamController.sink.addError(error);
      this.dispose();
    }
  }

  /// Internal method to handle and propagate successful responses through the stream.
  ///
  /// This method:
  /// 1. Calls the local [onSuccess] handler
  /// 2. Adds the response to the stream
  /// 3. Disposes of resources
  void _streamSuccess(T? response) {
    this.onSuccess(response);
    if (!_streamController.isClosed) {
      _streamController.sink.add(response);
      this.dispose();
    }
  }

  /// Subscribes to the response stream with callback handlers.
  ///
  /// This method provides a convenient way to listen to the response stream
  /// without manually calling [stream.listen]. It's typically used with
  /// the [onQueue] method for reactive programming patterns.
  ///
  /// Parameters:
  /// - [onSuccess]: Called when the request succeeds with parsed response data
  /// - [onDone]: Called when the request completes (success or failure)
  /// - [onError]: Called when the request fails with error details
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// action
  ///   .subscribe(
  ///     onSuccess: (data) => updateUI(data),
  ///     onError: (error) => showError(error),
  ///     onDone: () => hideLoading(),
  ///   )
  ///   .onQueue();
  /// ```
  ///
  /// See also:
  /// - [listen] for setting callback handlers without subscribing
  /// - [onQueue] for executing the request asynchronously
  RequestAction subscribe(
      {Function(T? response)? onSuccess,
      Function()? onDone,
      Function(Object error)? onError}) {
    stream.listen(onSuccess, onError: onError, onDone: onDone);
    return this;
  }

  /// Sets callback handlers for request lifecycle events.
  ///
  /// This method allows you to configure callback functions that will be
  /// invoked at different stages of the request lifecycle. Unlike [subscribe],
  /// this method only sets the callbacks without starting the request.
  ///
  /// Parameters:
  /// - [onStart]: Called just before HTTP request execution begins
  /// - [onDone]: Called after request completion (success or failure)
  /// - [onSuccess]: Called after successful response parsing
  /// - [onError]: Called when request or parsing fails
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final result = await action
  ///   .listen(
  ///     onStart: () => showLoading(),
  ///     onSuccess: (data) => print('Success: $data'),
  ///     onError: (error) => print('Error: ${error.message}'),
  ///     onDone: () => hideLoading(),
  ///   )
  ///   .execute();
  /// ```
  ///
  /// See also:
  /// - [subscribe] for listening to the response stream
  /// - [execute] for synchronous request execution
  RequestAction listen(
      {Function? onStart,
      Function? onDone,
      SuccessHandler<T>? onSuccess,
      ErrorHandler? onError}) {
    if (onStart != null) {
      this.onStart = onStart;
    }
    if (onDone != null) {
      this.onDone = onDone;
    }
    if (onSuccess != null) {
      this.onSuccess = onSuccess;
    }
    if (onError != null) {
      this.onError = onError;
    }
    return this;
  }

  /// Executes the request synchronously and returns the result.
  ///
  /// This is the primary method for executing API requests. It performs
  /// authentication checks, makes the HTTP request, parses the response,
  /// and returns an [Either] type for functional error handling.
  ///
  /// Returns:
  /// - `null` if authentication is required but no token is available
  /// - `Left(error)` if the request fails or parsing errors occur
  /// - `Right(data)` if the request succeeds and parsing is successful
  ///
  /// The method automatically:
  /// - Checks authentication requirements and token availability
  /// - Calls lifecycle hooks ([onStart], [onSuccess], [onError], [onDone])
  /// - Handles global error callbacks (unless [disableGlobalOnError] is true)
  /// - Tracks request performance if monitoring is enabled
  ///
  /// Example:
  /// ```dart
  /// final result = await GetPostAction().where('id', 123).execute();
  /// 
  /// if (result != null) {
  ///   result.fold(
  ///     (error) => showError('Failed to load post: ${error.message}'),
  ///     (post) => displayPost(post),
  ///   );
  /// } else {
  ///   showError('Authentication required');
  /// }
  /// ```
  ///
  /// See also:
  /// - [onQueue] for asynchronous execution with stream-based results
  /// - [listen] for setting callback handlers
  Future<Either<ActionRequestError, T>?> execute() async {
    log('${authRequired} -- ${await ApiRequestOptions.instance?.getTokenString()}');

    if (authRequired &&
        (await ApiRequestOptions.instance?.getTokenString()) == null) {
      log('You Need To Login to Request This action: ${this.runtimeType}');
      return null;
    }

    try {
      final response = await _execute();
      final result = await _parseResponse(response);

      return result.fold(
        (error) {
          _handleError(error);
          return left(error);
        },
        (success) {
          onSuccess(success);
          onDone();
          return right(success);
        },
      );
    } catch (e) {
      final error = ActionRequestError(e);
      _handleError(error);
      return left(error);
    }
  }

  Future<Either<ActionRequestError, T>> _parseResponse(
      Response? response) async {
    try {
      final parsedData = responseBuilder(response?.data);
      return right(parsedData);
    } catch (e) {
      return left(ActionRequestError(e, res: response));
    }
  }

  void _handleError(ActionRequestError error) {
    onError(error);
    if (ApiRequestOptions.instance!.onError != null && !disableGlobalOnError) {
      ApiRequestOptions.instance!.onError!(error);
    }
    onDone();
  }

  Future<Response?> _execute() async {
    _handleRequest(this._request);
    this.onStart();
    _performanceUtils?.startTrack();
    Response? _response;
    switch (this.method) {
      case RequestMethod.GET:
        _response = await get();
        break;
      case RequestMethod.POST:
        _response = await post();
        break;
      case RequestMethod.PUT:
        _response = await put();
        break;
      case RequestMethod.DELETE:
        _response = await delete();
        break;
    }
    _performanceUtils?.endTrack();
    //this._streamSuccess(responseBuilder(_response?.data));

    return _response;
  }

  /// Executes the request asynchronously and streams the result.
  ///
  /// This method starts the request execution in the background and emits
  /// the result through the [stream]. It's ideal for reactive programming
  /// patterns where you want to handle responses asynchronously.
  ///
  /// Unlike [execute], this method:
  /// - Does not return a value directly
  /// - Emits results through the [stream]
  /// - Does not perform authentication checks upfront
  /// - Is non-blocking and returns immediately
  ///
  /// Example:
  /// ```dart
  /// action.stream.listen(
  ///   (data) => handleSuccess(data),
  ///   onError: (error) => handleError(error),
  /// );
  /// 
  /// action.onQueue(); // Starts the request
  /// ```
  ///
  /// Example with subscribe:
  /// ```dart
  /// action
  ///   .subscribe(
  ///     onSuccess: (data) => updateUI(data),
  ///     onError: (error) => showError(error),
  ///   )
  ///   .onQueue();
  /// ```
  ///
  /// See also:
  /// - [execute] for synchronous execution with direct result
  /// - [subscribe] for convenient stream subscription
  /// - [stream] for manual stream listening
  void onQueue() {
    _handleRequest(this._request);
    _performanceUtils?.startTrack();
    this.onStart();
    Future<Response?> _dynamicCall;
    switch (this.method) {
      case RequestMethod.GET:
        _dynamicCall = get();
        break;
      case RequestMethod.POST:
        _dynamicCall = post();
        break;
      case RequestMethod.PUT:
        _dynamicCall = put();
        break;
      case RequestMethod.DELETE:
        _dynamicCall = delete();
        break;
    }
    _dynamicCall
        .then((value) => this._streamSuccess(responseBuilder(value?.data)))
        .catchError((error) => this._streamError(ActionRequestError(error)))
        .then((_) => _performanceUtils?.endTrack());
  }

  /// Gets the performance report for this request.
  ///
  /// Returns timing and performance data collected during request execution,
  /// or `null` if performance monitoring is disabled or the request hasn't
  /// been executed yet.
  ///
  /// The report includes:
  /// - Request duration
  /// - Network timing details
  /// - Request metadata (method, URL, etc.)
  ///
  /// Example:
  /// ```dart
  /// final result = await action.execute();
  /// final report = action.performanceReport;
  /// 
  /// if (report != null) {
  ///   print('Request took ${report.duration.inMilliseconds}ms');
  ///   print('URL: ${report.url}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [ApiRequestPerformance] for global performance monitoring
  /// - [PerformanceReport] for report data structure
  PerformanceReport? get performanceReport => _performanceUtils?.getReport();

  /// Executes an HTTP GET request.
  ///
  /// For GET requests, all data parameters are added to the query string.
  /// The request body is empty.
  ///
  /// Returns the raw HTTP response from the server.
  Future<Response?> get() async {
    _query.addAll(Map.of(_dataMap));
    return await _requestClient?.dio.get(_dynamicPath,
        queryParameters: _query, options: Options(headers: _headers));
  }

  /// Executes an HTTP POST request.
  ///
  /// The request data is sent in the request body, with query parameters
  /// appended to the URL.
  ///
  /// Returns the raw HTTP response from the server.
  Future<Response?> post() async {
    return await _requestClient?.dio.post(_dynamicPath,
        data: _dataMap,
        queryParameters: _query,
        options: Options(headers: _headers));
  }

  /// Executes an HTTP PUT request.
  ///
  /// The request data is sent in the request body, with query parameters
  /// appended to the URL.
  ///
  /// Returns the raw HTTP response from the server.
  Future<Response?> put() async {
    return await _requestClient?.dio.put(_dynamicPath,
        data: _dataMap,
        queryParameters: _query,
        options: Options(headers: _headers));
  }

  /// Executes an HTTP DELETE request.
  ///
  /// The request data is sent in the request body, with query parameters
  /// appended to the URL.
  ///
  /// Returns the raw HTTP response from the server.
  Future<Response?> delete() async {
    return await _requestClient?.dio.delete(_dynamicPath,
        data: _dataMap,
        queryParameters: _query,
        options: Options(headers: _headers));
  }

  _handleRequest(R? request) {
    Map<String, dynamic> mapData =
        Map.of(toMap.isNotEmpty ? toMap : request?.toMap() ?? {});
    mapData.addAll(_data);
    Map<String, dynamic> newData =
        ApiRequestUtils.handleDynamicPathWithData(path, mapData);
    this._dynamicPath = newData['path'];
    this._dataMap = newData['data'];
    if ((this.contentDataType == ContentDataType.formData ||
            request?.contentDataType == ContentDataType.formData) &&
        method != RequestMethod.GET) {
      this._dataMap = FormData.fromMap(
          newData['data'], ApiRequestOptions.instance!.listFormat);
    } else {
      this._dataMap = newData['data'];
    }
    _performanceUtils?.init(this.runtimeType.toString(),
        ApiRequestOptions.instance!.baseUrl! + _dynamicPath);
  }

  /// Disposes of resources and closes the response stream.
  ///
  /// This method is automatically called after request completion to clean up
  /// resources. It closes the stream controller to prevent memory leaks.
  ///
  /// You typically don't need to call this manually as it's handled automatically
  /// by the request lifecycle.
  ///
  /// Example (manual disposal if needed):
  /// ```dart
  /// action.dispose();
  /// ```
  void dispose() {
    if (!_streamController.isClosed) {
      _streamController.close();
    }
  }

  /// Adds a data parameter to the request.
  ///
  /// This method adds key-value pairs to the request data. For dynamic paths
  /// like `/users/{id}`, if the key matches a path variable, it will be used
  /// for path substitution. Otherwise, it's included in the request body (POST/PUT)
  /// or query parameters (GET).
  ///
  /// Parameters:
  /// - [key]: The parameter name
  /// - [value]: The parameter value
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// // For path /users/{id}/posts
  /// final result = await action
  ///   .where('id', 123)        // Replaces {id} in path
  ///   .where('title', 'Hello') // Added to request body/query
  ///   .execute();
  /// ```
  ///
  /// See also:
  /// - [whereMap] for adding multiple parameters at once
  /// - [whereQuery] for explicitly adding query parameters
  RequestAction where(String key, dynamic value) {
    _data[key] = value;
    return this;
  }

  /// Adds multiple data parameters to the request.
  ///
  /// This method merges a map of key-value pairs into the request data.
  /// It's equivalent to calling [where] multiple times but more efficient
  /// for bulk parameter addition.
  ///
  /// Parameters:
  /// - [map]: A map containing the parameters to add
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final result = await action
  ///   .whereMap({
  ///     'userId': 123,
  ///     'title': 'New Post',
  ///     'content': 'Post content here',
  ///   })
  ///   .execute();
  /// ```
  ///
  /// See also:
  /// - [where] for adding individual parameters
  /// - [whereMapQuery] for explicitly adding query parameters
  RequestAction whereMap(Map<String, dynamic> map) {
    _data.addAll(Map.of(map));
    return this;
  }

  /// Adds a query parameter to the request URL.
  ///
  /// This method explicitly adds parameters to the URL query string,
  /// regardless of the HTTP method. Query parameters appear after the
  /// '?' in the URL.
  ///
  /// Parameters:
  /// - [key]: The query parameter name
  /// - [value]: The query parameter value
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// // Results in: /posts?page=1&limit=10
  /// final result = await action
  ///   .whereQuery('page', 1)
  ///   .whereQuery('limit', 10)
  ///   .execute();
  /// ```
  ///
  /// See also:
  /// - [whereMapQuery] for adding multiple query parameters
  /// - [where] for general parameter addition
  RequestAction whereQuery(String key, dynamic value) {
    _query[key] = value;
    return this;
  }

  /// Adds multiple query parameters to the request URL.
  ///
  /// This method merges a map of key-value pairs into the URL query string.
  /// It's equivalent to calling [whereQuery] multiple times but more efficient
  /// for bulk query parameter addition.
  ///
  /// Parameters:
  /// - [map]: A map containing the query parameters to add
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// // Results in: /posts?page=1&limit=10&sort=date&order=desc
  /// final result = await action
  ///   .whereMapQuery({
  ///     'page': 1,
  ///     'limit': 10,
  ///     'sort': 'date',
  ///     'order': 'desc',
  ///   })
  ///   .execute();
  /// ```
  ///
  /// See also:
  /// - [whereQuery] for adding individual query parameters
  /// - [whereMap] for general parameter addition
  RequestAction whereMapQuery(Map<String, dynamic> map) {
    _query.addAll(Map.of(map));
    return this;
  }

  /// Adds multiple custom headers to the request.
  ///
  /// This method merges custom headers with the request. These headers
  /// are combined with default headers from [ApiRequestOptions] and
  /// any authentication headers.
  ///
  /// Parameters:
  /// - [headers]: A map containing the headers to add
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final result = await action
  ///   .withHeaders({
  ///     'Content-Type': 'application/json',
  ///     'X-Custom-Header': 'custom-value',
  ///     'Accept-Language': 'en-US',
  ///   })
  ///   .execute();
  /// ```
  ///
  /// See also:
  /// - [withHeader] for adding individual headers
  /// - [ApiRequestOptions.defaultHeaders] for global headers
  RequestAction withHeaders(Map<String, dynamic> headers) {
    _headers.addAll(Map.of(headers));
    return this;
  }

  /// Adds a single custom header to the request.
  ///
  /// This method adds an individual header to the request. The header
  /// is combined with default headers from [ApiRequestOptions] and
  /// any authentication headers.
  ///
  /// Parameters:
  /// - [key]: The header name
  /// - [value]: The header value
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final result = await action
  ///   .withHeader('Content-Type', 'application/json')
  ///   .withHeader('X-Request-ID', requestId)
  ///   .execute();
  /// ```
  ///
  /// See also:
  /// - [withHeaders] for adding multiple headers at once
  /// - [ApiRequestOptions.defaultHeaders] for global headers
  RequestAction withHeader(String key, dynamic value) {
    _headers[key] = value;
    return this;
  }
}
