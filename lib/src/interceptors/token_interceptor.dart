import 'package:api_request/api_request.dart';

/// An interceptor that automatically adds authentication tokens to requests.
///
/// This interceptor is responsible for injecting authentication tokens into
/// HTTP request headers. It's automatically managed by [RequestClient] and
/// added/removed based on the [RequestAction.authRequired] property.
///
/// ## Automatic Management
///
/// The interceptor is automatically:
/// - Added when a request requires authentication ([authRequired] = true)
/// - Removed when a request doesn't require authentication ([authRequired] = false)
/// - Managed by [RequestClient.configAuth] during request setup
///
/// ## Token Sources
///
/// The interceptor retrieves tokens from [ApiRequestOptions] in order of priority:
/// 1. Static token: [ApiRequestOptions.token]
/// 2. Synchronous callback: [ApiRequestOptions.getToken]
/// 3. Asynchronous callback: [ApiRequestOptions.getAsyncToken]
///
/// ## Token Format
///
/// By default, tokens are formatted as "Bearer {token}". You can customize
/// the prefix using [ApiRequestOptions.tokenType]:
///
/// ```dart
/// ApiRequestOptions.instance!.config(
///   token: 'abc123',
///   tokenType: 'Bearer ',  // Default
/// );
/// // Results in: Authorization: Bearer abc123
///
/// ApiRequestOptions.instance!.config(
///   token: 'xyz789',
///   tokenType: 'Token ',   // Custom prefix
/// );
/// // Results in: Authorization: Token xyz789
/// ```
///
/// ## Dynamic Token Retrieval
///
/// For applications that need to refresh tokens or retrieve them from
/// secure storage:
///
/// ```dart
/// ApiRequestOptions.instance!.config(
///   getAsyncToken: () async {
///     final token = await SecureStorage.getToken();
///     if (token == null || TokenService.isExpired(token)) {
///       return await TokenService.refreshToken();
///     }
///     return token;
///   },
/// );
/// ```
///
/// ## Usage with Actions
///
/// Actions automatically trigger token injection by setting [authRequired]:
///
/// ```dart
/// class GetUserProfileAction extends ApiRequestAction<UserProfile> {
///   @override
///   String get path => '/user/profile';
///   
///   @override
///   RequestMethod get method => RequestMethod.GET;
///   
///   @override
///   bool get authRequired => true;  // Triggers TokenInterceptor
///   
///   @override
///   ResponseBuilder<UserProfile> get responseBuilder => 
///     (data) => UserProfile.fromJson(data);
/// }
/// ```
///
/// ## Error Handling
///
/// If no token is available when required, the request may:
/// - Return null from [RequestAction.execute] (checked before making request)
/// - Proceed without authentication (depending on server requirements)
///
/// See also:
/// - [ApiRequestOptions] for token configuration
/// - [UnauthenticatedInterceptor] for handling 401 responses
/// - [RequestClient.configAuth] for automatic interceptor management
class TokenInterceptor extends ApiInterceptor {
  /// Internal tag for interceptor identification
  final String _tag = 'token';
  
  /// Intercepts outgoing requests to add authentication tokens.
  ///
  /// This method is called before each HTTP request that requires authentication.
  /// It retrieves the authentication token using [ApiRequestOptions.getTokenString]
  /// and adds it to the request headers.
  ///
  /// ## Token Injection Process
  ///
  /// 1. Retrieves token from configured source (static, sync, or async)
  /// 2. If token is available, adds "Authorization" header
  /// 3. Formats token with configured prefix (default: "Bearer ")
  /// 4. Continues with request processing
  ///
  /// ## Header Format
  ///
  /// The token is added as an Authorization header:
  /// ```
  /// Authorization: Bearer abc123token
  /// ```
  ///
  /// The prefix can be customized via [ApiRequestOptions.tokenType].
  ///
  /// ## Debug Output
  ///
  /// In debug builds, the interceptor logs token information for debugging
  /// purposes (token value is printed - ensure this doesn't leak to production).
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    String? token = await ApiRequestOptions.instance?.getTokenString();
    print("configAuth token $token");
    if (token != null) {
      options.headers.addAll(
          {"Authorization": "${ApiRequestOptions.instance?.tokenType}$token"});
    }
    super.onRequest(options, handler);
  }

  /// Compares two [TokenInterceptor] instances for equality.
  ///
  /// Two interceptors are considered equal if they have the same type
  /// and internal tag. This is used by [RequestClient] to prevent
  /// duplicate interceptors and to properly add/remove the interceptor
  /// based on authentication requirements.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenInterceptor &&
          runtimeType == other.runtimeType &&
          _tag == other._tag;

  /// Returns the hash code for this interceptor.
  ///
  /// Based on the internal tag to ensure consistent hashing for
  /// equality comparison and collection membership.
  @override
  int get hashCode => _tag.hashCode;
}
