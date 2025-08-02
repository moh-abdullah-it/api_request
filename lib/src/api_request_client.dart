import 'package:api_request/src/interceptors/token_interceptor.dart';
import 'package:api_request/src/interceptors/unauthenticated_interceptor.dart';
import 'package:flutter/foundation.dart';

import '../api_request.dart';

/// A singleton HTTP client wrapper around Dio with automatic configuration.
///
/// This class provides a centralized HTTP client that automatically configures
/// itself based on [ApiRequestOptions] settings. It manages interceptors,
/// authentication, logging, and other HTTP client features.
///
/// ## Features
///
/// - **Singleton Pattern**: Single instance shared across the application
/// - **Automatic Configuration**: Uses settings from [ApiRequestOptions]
/// - **Interceptor Management**: Automatic addition/removal of interceptors
/// - **Authentication Handling**: Dynamic token interceptor management
/// - **Request Logging**: Debug-mode request/response logging
/// - **Base URL Resolution**: Dynamic base URL resolution with async support
///
/// ## Usage
///
/// The client is typically used internally by [RequestAction] classes,
/// but can be accessed directly if needed:
///
/// ```dart
/// // Access the singleton instance
/// final client = RequestClient.instance;
///
/// // Make a direct request (not recommended - use RequestAction instead)
/// final response = await client?.dio.get('/posts');
/// ```
///
/// ## Configuration
///
/// The client automatically configures itself from [ApiRequestOptions]:
///
/// ```dart
/// ApiRequestOptions.instance!.config(
///   baseUrl: 'https://api.example.com',
///   enableLog: true,
///   defaultHeaders: {'User-Agent': 'MyApp/1.0'},
///   interceptors: [CustomInterceptor()],
/// );
///
/// // Client is automatically reconfigured
/// ```
///
/// ## Interceptor Management
///
/// The client automatically manages several interceptors:
/// - [ApiLogInterceptor]: Request/response logging (debug mode only)
/// - [TokenInterceptor]: Authentication token injection
/// - [UnauthenticatedInterceptor]: 401 response handling
/// - Custom interceptors from [ApiRequestOptions.interceptors]
///
/// ## Authentication Configuration
///
/// The client dynamically adds/removes authentication based on request needs:
///
/// ```dart
/// // This is handled automatically by RequestAction
/// client.configAuth(true);  // Adds TokenInterceptor
/// client.configAuth(false); // Removes TokenInterceptor
/// ```
///
/// See also:
/// - [ApiRequestOptions] for client configuration
/// - [RequestAction] for the action-based request system
/// - [Dio] for the underlying HTTP client
class RequestClient {
  /// The singleton instance of the request client
  static RequestClient? _instance;

  /// The underlying Dio HTTP client instance
  final Dio _dio = Dio();

  /// Provides access to the underlying Dio client.
  ///
  /// This getter allows direct access to the Dio instance for advanced
  /// use cases that aren't covered by the action-based system. However,
  /// it's recommended to use [RequestAction] subclasses instead.
  ///
  /// Example:
  /// ```dart
  /// final dio = RequestClient.instance?.dio;
  /// final response = await dio?.get('/custom-endpoint');
  /// ```
  ///
  /// Returns the configured Dio HTTP client instance.
  Dio get dio => _dio;

  /// Private constructor for singleton pattern.
  ///
  /// Automatically calls [intConfig] to initialize the client with
  /// settings from [ApiRequestOptions].
  RequestClient._() {
    intConfig();
  }

  /// Gets the singleton instance of the request client.
  ///
  /// Creates a new instance if one doesn't exist, otherwise returns
  /// the existing instance. The instance is automatically configured
  /// with settings from [ApiRequestOptions].
  ///
  /// Example:
  /// ```dart
  /// final client = RequestClient.instance;
  /// final response = await client?.dio.get('/posts');
  /// ```
  ///
  /// Returns the singleton [RequestClient] instance.
  static RequestClient? get instance {
    if (_instance == null) {
      _instance = RequestClient._();
    }
    return _instance;
  }

