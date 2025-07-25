import '../api_request.dart';

/// Function type for synchronous option retrieval.
///
/// Used for callbacks that return configuration values synchronously,
/// such as getting the current base URL or auth token.
///
/// Example:
/// ```dart
/// GetOption<String> getBaseUrl = () => Environment.current.apiUrl;
/// ```
typedef GetOption<T> = T Function();

/// Function type for asynchronous option retrieval.
///
/// Used for callbacks that return configuration values asynchronously,
/// such as getting auth tokens from secure storage.
///
/// Example:
/// ```dart
/// GetAsyncOption<String> getAsyncToken = () async {
///   return await SecureStorage.getToken();
/// };
/// ```
typedef GetAsyncOption<T> = Future<T> Function();

/// Global configuration singleton for API request settings.
///
/// This class provides centralized configuration for all API requests in the
/// application. It uses the singleton pattern to ensure consistent settings
/// across all request actions.
///
/// ## Key Features
///
/// - **Base URL Management**: Static or dynamic base URL resolution
/// - **Authentication**: Token management with sync/async support
/// - **Interceptors**: Global request/response interceptors
/// - **Default Parameters**: Global headers and query parameters
/// - **Error Handling**: Global error callback configuration
/// - **Multi-Environment Support**: Runtime environment switching
///
/// ## Basic Configuration
///
/// ```dart
/// ApiRequestOptions.instance!.config(
///   baseUrl: 'https://api.example.com',
///   token: 'your-auth-token',
///   enableLog: true,
///   connectTimeout: Duration(seconds: 30),
/// );
/// ```
///
/// ## Dynamic Configuration
///
/// For applications that need runtime configuration:
///
/// ```dart
/// ApiRequestOptions.instance!.config(
///   getBaseUrl: () => Environment.current.apiUrl,
///   getAsyncToken: () async => await AuthService.getToken(),
///   unauthenticated: () => AuthService.logout(),
/// );
/// ```
///
/// ## Global Error Handling
///
/// ```dart
/// ApiRequestOptions.instance!.config(
///   onError: (error) {
///     logger.error('API Error', error);
///     if (error.statusCode == 500) {
///       showErrorDialog('Server error occurred');
///     }
///   },
/// );
/// ```
///
/// See also:
/// - [RequestClient] for the HTTP client that uses these options
/// - [RequestAction] for request actions that respect these settings
class ApiRequestOptions {
  /// Singleton for ApiRequestOptions by create one instance
  static ApiRequestOptions? _instance;

  /// Singleton for ApiRequestOptions by create one instance
  static ApiRequestOptions? get instance {
    if (_instance == null) {
      _instance = ApiRequestOptions();
    }
    return _instance;
  }

  /// list of global interceptors
  List<ApiInterceptor> interceptors = <ApiInterceptor>[];

  /// to disable log set it to false
  bool enableLog = true;

  /// Timeout in milliseconds for opening url.
  /// [Dio] will throw the [DioException] with [DioExceptionType.connectTimeout] type
  ///  when time out.
  Duration? connectTimeout = Duration(seconds: 30);

  /// for Bearer token type.
  static String bearer = 'Bearer ';

  /// set tokenType for types
  String? tokenType = '';

  /// base url for your api
  /// You can set it ApiRequestOptions.instance.baseUrl = 'https://example.com';
  late String? baseUrl;

  GetOption<String>? getBaseUrl;

  GetAsyncOption<String>? getAsyncBaseUrl;

  /// access token
  String? token;

  /// get access token use callback function
  GetOption<String?>? getToken;

  /// write what you wont if your server response unauthenticated with status code 401
  GetOption? unauthenticated;

  /// get access token use async callback function
  GetAsyncOption<String?>? getAsyncToken;

  // set default query parameters to url
  late Map<String, dynamic> defaultQueryParameters = {};

  // set default header
  late Map<String, dynamic> defaultHeaders = {};

  Function(ActionRequestError error)? onError;

  Function(Map<String, dynamic> data)? errorBuilder;

  ListFormat listFormat = ListFormat.multiCompatible;

