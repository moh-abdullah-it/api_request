import '../../api_request.dart';

/// Base class for API request interceptors.
///
/// This class extends Dio's [Interceptor] to provide a foundation for custom
/// interceptors in the API request system. It serves as a marker class and
/// base for all interceptors used by the library.
///
/// ## Usage
///
/// Create custom interceptors by extending this class:
///
/// ```dart
/// class CustomApiInterceptor extends ApiInterceptor {
///   @override
///   void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
///     // Add custom headers or modify request
///     options.headers['X-Custom-Header'] = 'custom-value';
///     super.onRequest(options, handler);
///   }
///
///   @override
///   void onResponse(Response response, ResponseInterceptorHandler handler) {
///     // Process response data
///     print('Response received: ${response.statusCode}');
///     super.onResponse(response, handler);
///   }
///
///   @override
///   void onError(DioException error, ErrorInterceptorHandler handler) {
///     // Handle errors
///     print('Request failed: ${error.message}');
///     super.onError(error, handler);
///   }
/// }
/// ```
///
/// ## Registration
///
/// Register custom interceptors through [ApiRequestOptions]:
///
/// ```dart
/// ApiRequestOptions.instance!.config(
///   interceptors: [
///     CustomApiInterceptor(),
///     AnotherInterceptor(),
///   ],
/// );
/// ```
///
/// ## Built-in Interceptors
///
/// The library includes several built-in interceptors:
/// - [ApiLogInterceptor]: Request/response logging
/// - [TokenInterceptor]: Authentication token injection
/// - [UnauthenticatedInterceptor]: 401 response handling
///
/// See also:
/// - [Interceptor] for the base Dio interceptor class
/// - [ApiRequestOptions.interceptors] for registering interceptors
/// - [RequestClient] for interceptor management
class ApiInterceptor extends Interceptor {}
