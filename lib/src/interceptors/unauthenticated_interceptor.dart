import '../../api_request.dart';

/// An interceptor that handles 401 Unauthorized responses.
///
/// This interceptor automatically detects when the server returns a 401
/// (Unauthorized) status code and triggers the configured unauthenticated
/// callback. This is typically used to handle expired tokens, logout users,
/// or redirect to login screens.
///
/// ## Automatic Registration
///
/// The interceptor is automatically added by [RequestClient] when
/// [ApiRequestOptions.unauthenticated] callback is configured:
///
/// ```dart
/// ApiRequestOptions.instance!.config(
///   unauthenticated: () {
///     // Handle unauthenticated state
///     AuthService.logout();
///     NavigationService.goToLogin();
///   },
/// );
/// ```
///
/// ## Common Use Cases
///
/// **Token Expiration Handling:**
/// ```dart
/// ApiRequestOptions.instance!.config(
///   unauthenticated: () async {
///     // Clear expired token
///     await TokenService.clearToken();
///
///     // Redirect to login
///     Navigator.pushNamedAndRemoveUntil(
///       context, '/login', (route) => false,
///     );
///   },
/// );
/// ```
///
/// **Token Refresh Attempt:**
/// ```dart
/// ApiRequestOptions.instance!.config(
///   unauthenticated: () async {
///     try {
///       await TokenService.refreshToken();
///       // Optionally retry the failed request
///     } catch (e) {
///       // Refresh failed, logout user
///       AuthService.logout();
///     }
///   },
/// );
/// ```
///
/// **User Notification:**
/// ```dart
/// ApiRequestOptions.instance!.config(
///   unauthenticated: () {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(
///         content: Text('Session expired. Please login again.'),
///         action: SnackBarAction(
///           label: 'Login',
///           onPressed: () => Navigator.pushNamed(context, '/login'),
///         ),
///       ),
///     );
///   },
/// );
/// ```
///
/// ## Global vs Per-Request Handling
///
/// This interceptor provides global 401 handling. Individual requests can
/// disable global error handling using [RequestAction.disableGlobalOnError]
/// if they need custom 401 handling:
///
/// ```dart
/// class LoginAction extends RequestAction<AuthResponse, LoginRequest> {
///   @override
///   bool get disableGlobalOnError => true;  // Handle 401 locally
///
///   // Custom error handling in onError callback
/// }
/// ```
///
/// ## Execution Order
///
/// The unauthenticated callback is called before other error handling:
/// 1. UnauthenticatedInterceptor detects 401
/// 2. Calls [ApiRequestOptions.unauthenticated]
/// 3. Error propagates to [RequestAction.onError]
/// 4. Error propagates to global error handler (if enabled)
///
/// ## Error Propagation
///
/// The interceptor doesn't prevent error propagation - it calls the
/// unauthenticated callback and then allows the error to continue through
/// the normal error handling chain. This allows both global handling
/// (logout/redirect) and local handling (retry logic, user feedback).
///
/// See also:
/// - [ApiRequestOptions.unauthenticated] for callback configuration
/// - [TokenInterceptor] for authentication token injection
/// - [RequestAction.disableGlobalOnError] for per-request error handling
class UnauthenticatedInterceptor extends ApiInterceptor {
  /// Internal tag for interceptor identification
  final String _tag = 'unauthenticated';

  /// Intercepts request errors to handle 401 Unauthorized responses.
  ///
  /// This method is called whenever an HTTP request fails with an error.
  /// It specifically checks for 401 status codes and triggers the configured
  /// unauthenticated callback when detected.
  ///
  /// ## Error Detection
  ///
  /// The method checks if:
  /// - The error has an associated response (server responded)
  /// - The response status code is exactly 401 (Unauthorized)
  ///
  /// ## Callback Execution
  ///
  /// When a 401 is detected, the method:
  /// 1. Calls [ApiRequestOptions.instance.unauthenticated] if configured
  /// 2. Allows the error to continue through the error handling chain
  /// 3. Does not modify or prevent the error from reaching other handlers
  ///
  /// ## Error Continuation
  ///
  /// After calling the unauthenticated callback, the error continues to
  /// propagate through:
  /// - [RequestAction.onError] callbacks
  /// - Global error handlers (if not disabled)
  /// - The Either return value from [RequestAction.execute]
  ///
  /// This allows for both global handling (logout) and local handling
  /// (retry logic, user feedback) of the same 401 error.
  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    if (error.response?.statusCode == 401) {
      ApiRequestOptions.instance?.unauthenticated!();
    }
    super.onError(error, handler);
  }

  /// Compares two [UnauthenticatedInterceptor] instances for equality.
  ///
  /// Two interceptors are considered equal if they have the same type
  /// and internal tag. This is used by [RequestClient] to prevent
  /// duplicate interceptors.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnauthenticatedInterceptor &&
          runtimeType == other.runtimeType &&
          _tag == other._tag;

  /// Returns the hash code for this interceptor.
  ///
  /// Based on the internal tag to ensure consistent hashing for
  /// equality comparison and collection membership.
  @override
  int get hashCode => _tag.hashCode;
}