  /// Configures global API request settings.
  ///
  /// This method allows you to set up all global configuration options for
  /// API requests. Settings can be updated at runtime, and changes will affect
  /// all subsequent requests.
  ///
  /// ## Parameters
  ///
  /// **URL Configuration:**
  /// - [baseUrl]: Static base URL for all requests
  /// - [getBaseUrl]: Callback for dynamic base URL (sync)
  /// - [getAsyncBaseUrl]: Callback for dynamic base URL (async)
  ///
  /// **Authentication:**
  /// - [token]: Static authentication token
  /// - [getToken]: Callback for dynamic token retrieval (sync)
  /// - [getAsyncToken]: Callback for dynamic token retrieval (async)
  /// - [tokenType]: Token prefix (defaults to 'Bearer ')
  /// - [unauthenticated]: Callback for handling 401 responses
  ///
  /// **Request Configuration:**
  /// - [defaultQueryParameters]: Global query parameters for all requests
  /// - [defaultHeaders]: Global headers for all requests
  /// - [connectTimeout]: Connection timeout duration
  /// - [listFormat]: Format for list serialization in form data
  ///
  /// **Development:**
  /// - [enableLog]: Enable request/response logging in debug mode
  /// - [interceptors]: Global interceptors for all requests
  ///
  /// **Error Handling:**
  /// - [onError]: Global error handler for all requests
  /// - [errorBuilder]: Custom error object builder
  ///
  /// ## Examples
  ///
  /// Basic setup:
  /// ```dart
  /// await ApiRequestOptions.instance!.config(
  ///   baseUrl: 'https://api.example.com',
  ///   token: 'abc123',
  ///   enableLog: true,
  /// );
  /// ```
  ///
  /// Advanced setup with dynamic configuration:
  /// ```dart
  /// await ApiRequestOptions.instance!.config(
  ///   getAsyncBaseUrl: () async => await ConfigService.getApiUrl(),
  ///   getAsyncToken: () async => await AuthService.getToken(),
  ///   unauthenticated: () => NavigationService.goToLogin(),
  ///   defaultHeaders: {'User-Agent': 'MyApp/1.0'},
  ///   onError: (error) => ErrorService.handleApiError(error),
  /// );
  /// ```
  void config(
      {String? baseUrl,
      GetOption<String>? getBaseUrl,
      GetAsyncOption<String>? getAsyncBaseUrl,
      String? token,
      GetOption<String?>? getToken,
      GetAsyncOption<String?>? getAsyncToken,
      GetOption? unauthenticated,
      Map<String, dynamic>? defaultQueryParameters,
      Map<String, dynamic>? defaultHeaders,
      String? tokenType,
      Duration? connectTimeout,
      bool? enableLog,
      List<ApiInterceptor>? interceptors,
      Function(ActionRequestError error)? onError,
      Function(Map<String, dynamic> data)? errorBuilder,
      ListFormat? listFormat}) async {
    this.baseUrl = baseUrl ?? this.baseUrl;
    this.getBaseUrl = getBaseUrl ?? this.getBaseUrl;
    this.getAsyncBaseUrl = getAsyncBaseUrl ?? this.getAsyncBaseUrl;
    this.token = token ?? this.token;
    this.getToken = getToken ?? this.getToken;
    this.getAsyncToken = getAsyncToken ?? this.getAsyncToken;
    this.unauthenticated = unauthenticated ?? this.unauthenticated;

    if (this.defaultQueryParameters.isNotEmpty) {
      this.defaultQueryParameters.addAll(defaultQueryParameters ?? {});
    } else {
      this.defaultQueryParameters =
          defaultQueryParameters ?? this.defaultQueryParameters;
    }
    if (this.defaultHeaders.isNotEmpty) {
      this.defaultHeaders.addAll(defaultHeaders ?? {});
    } else {
      this.defaultHeaders = defaultHeaders ?? this.defaultHeaders;
    }

    if (this.interceptors.isNotEmpty) {
      this.interceptors.addAll(interceptors ?? []);
    } else {
      this.interceptors = interceptors ?? this.interceptors;
    }

    this.tokenType = tokenType ?? this.tokenType;
    this.connectTimeout = connectTimeout ?? this.connectTimeout;
    this.enableLog = enableLog ?? this.enableLog;
    this.onError = onError ?? this.onError;
    this.errorBuilder = errorBuilder ?? this.errorBuilder;
    this.listFormat = listFormat ?? this.listFormat;
  }

  /// Refreshes the HTTP client configuration.
  ///
  /// This method forces the [RequestClient] to recreate itself with the
  /// current configuration settings. Call this after making changes to
  /// configuration options if you need them to take effect immediately.
  ///
  /// Example:
  /// ```dart
  /// ApiRequestOptions.instance!.baseUrl = 'https://new-api.com';
  /// ApiRequestOptions.refreshConfig(); // Apply changes immediately
  /// ```
  static refreshConfig() {
    RequestClient.refreshConfig();
  }

  /// Retrieves the authentication token using configured methods.
  ///
  /// This method attempts to get the auth token in the following order:
  /// 1. Static [token] if set
  /// 2. [getToken] callback if configured
  /// 3. [getAsyncToken] callback if configured
  /// 4. Returns null if no token source is available
  ///
  /// Returns the auth token string or null if not available.
  ///
  /// Example:
  /// ```dart
  /// final token = await ApiRequestOptions.instance!.getTokenString();
  /// if (token != null) {
  ///   print('Token available: ${token.substring(0, 10)}...');
  /// }
  /// ```
  Future<String?> getTokenString() async {
    if (ApiRequestOptions.instance?.token != null) {
      return token;
    }
    if (ApiRequestOptions.instance?.getToken != null) {
      return getToken!.call();
    }
    if (ApiRequestOptions.instance?.getAsyncToken != null) {
      return await getAsyncToken!.call();
    }
    return null;
  }

  /// Retrieves the base URL using configured methods.
  ///
  /// This method resolves the base URL in the following order:
  /// 1. [getBaseUrl] callback if configured (updates [baseUrl])
  /// 2. [getAsyncBaseUrl] callback if configured (updates [baseUrl])
  /// 3. Uses current [baseUrl] value
  ///
  /// Throws an assertion error if no base URL is available.
  ///
  /// Returns the resolved base URL string.
  ///
  /// Example:
  /// ```dart
  /// final baseUrl = await ApiRequestOptions.instance!.getBaseUrlString();
  /// print('API Base URL: $baseUrl');
  /// ```
  Future<String> getBaseUrlString() async {
    if (ApiRequestOptions.instance?.getBaseUrl != null) {
      baseUrl = getBaseUrl!.call();
    }

    if (ApiRequestOptions.instance?.getAsyncBaseUrl != null) {
      baseUrl = await getAsyncBaseUrl!.call();
    }
    assert(baseUrl != null, 'BaseUrl cannot be Null');
    return baseUrl!;
  }
}