  /// Initializes the client configuration with settings from [ApiRequestOptions].
  ///
  /// This method configures the Dio client with:
  /// - Base URL (resolved asynchronously if needed)
  /// - Default query parameters and headers
  /// - Connection timeout settings
  /// - Content-Type and Accept headers
  /// - Logging interceptor (debug mode only)
  /// - Authentication and error handling interceptors
  /// - Custom interceptors from options
  ///
  /// This method is called automatically during client initialization
  /// and when [refreshConfig] is called.
  intConfig() async {
    _dio.options = BaseOptions(
      receiveDataWhenStatusError: true,
      baseUrl: await ApiRequestOptions.instance!.getBaseUrlString(),
      queryParameters: ApiRequestOptions.instance!.defaultQueryParameters,
      connectTimeout: ApiRequestOptions.instance!.connectTimeout,
      headers: ApiRequestOptions.instance!.defaultHeaders,
    );

    if (!kReleaseMode &&
        ApiRequestOptions.instance!.logLevel != ApiLogLevel.none) {
      addInterceptorOnce(ApiLogInterceptor());
    }

    _dio.options.headers
        .addAll({Headers.acceptHeader: Headers.jsonContentType});

    if (ApiRequestOptions.instance!.unauthenticated != null) {
      addInterceptorOnce(UnauthenticatedInterceptor());
    }
    if (ApiRequestOptions.instance!.interceptors.isNotEmpty) {
      ApiRequestOptions.instance!.interceptors.forEach(addInterceptorOnce);
    }
  }

  /// Configures authentication interceptor based on request requirements.
  ///
  /// This method dynamically adds or removes the [TokenInterceptor] based
  /// on whether the current request requires authentication. It's called
  /// automatically by [RequestAction] during request setup.
  ///
  /// Parameters:
  /// - [authRequired]: Whether authentication is required for the request
  ///
  /// When `true`, adds [TokenInterceptor] to inject auth tokens.
  /// When `false`, removes [TokenInterceptor] to avoid unnecessary auth headers.
  ///
  /// Example:
  /// ```dart
  /// // This is typically called automatically by RequestAction
  /// client.configAuth(true);  // Adds authentication
  /// client.configAuth(false); // Removes authentication
  /// ```
  configAuth(bool authRequired) {
    bool hasInterceptor = _dio.interceptors.contains(TokenInterceptor());
    if (!authRequired && hasInterceptor) {
      _dio.interceptors.remove(TokenInterceptor());
    } else if (authRequired) {
      addInterceptorOnce(TokenInterceptor());
    }
  }

  /// Adds an interceptor to the client if it's not already present.
  ///
  /// This method ensures that interceptors are not duplicated by checking
  /// if the interceptor already exists before adding it.
  ///
  /// Parameters:
  /// - [interceptor]: The interceptor to add
  ///
  /// Example:
  /// ```dart
  /// client.addInterceptorOnce(CustomInterceptor());
  /// client.addInterceptorOnce(LogInterceptor()); // Won't duplicate
  /// ```
  addInterceptorOnce(Interceptor interceptor) {
    if (!_dio.interceptors.contains(interceptor)) {
      _dio.interceptors.add(interceptor);
    }
  }

  /// Removes an interceptor from the client if it exists.
  ///
  /// This method safely removes an interceptor by first checking if it
  /// exists in the interceptor list.
  ///
  /// Parameters:
  /// - [interceptor]: The interceptor to remove
  ///
  /// Example:
  /// ```dart
  /// client.removeInterceptor(CustomInterceptor());
  /// ```
  removeInterceptor(Interceptor interceptor) {
    if (_dio.interceptors.contains(interceptor)) {
      _dio.interceptors.remove(interceptor);
    }
  }

  /// Refreshes the client configuration by creating a new instance.
  ///
  /// This method creates a new [RequestClient] instance, which automatically
  /// reconfigures itself with the current settings from [ApiRequestOptions].
  /// This is useful when configuration settings have changed and you need
  /// to apply them to the HTTP client.
  ///
  /// Called automatically by [ApiRequestOptions.refreshConfig].
  ///
  /// Example:
  /// ```dart
  /// // After changing ApiRequestOptions settings
  /// ApiRequestOptions.instance!.config(baseUrl: 'https://new-api.com');
  /// RequestClient.refreshConfig(); // Apply the new base URL
  /// ```
  static refreshConfig() {
    _instance = RequestClient._();
  }
}
